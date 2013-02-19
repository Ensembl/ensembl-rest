package EnsEMBL::REST::Controller::Ontology;

use Moose;
use namespace::autoclean;
use Try::Tiny;
use Bio::EnsEMBL::Utils::Scalar qw/check_ref/;
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
  $self->status_ok( $c, entity => $self->_encode($term));
}

sub name_GET {}
sub name : Chained('ontology_root') PathPart('name') Args(1) ActionClass('REST') {
  my ($self, $c, $name) = @_;
  my $ontology = $c->request()->param('ontology');
  my $terms = $c->stash->{ontology_adaptor}->fetch_all_by_name($name, $ontology);
  $self->status_ok( $c, entity => $self->_encode_array($terms));
}

sub ancestors_GET {}
sub ancestors : Chained('ontology_root') PathPart('ancestors') Args(1) ActionClass('REST') {
  my ($self, $c, $id) = @_;
  my $term = $self->term($c, $id);
  my $ontology = $c->request->param('ontology');
  my $terms = $c->stash()->{ontology_adaptor}->fetch_all_by_ancestor_term($term, $ontology);
  $self->status_ok($c, entity => $self->_encode_array($terms));
}

sub childern_GET {}
sub childern : Chained('ontology_root') PathPart('children') Args(1) ActionClass('REST') {
  my ($self, $c, $id) = @_;
  my $term = $self->term($c, $id);
  my $relation = $c->request->param('relation') || [];
  $relation = ( check_ref($relation, 'ARRAY') ) ? $relation : [$relation];
  my $terms = $term->children(@{$relation});
  $self->status_ok($c, entity => $self->_encode_array($terms));
}

sub parents_GET {}
sub parents : Chained('ontology_root') PathPart('parents') Args(1) ActionClass('REST') {
  my ($self, $c, $id) = @_;
  my $term = $self->term($c, $id);
  my $relation = $c->request->param('relation') || [];
  $relation = ( check_ref($relation, 'ARRAY') ) ? $relation : [$relation];
  my $terms = $term->parents(@{$relation});
  $self->status_ok($c, entity => $self->_encode_array($terms));
}

sub descendents_GET {}
sub descendents : Chained('ontology_root') PathPart('descendents') Args(1) ActionClass('REST') {
  my ($self, $c, $id) = @_;
  my $term = $self->term($c, $id);
  my $r = $c->request();
  my ($subset, $closest_terms, $zero_distance, $cross_ontology) = map { $r->param($_) } qw/subset closest_terms zero_distance cross_ontology/;
  my $terms = $c->stash()->{ontology_adaptor}->fetch_all_by_descendant_term($term, $subset, $closest_terms, $zero_distance, $cross_ontology);
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
  }
  return $entity;
}

1;