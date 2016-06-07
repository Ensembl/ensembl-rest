=head1 LICENSE

Copyright [2016] EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::REST::Controller::GeneTree;
use Moose;
use namespace::autoclean;
use Try::Tiny;
use Bio::EnsEMBL::Compara::Utils::GeneTreeHash;
require EnsEMBL::REST;

BEGIN { extends 'Catalyst::Controller::REST'; }

__PACKAGE__->config(
  default => 'text/html',
  map => {
    'text/html'           => [qw/View PhyloXMLHTML/],
    'text/x-phyloxml+xml' => [qw/View PhyloXML/],
    'text/x-orthoxml+xml' => [qw/View OrthoXML/],
    'text/x-phyloxml'     => [qw/View PhyloXML/], #naughty but needs must
    'text/x-nh'           => [qw/View NHTree/],
    'text/xml'            => [qw/View PhyloXML/],
  }
);

EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

#We want to find every "non-special" format. To generate the regex used then invoke this command:
#perl -MRegexp::Assemble -e 'my $ra = Regexp::Assemble->new; $ra->add($_) for qw(application\/json text\/javascript text\/x-yaml ); print $ra->re, "\n"'
my $CONTENT_TYPE_REGEX = qr/(?^:(?:text\/(?:javascript|x-yaml)|application\/json))/;

sub get_genetree_GET { }

sub get_genetree : Chained('/') PathPart('genetree/id') Args(1) ActionClass('REST') {
  my ($self, $c, $id) = @_;
  my $s = $c->stash();
  try {
    my $gt = $c->model('Lookup')->find_genetree_by_stable_id($id);
    $self->_set_genetree($c, $gt);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  }
}

sub get_genetree_by_member_id_GET { }

sub get_genetree_by_member_id : Chained('/') PathPart('genetree/member/id') Args(1) ActionClass('REST') {
  my ($self, $c, $id) = @_;
   
  try {
    my $gt = $c->model('Lookup')->find_genetree_by_member_id($id);
    $self->_set_genetree($c, $gt);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  }
}

sub get_genetree_by_symbol_GET { }

sub get_genetree_by_symbol : Chained('/') PathPart('genetree/member/symbol') Args(2) ActionClass('REST') {
  my ($self, $c, $species, $symbol) = @_;
  $c->stash(species => $species);
  my $object_type = $c->request->param('object_type');
  unless ($object_type) {$c->request->param('object_type','gene')};
  unless ($c->request->param('db_type') ) {$c->request->param('db_type','core')}; 
  
  my @objects = @{$c->model('Lookup')->find_objects_by_symbol($symbol) };
  my @genes = grep { $_->slice->is_reference() } @objects;
  $c->log()->debug(scalar(@genes). " objects found with symbol: ".$symbol);
  $c->go('ReturnError', 'custom', ["Lookup found nothing."]) unless (@genes && scalar(@genes) > 0);
  
  my $stable_id = $genes[0]->stable_id;
  
  try {
    my $gt = $c->model('Lookup')->find_genetree_by_member_id($stable_id);
    $self->_set_genetree($c, $gt);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  }
}

sub _set_genetree {
  my ($self, $c, $gt) = @_;

  my $species_filter;
  if($c->request->param('prune_species') || $c->request->param('prune_taxon')) {
    $c->log->debug('Limiting on species/taxons');
    $species_filter = $self->_find_species($gt, $c);
  }
  $gt->preload($species_filter);

  my $aligned = $c->request()->param('aligned') || $c->request()->param('phyloxml_aligned') ? 1 : 0;
  my $sequence = $c->request()->param('sequence') || $c->request()->param('phyloxml_sequence') || 'protein';
  my $cigar_line = $c->request()->param('cigar_line') ? 1 : 0;
  my $cdna = $sequence eq 'cdna' ? 1 : 0;
  my $no_sequences = $sequence eq 'none' ? 1 : 0;
  my $seq_type = $sequence eq 'cdna' ? 'cds' : undef;
  $gt->_load_all_missing_sequences($seq_type) unless $no_sequences;

  if($self->is_content_type($c, $CONTENT_TYPE_REGEX)) {
    # If it wasn't a special format convert GT into a Hash data structure and let the normal serialisation
    # code deal with it.
    my $hash = Bio::EnsEMBL::Compara::Utils::GeneTreeHash->convert ($gt, -no_sequences => $no_sequences, -aligned => $aligned, -cdna => $cdna, -species_common_name => 0, -exon_boundaries => 0, -gaps => 0, -full_tax_info => 0, -cigar_line => $cigar_line);
    return $self->status_ok($c, entity => $hash);
  }
  return $self->status_ok($c, entity => $gt);
}

# TODO: move to Compara side
sub _find_species {
  my ($self, $gt, $c) = @_;

  my $mlssa = $gt->adaptor->db->get_MethodLinkSpeciesSetAdaptor();
  my $gdba = $gt->adaptor->db->get_GenomeDBAdaptor();

  my $registry = $c->model('Registry');
  my %unique_genome_dbs;

  # List species names
  my @prune_species = $c->request->param('prune_species');
  foreach my $target (@prune_species) {
    my $species_name = $registry->get_alias($target);
    if(! $species_name) {
      $c->go('ReturnError', 'custom', "Nothing is known to this server about the species name '${target}'");
    }
    my $gdb;
    try {
      $gdb = $gdba->fetch_by_name_assembly($species_name);
    } catch {
      my $meta_c = $registry->get_adaptor($species_name, 'core', 'MetaContainer');
      $gdb = $gdba->fetch_by_name_assembly($meta_c->get_production_name());
    };
    if($gdb) {
      $unique_genome_dbs{$gdb->dbID()} = 1;
    }
    else {
      $c->go('ReturnError', 'custom', "Cannot convert '${target}' into a valid GenomeDB object. Please try again with a different value");
    }
  }

  #Could be taxon identifiers though
  my @prune_taxons = $c->request->param('prune_taxon');
  foreach my $taxon (@prune_taxons) {
    foreach my $gdb (@{ $gdba->fetch_all_by_ancestral_taxon_id($taxon) }) {
      $unique_genome_dbs{$gdb->dbID()} = 1;
    }
  }

  return [keys %unique_genome_dbs];
}


with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;
