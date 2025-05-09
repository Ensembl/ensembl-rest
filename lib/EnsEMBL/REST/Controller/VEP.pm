=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
Copyright [2016-2025] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::REST::Controller::VEP;
use Moose;
use namespace::autoclean;
use Data::Dumper;
use Bio::EnsEMBL::VEP::Runner;
use Bio::EnsEMBL::Utils::IO qw/slurp/;

use Try::Tiny;

require EnsEMBL::REST;

EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);
BEGIN { 
  extends 'Catalyst::Controller::REST';
}

# This list describes user overridable variables for this endpoint. It protects other more fundamental variables
has valid_user_params => ( 
  is => 'ro', 
  isa => 'HashRef', 
  traits => ['Hash'], 
  handles => { valid_user_param => 'exists' },
  default => sub { return {
    map {$_ => 1} (qw/
    gencode_basic
    gencode_primary
    refseq
    merged

    failed
    variant_class
    minimal
    vcf_string
    transcript_version
    ambiguous_hgvs

    appris
    canonical
    ccds
    domains
    hgvs
    numbers
    protein
    tsl
    uniprot
    xref_refseq
    phyloP
    transcript_id
    phastCons
    distance
    ambiguity
    mane
    shift_3prime
    shift_genomic
    mirna

    ga4gh_vrs

    pick
    pick_allele
    per_gene
    pick_allele_gene
    flag_pick
    flag_pick_allele
    flag_pick_allele_gene
    pick_order
  /)}
  }
);

with 'EnsEMBL::REST::Role::PostLimiter';

