=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::REST::Controller::Vep;
use Moose;
use Bio::EnsEMBL::Variation::VariationFeature;
use namespace::autoclean;
use Data::Dumper;
use Bio::DB::Fasta;
use Bio::EnsEMBL::Variation::Utils::VEP qw(get_all_consequences parse_line read_cache_info);
use Bio::EnsEMBL::Slice;
use Bio::EnsEMBL::Utils::Sequence qw(reverse_comp);
use Bio::EnsEMBL::Funcgen::MotifFeature;
use Bio::EnsEMBL::Funcgen::RegulatoryFeature;
use Bio::EnsEMBL::Funcgen::BindingMatrix;



require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);
BEGIN { 
  extends 'Catalyst::Controller::REST';
}
__PACKAGE__->config( 'map' => { 'text/javascript' => ['JSONP'] } );
use Try::Tiny;

has 'fasta_db' => (
  isa => 'Bio::DB::Fasta',
  is => 'ro',
  lazy => 1,
  builder => '_find_fasta_cache',
);

has 'fasta' => (
  isa =>'Str',
  is =>'ro'
);

# /vep/:species
sub get_species : Chained('/') PathPart('vep') CaptureArgs(1) {
  my ( $self, $c, $species ) = @_;
  try {
      $c->stash->{species} = $c->model('Registry')->get_alias($species);
      $c->stash( variation_adaptor => $c->model('Registry')->get_adaptor( $species, 'Variation', 'Variation' ) );
      $c->stash(
          variation_feature_adaptor => $c->model('Registry')->get_adaptor( $species, 'Variation', 'VariationFeature' ) );
      $c->stash(
          structural_variation_feature_adaptor => $c->model('Registry')->get_adaptor( $species, 'Variation', 'StructuralVariationFeature' ) );
      $c->stash(ga => $c->model('Registry')->get_adaptor($species, 'Core', 'Gene'));
  } catch {
      $c->go('ReturnError', 'from_ensembl', [$_]);
  };
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
  my ($sr_name) = $c->model('Lookup')->decode_region( $region, 1, 1 );
  $c->model('Lookup')->find_slice( $sr_name );
  $self->status_ok( $c, entity => { data => $region } );
  $c->forward('get_allele');
}

sub get_region_POST {
  my ( $self, $c ) = @_;
  my $post_data = $c->req->data;

  # $c->log->debug(Dumper $post_data);
  # $c->log->debug(Dumper $config->{'Controller::Vep'});
  # handle user config
  my $config = $self->_include_user_params($c,$post_data);
  $config->{va} = $c->stash->{variation_adaptor};
  read_cache_info($config);
  my @variants = @{$post_data->{'variants'}};
  $self->_give_POST_to_VEP($c,\@variants, $config);
}

sub _give_POST_to_VEP {
  my ($self,$c,$data,$config) = @_;
  my @variants = @$data;
  my @vfs;
  foreach my $line (@variants) {
    push @vfs, @{ parse_line($config,$line) };
    # $c->log->debug(Dumper @vfs);
  }
  if ( !@vfs ) {
    $c->log->fatal(qq{no variant features found in post data});
    $c->go( 'ReturnError', 'no_content', [qq{no variant features found in post data}] );
  }
  try {
    
    # Overwrite Slice->seq method to use a local disk cache when using Human
    my $consequences;
    if ($c->stash->{species} eq 'homo_sapiens') {
      $c->log->debug('Farming human out to Bio::DB');
      no warnings 'redefine';
      local *Bio::EnsEMBL::Slice::seq = $self->_new_slice_seq();
      $consequences = get_all_consequences( $config, \@vfs );
    } else {
      $c->log->debug('Query Ensembl');
      $config->{species} = $c->stash->{species}; # override VEP default for human
      $consequences = get_all_consequences( $config, \@vfs );
    }
    $c->stash->{consequences} = $consequences;

    $self->status_ok( $c, entity => { data => $consequences } );
  }
  catch {
    $c->log->fatal(qw{Problem Getting Consequences});
    $c->log->fatal($_);
    $c->log->fatal(Dumper $data);
    $c->go( 'ReturnError', 'custom', [ qq{Problem entry within this batch: } . Dumper $data] );
  };
}




