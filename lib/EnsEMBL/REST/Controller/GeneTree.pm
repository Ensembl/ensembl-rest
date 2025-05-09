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

sub get_genetree_by_species_member_id_GET { }

sub get_genetree_by_species_member_id : Chained('/') PathPart('genetree/member/id') Args(2) ActionClass('REST') {
  my ($self, $c, $species, $id) = @_;
  $c->request->param('species', $species);  # lookup method gets species from parameter

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

  my $prune_species     = $c->request->param('prune_species') ? [$c->request->param('prune_species')] : undef;
  my $prune_taxons      = $c->request->param('prune_taxon') ? [$c->request->param('prune_taxon')] : undef;
  my ($subtree_filter)  = $c->request->param('subtree_node_id');
  my $aligned           = $c->request()->param('aligned') || $c->request()->param('phyloxml_aligned') ? 1 : 0;
  my $sequence          = $c->request()->param('sequence') || $c->request()->param('phyloxml_sequence') || 'protein';
  my $cigar_line        = $c->request()->param('cigar_line') ? 1 : 0;
  my $cdna              = $sequence eq 'cdna' ? 1 : 0;
  my $no_sequences      = $sequence eq 'none' ? 1 : 0;

  $gt->preload(
      -PRUNE_SPECIES => $prune_species,
      -PRUNE_TAXA => $prune_taxons,
      -PRUNE_SUBTREE => $subtree_filter,
  );

  if($self->is_content_type($c, $CONTENT_TYPE_REGEX)) {
    # If it wasn't a special format convert GT into a Hash data structure and let the normal serialisation
    # code deal with it.
    my $hash = Bio::EnsEMBL::Compara::Utils::GeneTreeHash->convert ($gt, -no_sequences => $no_sequences, -aligned => $aligned, -cdna => $cdna, -exon_boundaries => 0, -gaps => 0, -cigar_line => $cigar_line);
    $gt->release_tree();
    return $self->status_ok($c, entity => $hash);
  }
  return $self->status_ok($c, entity => $gt);
}


with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;
