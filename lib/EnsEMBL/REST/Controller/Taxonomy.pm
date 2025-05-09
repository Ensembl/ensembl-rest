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

package EnsEMBL::REST::Controller::Taxonomy;

use Moose;
use namespace::autoclean;
use Try::Tiny;
use Bio::EnsEMBL::Utils::Scalar qw/check_ref/;
use Scalar::Util qw/looks_like_number/;
use URI::Escape;
require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

BEGIN {extends 'Catalyst::Controller::REST'; }

# Config variable used to control the name of the schema NCBI Taxa tables are held in
has taxonomy => ( is => 'ro', isa => 'Str', default => 'multi' );

sub taxonomy_root: Chained('/') PathPart('taxonomy') CaptureArgs(0) {
  my ( $self, $c) = @_;
  $c->stash(taxon_adaptor => $c->model('Registry')->get_adaptor($self->taxonomy(), 'compara', 'NCBITaxon'));
}

sub id_GET {}
sub id : Chained('taxonomy_root') PathPart('id') Args(1) ActionClass('REST') {
  my ($self, $c, $id) = @_;
  my $taxon = $self->taxon($c, $id);
  my $simple = $c->request->param('simple');
  $self->status_ok( $c, entity => $self->_encode($taxon, $simple));
}

sub classification_GET {}
sub classification : Chained('taxonomy_root') PathPart('classification') Args(1) ActionClass('REST') {
  my ($self, $c, $id) = @_;
  my $taxon = $self->taxon($c, $id);
  my $classification = $taxon->classification(-AS_ARRAY => 1);
  my $entity = $self->_encode_array($classification);
  $self->status_ok($c, entity => $entity);
}

sub name_GET {}
sub name : Chained('taxonomy_root') PathPart('name') Args(1) ActionClass('REST') {
  my ($self, $c, $id) = @_;
  $id = uri_unescape($id);
  $c->log->debug($id);
  my $simple = $c->request->param('simple');
  my $taxons = $self->_name($c,$id);
  # remove any duplicates in the list
  my %list = map { $_->taxon_id => $_ } @$taxons;
  @$taxons = map { $list{$_} } keys %list;
  
  $self->status_ok($c, entity => $self->_encode_array($taxons,$simple));  
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

sub _name {
  my ($self, $c, $name) = @_;
  my @taxons;
  @taxons = @{ $c->stash->{taxon_adaptor}->fetch_all_nodes_by_name($name) };
  $c->go('ReturnError', 'custom', ["No taxons found with given name '$name'"]) if scalar(@taxons) == 0;
  return \@taxons;
}

sub _encode_array {
  my ($self, $taxons, $ignore_relations) = @_;
  return [ map {$self->_encode($_, $ignore_relations)} @{$taxons}];
}

sub _encode {
  my ($self, $taxon, $ignore_relations) = @_;
  return {} unless check_ref($taxon, 'Bio::EnsEMBL::Compara::NCBITaxon');
  my $entity = {
    id => $taxon->taxon_id(),
    scientific_name => $taxon->scientific_name(),
    leaf => $taxon->is_leaf(),
    name => $taxon->name(),
  };
  foreach my $tag ($taxon->get_all_tags()) {
    my $values = $taxon->get_all_values_for_tag($tag);
    $tag =~ s/\s/_/g;
    $entity->{tags}->{$tag} = $values;
  }
  $entity->{tags}->{'name'} = [ $taxon->name() ];
  if(! $ignore_relations) {
    my $parent = $taxon->parent();
    my $children = $taxon->children();
    if(defined $parent) {
      $entity->{parent} = $self->_encode($parent, 1);
    }
    if(defined $children && scalar(@{$children}) > 0) {
      $entity->{children} = $self->_encode_array($children, 1);
    }
  }
  return $entity;
}

1;
