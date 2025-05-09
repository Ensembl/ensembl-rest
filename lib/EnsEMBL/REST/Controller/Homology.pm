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

package EnsEMBL::REST::Controller::Homology;
use Moose;
use namespace::autoclean;
use Try::Tiny;
use Bio::EnsEMBL::Compara::Utils::HomologyHash;

require EnsEMBL::REST;

EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

BEGIN { extends 'Catalyst::Controller::REST'; }

__PACKAGE__->config(
  map => {
    'text/x-orthoxml+xml' => [qw/View OrthoXML_homology/],
  }
);

#We want to find every "non-special" format. To generate the regex used then invoke this command:
#perl -MRegexp::Assemble -e 'my $ra = Regexp::Assemble->new; $ra->add($_) for qw(application\/json text\/javascript text\/xml ); print $ra->re, "\n"'
my $CONTENT_TYPE_REGEX = qr/(?^:(?:text\/(?:javascript|xml)|application\/json))/;


my $FORMAT_LOOKUP = { full => 1, condensed => 1 };
my $TYPE_TO_COMPARA_TYPE = { orthologues => 'ENSEMBL_ORTHOLOGUES', paralogues => 'ENSEMBL_PARALOGUES', projections => 'ENSEMBL_PROJECTIONS', all => ''};

has default_compara => ( is => 'ro', isa => 'Str', default => 'vertebrates' );

