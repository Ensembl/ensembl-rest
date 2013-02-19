package EnsEMBL::REST::Controller::Taxonomy;

use Moose;
use namespace::autoclean;
use Try::Tiny;
use Bio::EnsEMBL::Utils::Scalar qw/check_ref/;
use Scalar::Util qw/looks_like_number/;
require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

BEGIN {extends 'Catalyst::Controller::REST'; }

# Config variable used to control the name of the schema NCBI Taxa tables are held in
has taxonomy => ( is => 'ro', isa => 'Str', default => 'compara' );

sub taxonomy_root: Chained('/') PathPart('taxonomy') CaptureArgs(0) {
  my ( $self, $c) = @_;
  $c->stash(taxon_adaptor => $c->model('Registry')->get_adaptor('multi', $self->taxonomy(), 'NCBITaxon'));
}

sub id_GET {}
sub id : Chained('taxonomy_root') PathPart('id') Args(1) ActionClass('REST') {
  my ($self, $c, $id) = @_;
  my $taxon = $self->taxon($c, $id);
  $self->status_ok( $c, entity => $self->_encode($taxon));
}

sub classification_GET {}
sub classification : Chained('taxonomy_root') PathPart('classification') Args(1) ActionClass('REST') {
  my ($self, $c, $id) = @_;
  my $taxon = $self->taxon($c, $id);
  my $classification = $taxon->classification(-AS_ARRAY => 1);
  my $entity = $self->_encode_array($classification);
  $self->status_ok($c, entity => $entity);
}

sub childern_GET {}
sub childern : Chained('taxonomy_root') PathPart('children') Args(1) ActionClass('REST') {
  my ($self, $c, $id) = @_;
  my $taxon = $self->taxon($c, $id);
  my $children = $taxon->sorted_children();
  my $entity = $self->_encode_array($children);
  $self->status_ok($c, entity => $entity);
}

sub parent_GET {}
sub parent : Chained('taxonomy_root') PathPart('parent') Args(1) ActionClass('REST') {
  my ($self, $c, $id) = @_;
  my $taxon = $self->taxon($c, $id);
  my $entity = $self->_encode($taxon->parent);
  $self->status_ok($c, entity => $entity);
}

sub taxon {
  my ($self, $c, $id) = @_;
  my $taxon;
  if(looks_like_number($id)) {
    $taxon = $c->stash->{taxon_adaptor}->fetch_node_by_taxon_id($id);
  }
  else {
    $taxon = $c->stash->{taxon_adaptor}->fetch_node_by_name($id);
  }
  $c->go('ReturnError', 'custom', ["No taxon node found for '$id'"]) if ! $taxon;
  return $taxon;
}

sub _encode_array {
  my ($self, $taxons) = @_;
  return [ map {$self->_encode($_)} @{$taxons}];
}

sub _encode {
  my ($self, $taxon) = @_;
  return {} unless $taxon;
  my $entity = {
    id => $taxon->taxon_id(),
    scientific_name => $taxon->scientific_name(),
    leaf => $taxon->is_leaf(),
    name => $taxon->name(),
  };
  foreach my $tag ($taxon->get_all_tags()) {
    my $values = $taxon->get_all_values_for_tag($tag);
    $entity->{tags}->{$tag} = $values;
  }
  return $entity;
}

1;