# /vep/:species/region/:region/:allele_string
# Only one argument wanted here, but region is still on the stack and needs to be moved out of the way.
sub get_allele : PathPart('') Args(2) {
    my ( $self, $c, $region, $allele ) = @_;
    $c->log->debug($allele);
    my $s = $c->stash();
    if ( $allele !~ /^[ATGC-]+$/i ) {
        my $error_msg = qq{Allele must be A,T,G or C [got: $allele]};
        $c->go( 'ReturnError', 'custom', [$error_msg] );
    }
    my $reference_base;
    try {
        $reference_base = $s->{slice}->subseq( $s->{start}, $s->{end}, $s->{strand} );
        $s->{reference_base} = $reference_base;
    }
    catch {
        $c->log->fatal(qq{can't get reference base from slice});
        $c->go( 'ReturnError', 'from_ensembl', [$_] );
    };
    $c->go( 'ReturnError', 'custom', ["request for consequence of [$allele] matches reference [$reference_base]"] )
      if $reference_base eq $allele;
    my $allele_string = $reference_base . '/' . $allele;
    $s->{allele_string} = $allele_string;
    $s->{allele}        = $allele;

    my $user_config = $c->request->parameters;
    my $config = $self->_include_user_params($c,$user_config);
    $config->{ga} = $s->{ga};
    my $vf = $self->_build_vf($c);
    my $consequences = get_all_consequences( $config, [$vf]);
    # $c->log->debug(Dumper $consequences);
    $c->stash->{consequences} = $consequences;
    $self->status_ok( $c, entity => { data => $consequences } );
}


# /vep/:species/id/:id
sub get_id : Chained('get_species') PathPart('id') ActionClass('REST') {
  my ( $self, $c, $rs_id) = @_;

}

sub get_id_GET {
  my ( $self, $c, $rs_id ) = @_;
  unless ($rs_id) {$c->go('ReturnError', 'custom', ["rs_id is a required parameter for this endpoint"])}
  my $v = $c->stash()->{variation_adaptor}->fetch_by_name($rs_id);
  $c->go( 'ReturnError', 'custom', [qq{No variation found for RS ID $rs_id}] ) unless $v;
  my $vfs = $c->stash()->{variation_feature_adaptor}->fetch_all_by_Variation($v);
  $c->stash( variation => $v, variation_features => $vfs );

  my $user_config = $c->request->parameters;
  my $config = $self->_include_user_params($c,$user_config);
  $config->{format} = 'id';

  my $consequences = get_all_consequences( $config, $vfs);
  $self->status_ok( $c, entity => { data => $consequences } );
}


sub get_id_POST {
  my ($self, $c) = @_;
  my $post_data = $c->req->data;
  my $config = $self->_include_user_params($c,$post_data);
  $config->{va} = $c->stash->{variation_adaptor};
  my @ids = @{$post_data->{'ids'}};
  $self->_give_POST_to_VEP($c,\@ids,$config);
}

# Cribbed from Utils::VEP
# Turns a series of parameters into a VariationFeature object
sub _build_vf {
  my ($self, $c) = @_;
  my $s = $c->stash;
  my $vf;
  try {
      if($s->{allele_string} !~ /\//) {
          my $so_term;
          
          # convert to SO term
          my %terms = (
              INS  => 'insertion',
              DEL  => 'deletion',
              TDUP => 'tandem_duplication',
              DUP  => 'duplication'
          );
          
          $so_term = defined $terms{$s->{allele_string}} ? $terms{$s->{allele_string}} : $s->{allele_string};
          
          $vf = Bio::EnsEMBL::Variation::StructuralVariationFeature->new_fast({
              start          => $s->{start},
              end            => $s->{end},
              strand         => $s->{strand},
              adaptor        => $s->{structural_variation_feature_adaptor},
              variation_name => 'temp',
              chr            => $s->{sr_name},
              slice          => $s->{slice},
              class_SO_term  => $so_term,
          });
      } else {
        $vf = Bio::EnsEMBL::Variation::VariationFeature->new_fast(
            {
                start         => $s->{start},
                end           => $s->{end},
                strand        => $s->{strand},
                allele_string => $s->{allele_string},
                variation_name => 'temp',
                mapped_weight  => 1,
                chr            => $s->{sr_name},
                slice          => $s->{slice},
                adaptor        => $s->{variation_feature_adaptor},
            }
        );
      }
    }
    catch {
        $c->log->fatal(qq{problem making Bio::EnsEMBL::Variation::VariationFeature object});
        $c->go( 'ReturnError', 'from_ensembl', [$_] );
    };
  return $vf;
}

sub _find_fasta_cache {
  my $self = shift;
  
  my $fasta_db = Bio::DB::Fasta->new($self->fasta);
  return $fasta_db;
}


sub _new_slice_seq {
  # replacement seq method to read from FASTA DB
  my $self = shift;
  my $fasta_db = $self->fasta_db;
  return sub {
    my $self = shift;
    my $seq = $fasta_db->seq( $self->seq_region_name, $self->start => $self->end );
    $seq ||= 'N' x $self->length();
    reverse_comp( \$seq ) if $self->strand < 0;
    # default to a string of Ns if we couldn't get sequence
    return $seq;
  };
};

sub _include_user_params {
  my ($self,$c,$user_config) = @_;
  # This list stops users altering more crucial variables.
  my @valid_keys = (qw/hgvs ccds numbers domains canonical protein strip maf_1kg maf_esp pubmed/);
  
  my %vep_params = %{ $c->config->{'Controller::Vep'} };
  # $c->log->debug("Before ".Dumper \%vep_params);
  map { $vep_params{$_} = $user_config->{$_} if ($_ ~~ @valid_keys ) } keys %{$user_config};
  # $c->log->debug("After ".Dumper \%vep_params);
  return \%vep_params;
}

__PACKAGE__->meta->make_immutable;

