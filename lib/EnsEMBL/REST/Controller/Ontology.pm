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

package EnsEMBL::REST::Controller::Ontology;

use Moose;
use namespace::autoclean;
use Try::Tiny;
use Bio::EnsEMBL::Utils::Scalar qw/wrap_array/;
use Data::Dumper;
require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

BEGIN {extends 'Catalyst::Controller::REST'; }

has ontology => ( is => 'ro', isa => 'Str', default => 'ontology' );

sub ontology_root: Chained('/') PathPart('ontology') CaptureArgs(0) {
  my ( $self, $c) = @_;
  $c->stash(ontology_adaptor => $c->model('Registry')->get_adaptor('multi', $self->ontology(), 'OntologyTerm'));
}

sub id_GET {}
sub id : Chained('ontology_root') PathPart('id') Args(1) ActionClass('REST') {
  my ($self, $c, $id) = @_;
  my $term = $self->term($c, $id);
  $self->enhance_terms($c, [$term]);
  $self->status_ok( $c, entity => $self->_encode($term));
}

sub name_GET {}
sub name : Chained('ontology_root') PathPart('name') Args(1) ActionClass('REST') {
  my ($self, $c, $name) = @_;
  my $ontology = $c->request()->param('ontology');
  my $terms = $c->stash->{ontology_adaptor}->fetch_all_by_name($name, $ontology);
  $c->go('ReturnError', 'custom',  [qq{No valid terms found for ontology name $name}]) unless @{$terms};
  $self->enhance_terms($c, $terms);
  $self->status_ok( $c, entity => $self->_encode_array($terms));
}

sub enhance_terms {
  my ($self, $c, $terms) = @_;
  return if $c->request->param('simple');
  my $relation = $c->request->param('relation') || [];
  $relation = wrap_array($relation);
  foreach my $t (@{$terms}) {
    my $parents = $t->parents(@{$relation});
    my $children = $t->children(@{$relation});
    $t->{tmp} = {parents => $parents, children => $children};
  }
  return;
}

sub ancestors_GET {}
sub ancestors : Chained('ontology_root') PathPart('ancestors') Args(1) ActionClass('REST') {
  my ($self, $c, $id) = @_;
  my $term = $self->term($c, $id);
  my $ontology = $c->request->param('ontology');
  my $terms = $c->stash()->{ontology_adaptor}->fetch_all_by_ancestor_term($term, $ontology);
  $self->status_ok($c, entity => $self->_encode_array($terms));
}

sub descendants_GET {}
sub descendants : Chained('ontology_root') PathPart('descendants') Args(1) ActionClass('REST') {
  my ($self, $c, $id) = @_;
  my $term = $self->term($c, $id);
  my $r = $c->request();
  
  my $subset = $r->param('subset');
  my $closest_terms = $r->param('closest_terms');
  my $zero_distance = $r->param('zero_distance');
  my $ontology = $r->param('ontology');
  
  my $terms = $c->stash()->{ontology_adaptor}->fetch_all_by_descendant_term($term, $subset, $closest_terms, $zero_distance, $ontology);
  $self->status_ok($c, entity => $self->_encode_array($terms));
}

sub ancestors_chart_GET {}
sub ancestors_chart : Chained('ontology_root') PathPart('ancestors/chart') Args(1) ActionClass('REST') {
  my ($self, $c, $id) = @_;
  my $term = $self->term($c, $id);
  my $r = $c->request();
  my $ontology = $c->request->param('ontology');
  my $raw_chart = $c->stash()->{ontology_adaptor}->_fetch_ancestor_chart($term, $ontology);
  my $processed_chart = {};
  foreach my $term_accession (keys %{$raw_chart}) {
    my $raw_ancestor_hash = $raw_chart->{$term_accession};
    my $term = $self->_encode($raw_ancestor_hash->{term});
    my $processed_ancestor_hash = { term => $term };
    my @relations = grep { $_ ne 'term' } keys %{$raw_ancestor_hash};
    foreach my $relation (@relations) {
      my $processed_relations = $self->_encode_array($raw_ancestor_hash->{$relation});
      $processed_ancestor_hash->{$relation} = $processed_relations;
    }
    $processed_chart->{$term_accession} = $processed_ancestor_hash;
  }
  $self->status_ok($c, entity => $processed_chart);
}

sub term {
  my ($self, $c, $id) = @_;
  my $term = $c->stash->{ontology_adaptor}->fetch_by_accession($id);
  $c->go('ReturnError', 'custom', ["No ontology term found for '$id'"]) if ! $term;
  $c->go('ReturnError', 'custom', ["No ontology term found for '$id'"]) if ! $term->dbID();
  return $term;
}

sub _encode_array {
  my ($self, $terms) = @_;
  return [ map {$self->_encode($_)} @{$terms}];
}

sub _encode {
  my ($self, $term) = @_;
  my $entity = {};
  if($term->dbID()) {
    $entity = {
      accession => $term->accession(),
      name => $term->name(),
      ontology => $term->ontology(),
      definition => $term->definition(),
      namespace => $term->namespace(),
      synonyms => $term->synonyms(),
      subsets => $term->subsets(),
    };
    if(exists $term->{tmp}) {
      $entity->{parents} = $self->_encode_array($term->{tmp}->{parents});
      $entity->{children} = $self->_encode_array($term->{tmp}->{children});
      delete $term->{tmp};
    }
  }
  return $entity;
}

1;