sub get_adaptors :Private {
  my ($self, $c) = @_;

  try {
    my $species = $c->stash()->{species};
    my $param_compara = $c->request()->param('compara');
    my $default_compara = $self->default_compara();
    my $compara_dba = $c->model('Registry')->get_best_compara_DBAdaptor($species, $param_compara, $default_compara);
    my $gma = $compara_dba->get_GeneMemberAdaptor();
    my $ha = $compara_dba->get_HomologyAdaptor();
    my $ga = $compara_dba->get_GenomeDBAdaptor();

    $c->stash(
      gene_member_adaptor => $gma,
      homology_adaptor => $ha,
      genome_adaptor => $ga,
    );
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
}

sub fetch_by_species_ensembl_gene : Chained("/") PathPart("homology/id") Args(2)  {
  my ( $self, $c, $species, $id ) = @_;

  $c->stash(species => $species, stable_ids => [$id]);
  $c->detach('get_orthologs');
}

sub fetch_by_gene_symbol : Chained("/") PathPart("homology/symbol") Args(2)  {
  my ( $self, $c, $species, $gene_symbol ) = @_;
  my $genes;
  try {
    $c->stash(species => $species);
    $c->request->param('object', 'gene');
    my $local_genes = $c->model('Lookup')->find_objects_by_symbol($gene_symbol);
    $genes = [grep { $_->slice->is_reference() } @{$local_genes}];
  } catch {
    $c->log->fatal(qq{No genes found for external id: $gene_symbol});
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  unless ( defined $genes ) {
      $c->log->fatal(qq{Nothing found in DB for : [$gene_symbol]});
      $c->go( 'ReturnError', 'custom', [qq{No content for [$gene_symbol]}] );
  }
  my @gene_stable_ids = map { $_->stable_id } @$genes;
  if(! @gene_stable_ids) {
    $c->go('ReturnError','custom', "Cannot find a suitable gene for the symbol '${gene_symbol}' and species '${species}");
  }
  $c->stash->{stable_ids} = \@gene_stable_ids;
  $c->detach('get_orthologs');
}

sub get_orthologs : Args(0) ActionClass('REST') {
  my ($self, $c) = @_;
  my $s = $c->stash();
  
  #Get the compara DBAdaptor
  $c->forward('get_adaptors');
  
  # get defaults from config
  my $compara_defaults = $c->config->{'Model::Compara'};

  # Sort out the encoder
  my $format = $c->request->param('format') || $compara_defaults->{format};
  my $target = $FORMAT_LOOKUP->{$format};
  $c->go('ReturnError', 'custom', [qq{The format '$format' is not an understood encoding}]) unless $target;
  
  #Sort out the type of response
  my $user_type = $c->request->param('type') || $compara_defaults->{type};
  my $method_link_type= $TYPE_TO_COMPARA_TYPE->{lc($user_type)};
  $c->go('ReturnError', 'custom', [qq{The type '$user_type' is not a known available type}]) unless defined $method_link_type;
  $c->stash(method_link_type => $method_link_type);
  
  my @final_homologies;
  
  my $species = $s->{species};  # species is assumed to have been stashed
  my $gdb = try {
    $s->{genome_adaptor}->fetch_by_name_assembly( $species );
  } catch {
    $c->log->warn("Could not fetch GenomeDB for species [$species], will try aliases");
  };

  if (!defined $gdb) {
    my $resolved_species_name = $c->model('Registry')->get_alias( $species );
    $gdb = try {
      $s->{genome_adaptor}->fetch_by_name_assembly( $resolved_species_name );
    } catch {
      $c->log->error(qq{Species not found in db: $species});
      $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
      $c->go('ReturnError', 'custom', [qq{$_}]);
    };
  }

  #Loop for stable IDs
  foreach my $stable_id ( @{ $s->{stable_ids} } ) {
    my $member = try {
      $c->log->debug('Searching for gene member linked to ', $stable_id, ' in GenomeDB ', $gdb->name);
      $s->{gene_member_adaptor}->fetch_by_stable_id_GenomeDB( $stable_id, $gdb );
    } catch {
      $c->log->error(qq{Stable Id not found id db: $stable_id});
      $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
      $c->go('ReturnError', 'custom', [qq{$_}]);
    };

    if(! defined $member) {
      $c->log->debug('The ID '.$stable_id.' produced no member in compara');
      next;
    }

    my $all_homologies;
    try {
      my $ha = $s->{homology_adaptor};
      $all_homologies = $ha->fetch_all_by_Member($member,
          -TARGET_TAXON     => ($c->request->param('target_taxon')   ? [$c->request->param('target_taxon')]   : undef),
          -TARGET_SPECIES   => ($c->request->param('target_species') ? [$c->request->param('target_species')] : undef),
          -METHOD_LINK_TYPE => ($method_link_type || undef),
      );
    } catch {
      $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
      $c->go('ReturnError', 'custom', [qq{$_}]);
    };
    push(@final_homologies, {
      id => $stable_id,
      homologies => $all_homologies,
    });
  }
  
  $c->stash(homology_data => \@final_homologies);
}


sub get_orthologs_GET {
  my ( $self, $c ) = @_;

  # get defaults from config
  my $compara_defaults = $c->config->{'Model::Compara'};

  if($self->is_content_type($c, $CONTENT_TYPE_REGEX)) {
    my $format          = $c->request->param('format') || $compara_defaults->{format};
    my $sequence_param  = $c->request->param('sequence') || $compara_defaults->{sequence};
    my $seq_type        = $sequence_param eq 'protein' ? undef : 'cds';
    my $no_seq          = $sequence_param eq 'none' ? 1 : 0;
    my $aligned         = $c->request->param('aligned') // $compara_defaults->{aligned};
    my $cigar_line      = $c->request->param('cigar_line') // $compara_defaults->{cigar_line};

    try {
      foreach my $ref (@{$c->stash->{homology_data}}) {
        $ref->{homologies} = Bio::EnsEMBL::Compara::Utils::HomologyHash->convert($ref->{homologies}, -FORMAT_PRESET => $format, -NO_SEQ => $no_seq, -SEQ_TYPE => $seq_type, -ALIGNED => $aligned, -CIGAR_LINE => $cigar_line);
      }
    } catch {
      $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
      $c->go('ReturnError', 'custom', [qq{$_}]);
    };
    return $self->status_ok( $c, entity => { data => $c->stash->{homology_data} } );

  } else {
    # Let's use the OrthoXML writer
    my @homologies;
    try {
      foreach my $ref (@{$c->stash->{homology_data}}) {
        push @homologies, @{$ref->{homologies}};
      }
    } catch {
      $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
      $c->go('ReturnError', 'custom', [qq{$_}]);
    };
    return $self->status_ok($c, entity => \@homologies);
  }
}

with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;