# /vep/:species
sub get_species : Chained('/') PathPart('vep') CaptureArgs(1) {
  my ( $self, $c, $species ) = @_;
  my $reg = $c->model('Registry');
  $c->stash->{species} = $reg->get_alias($species);

  my ($csa, $css);
  try {
    $csa = $reg->get_adaptor($species, 'core', 'coordsystem');
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  try {
    $css = $csa->fetch_all;
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };

  $c->stash->{assembly} = $css->[0]->version;
  $c->stash->{has_variation} = $c->model('Registry')->get_adaptor( $species, 'Variation', 'Variation');
  $c->log->debug('Working with species '.$species);
}


# WARNING: Do not combine REST auto-dispatch with Args() or CaptureArgs()
# It prevents the dispatcher from recognising the GET and POST methods
# Arguments must be handled subsequently
sub get_region : Chained('get_species') PathPart('region') ActionClass('REST') {
  my ( $self, $c, $region ) = @_;
}

sub get_region_GET {
  my ( $self, $c, $region ) = @_;
  try {
    my ($sr_name) = $c->model('Lookup')->decode_region( $region, 1, 1 );
    my $slice = $c->model('Lookup')->find_slice( $sr_name );
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  $self->status_ok( $c, entity => $region );
  $c->forward('get_allele');
}

sub get_region_POST {
  my ( $self, $c ) = @_;
  my $post_data = $c->req->data;
  # $c->log->debug(Dumper $post_data);
  # $c->log->debug(Dumper $config->{'Controller::VEP'});
  # handle user config
  my $config = $self->_include_user_params($c,$post_data);
  
  unless (exists $post_data->{variants}) {
    $c->go( 'ReturnError', 'custom', [ ' Cannot find "variants" key in your POST. Please check the format of your message against the documentation' ] );
  }
  my @variants = @{$post_data->{variants}};
  $self->assert_post_size($c,\@variants);

  $self->_give_POST_to_VEP($c,\@variants, $config);
}

sub _give_POST_to_VEP {
  my ($self,$c,$data,$config) = @_;
  try {    
    $config->{species} = $c->stash->{species}; # override VEP default for human
    my $consequences = $self->get_consequences($c, $config, join("\n", @$data));
    $c->stash->{consequences} = $consequences;
    $self->status_ok( $c, entity => $consequences );
  } catch {
    $c->log->fatal(qw{Problem Getting Consequences});
    $c->log->fatal($_);
    $c->log->fatal(Dumper $data);
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
}




# /vep/:species/region/:region/:allele_string
# Only one argument wanted here, but region is still on the stack and needs to be moved out of the way.
sub get_allele : PathPart('') Args(2) {
  my ( $self, $c, $region, $allele ) = @_;
  $c->log->debug($allele);
  my $s = $c->stash();
  if ($allele !~ /^[ATGC-]+$/i && $allele !~ /INS|DUP|DEL|TDUP/i) {
    my $error_msg = qq{Allele must be A,T,G,C or SO term [got: $allele]};
    $c->go( 'ReturnError', 'custom', [$error_msg] );
  }

  $s->{end} = $s->{start} if !$s->{end};
  $c->go('ReturnError', 'custom', ['Start or End cannot be negative']) if ($s->{start} < 0 || $s->{end} < 0);
  $c->go('ReturnError', 'custom', ['Strand should be 1 or -1, not ' . $s->{strand}]) if $s->{strand} !~ /1/;

  if($allele =~ /INS|DUP|DEL|TDUP/) {
    $s->{allele_string} = $allele;
    $s->{allele} = $allele;
  }
  else {
    my $reference_base;
    try {
      $reference_base = $s->{slice}->subseq( $s->{start}, $s->{end}, $s->{strand} );
      $s->{reference_base} = $reference_base;
    } catch {
      $c->log->fatal(qq{can't get reference base from slice});
      $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
      $c->go('ReturnError', 'custom', [qq{$_}]);
    };
    $c->go( 'ReturnError', 'custom', ["request for consequence of [$allele] matches reference [$reference_base]"] )
      if $reference_base eq $allele;

    $reference_base ||= '-';
    my $allele_string = $reference_base . '/' . $allele;
    $s->{allele_string} = $allele_string;
    $s->{allele}        = $allele;
  }

  my $user_config = $c->request->parameters;
  my $config = $self->_include_user_params($c,$user_config);

  my $string = sprintf(
    '%s %i %i %s %i',
    $s->{slice}->seq_region_name,
    $s->{start},
    $s->{end},
    $s->{allele_string},
    1
  );
  $config->{format} = 'ensembl';
  $config->{delimiter} = ' ';

  my $consequences = $self->get_consequences($c, $config, $string);
  $c->stash->{consequences} = $consequences;

  $self->status_ok( $c, entity => $c->stash->{consequences} );
}


# /vep/:species/id/:id
sub get_id : Chained('get_species') PathPart('id') ActionClass('REST') {
  my ( $self, $c, $rs_id) = @_;

}

sub get_id_GET {
  my ( $self, $c, $rs_id ) = @_;

  if (!$c->stash->{has_variation}) { $c->go('ReturnError', 'custom', ["Species ".$c->stash->{species}." does not have a variation database"]); }
  
  unless ($rs_id) {$c->go('ReturnError', 'custom', ["rs_id is a required parameter for this endpoint"])}

  my $user_config = $c->request->parameters;
  my $config = $self->_include_user_params($c,$user_config);
  $config->{format} = 'id';
  
  my $consequences = $self->get_consequences($c, $config, $rs_id);
  $c->stash->{consequences} = $consequences;

  $self->status_ok( $c, entity => $consequences );
}


# /vep/:species/hgvs/:hgvs
sub get_hgvs : Chained('get_species') PathPart('hgvs') ActionClass('REST') {
  my ($self, $c, $hgvs) = @_;
}

sub get_hgvs_GET {
  my ($self, $c, $hgvs) = @_;

  unless ($hgvs) {$c->go('ReturnError', 'custom', ["HGVS is a required parameter for this endpoint"])}
  
  my $user_config = $c->request->parameters;
  my $config = $self->_include_user_params($c,$user_config);
  $config->{format} = 'hgvs';

  my $consequences = $self->get_consequences($c, $config, $hgvs);
  $c->stash->{consequences} = $consequences;

  $self->status_ok( $c, entity => $consequences );
}

sub get_consequences {
  my ($self, $c, $config, $vfs) = @_;
  my $user_config = $c->request->parameters;

  my ($runner, $consequences);

  $self->_amend_transcript_id($config);

  try {
    $runner = Bio::EnsEMBL::VEP::Runner->new($config);
    $runner->registry($c->model('Registry')->_registry());
    $runner->{plugins} = $config->{plugins} || [];
    $consequences = $runner->run_rest($vfs);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };

  # catch and report errors/warnings
  my $warnings = $runner->warnings();
  $c->go('ReturnError', 'custom', [map {$_->{msg}} @$warnings]) if !@$consequences && @$warnings;

  return $consequences;
}


sub get_id_POST {
  my ($self, $c) = @_;

  if (!$c->stash->{has_variation}) { $c->go('ReturnError', 'custom', ["Species ".$c->stash->{species}." does not have a variation database"]); }
  
  my $post_data = $c->req->data;
  my $config = $self->_include_user_params($c,$post_data);
  unless (exists $post_data->{ids}) {
    $c->go( 'ReturnError', 'custom', [ ' Cannot find "ids" key in your POST. Please check the format of your message against the documentation' ] );
  }
$config->{format} = 'id';
  my @ids = @{$post_data->{ids}};
  $self->assert_post_size($c,\@ids);
  $self->_give_POST_to_VEP($c,\@ids,$config);
}


sub get_hgvs_POST {
  my ($self, $c) = @_;

  my $post_data = $c->req->data;
  my $config = $self->_include_user_params($c,$post_data);
  unless (exists $post_data->{hgvs_notations}) {
    $c->go( 'ReturnError', 'custom', [ ' Cannot find "hgvs_notations" key in your POST. Please check the format of your message against the documentation' ] );
  }
  $config->{format} = 'hgvs';
  my @hgvs = @{$post_data->{hgvs_notations}};
  $self->assert_post_size($c,\@hgvs);
  $self->_give_POST_to_VEP($c,\@hgvs,$config);
}

sub _include_user_params {
  my ($self,$c,$user_config) = @_;

  my %vep_params = %{ $c->config->{'Controller::VEP'} };

  # stash species
  $vep_params{species} = $c->stash->{species};

  # set ucsc_assembly param
  my %assembly_map = (
    'GRCh38' => 'hg38',
    'GRCh37' => 'hg19'
  );
  if(my $mapped = $assembly_map{$c->stash->{assembly}}) {
    $vep_params{ucsc_assembly} = $mapped;
  }

  # copy in params from URL
  # first copy *everything* to %tmp_vep_params from URL ($c->request->params) and POST body ($user_config)
  # we need the unfiltered list to send to _configure_plugins
  # data body ($user_config) takes precedence over URL, so add those second and don't worry about overwrite
  my %tmp_vep_params;
  map { $tmp_vep_params{$_} = $c->request()->param($_)} keys %{$c->request->params()};
  map { $tmp_vep_params{$_} = $user_config->{$_}} keys %{$user_config};

  # only copy allowed keys to %vep_params as we don't want users to be able to meddle
  $vep_params{$_} = $tmp_vep_params{$_} for grep { $self->valid_user_param($_) } keys %tmp_vep_params;
 
  # we currently only have cache for human
  if ($c->stash->{species} ne 'homo_sapiens') {
    delete $vep_params{cache};
    delete $vep_params{fasta};
    $vep_params{database} = 1;
  }
  else {
    $vep_params{database} = 0;
  }

  my $plugin_config = $self->_configure_plugins($c,\%tmp_vep_params,\%vep_params);
  $vep_params{plugins} = $plugin_config if $plugin_config;

  return \%vep_params;
}

sub _amend_transcript_id {
  my ($self, $config) = @_;

  if(exists($config->{transcript_id}) && length($config->{transcript_id}) < 25 
  && !($config->{transcript_id} =~ m/[^A-Z0-9_.]/i))
  {
    $config->{transcript_filter} = "stable_id is " . $config->{transcript_id};
    $config->{no_intergenic} = 1;
  }
}


sub _configure_plugins {
  my ($self,$c,$user_config,$vep_config) = @_;

  # add dir_plugins to Perl's list of include dirs
  # otherwise the plugins have to be somewhere in PERL5LIB on startup
  unshift @INC, $vep_config->{dir_plugins};
  my @plugin_config = ();

  # get config from file
  my $plugin_config_file = $vep_config->{plugin_config};
  return [] unless $plugin_config_file && -e $plugin_config_file;

  my $content = [];
  $content = slurp($plugin_config_file);
  my $VEP_PLUGIN_CONFIG = eval $content;
  $c->log->warn("Could not eval VEP plugin config file: $@\n") if $@;

  # iterate over all defined plugins
  foreach my $plugin_hash(grep {$_->{available}} @{$VEP_PLUGIN_CONFIG->{plugins}}) {
    my $module = $plugin_hash->{key};

    # has user specified it, or is it enabled by default?
    if(defined($user_config->{$module}) || $plugin_hash->{enabled}) {

      # user passes a list of params as a comma-separated string ModuleName=param1,param2,...,paramN
      my @given_params = split(',', $user_config->{$module} || '');

      # we now need to add these to a final list, including any that come from the plugin config file
      my $added_given = 0;
      my @params;
      my $spliceai_file;

      foreach my $param(@{$plugin_hash->{params} || []}) {

        # This is probably not the best way to do this!
        # Basically '@field' should mean insert the value of a field from the form here
        # and '@*' means insert all params here.
        # But since we are just taking a list of params anyway, if we see either
        # type we just add them all and make sure we do it once
        if($param =~ /^\@/ && !$added_given) {
          push @params, @given_params;
          $added_given = 1;
        }
        # SpliceAI - check which file is defined by user
        # param = 1 (default) use the illumina's annotation file
        # param = 2 use the Ensembl annotation file which is defined in config file as snv_ensembl
        elsif(lc $module eq 'spliceai' && $given_params[0] == 2) {
          if($param =~ /snv_ensembl/) {
            my $param_aux = $param;
            $param_aux =~ s/snv_ensembl=//;
            $spliceai_file = $param_aux;
          }
          push @params, $param;
        }
        # CADD - check if species is pig and provide appropriate file based on that
        elsif(lc $module eq 'cadd' && $c->stash->{species} eq "sus_scrofa"){
          next unless $param =~ /^snv_pig=/;

          my $param_aux = $param;
          $param_aux =~ s/snv_pig=//;
          $param = 'snv=' . $param_aux;

          push @params, $param;
        }
        elsif(lc $module eq 'cadd' && ($user_config->{$module} eq "snv_indels" || $user_config->{$module} eq "1")){
          next unless ($param =~ /^snv=/ || $param =~ /^indels=/);
          push @params, $param;
        }
        elsif(lc $module eq 'cadd' && $user_config->{$module} eq "snv"){
          next unless ($param =~ /^snv=/);
          push @params, $param;
        }
        elsif(lc $module eq 'cadd' && $user_config->{$module} eq "indels"){
          next unless ($param =~ /^indels=/);
          push @params, $param;
        }
        elsif(lc $module eq 'cadd' && $user_config->{$module} eq "sv"){
          next unless ($param =~ /^sv=/);
          push @params, $param;
        }
        # other params, such as file paths, get passed from the config
        else {
          push @params, $param;
        }
      }

      # overwrite SpliceAI SNV file
      if(defined $spliceai_file) {
        my @new_params;
        foreach my $spliceai_param (@params) {
          if($spliceai_param =~ /^snv=/) {
            push @new_params, 'snv=' . $spliceai_file;
          }
          else {
            push @new_params, $spliceai_param;
          }
        }
        @params = @new_params;
      }

      ## could probably implement some checking on @params here based on whats in the web form

      # attempt to load the module
      eval qq{
        use $module;
      };
      if($@) {
        $c->log->warn("Failed to use module for VEP plugin $module:\n$@");
        next;
      }
      
      # now check we can instantiate it, passing any parameters to the constructor
      my $instance;
      
      eval {
        $instance = $module->new($vep_config, @params);
      };
      if($@) {
        $c->log->warn("Failed to create instance of VEP plugin $module:\n$@");
        next;
      }

      push @plugin_config, $instance;
    }
  }

  return \@plugin_config;
}

__PACKAGE__->meta->make_immutable;

