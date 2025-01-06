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

package EnsEMBL::REST::Controller::Cafe;
use Moose;
use namespace::autoclean;
use Try::Tiny;
use Bio::EnsEMBL::Compara::Utils::CAFETreeHash;
use Data::Dumper;

require EnsEMBL::REST;

BEGIN { extends 'Catalyst::Controller::REST'; }

__PACKAGE__->config(
  default => 'text/html',
  map => {
    'text/x-nh'           => [qw/View NHTree/],
  }
);

EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

my $CONTENT_TYPE_REGEX = qr/(?^:(?:text\/(?:javascript|x-yaml)|application\/json))/;

sub get_genetree_cafe_GET { }

sub get_genetree_cafe : Chained('/') PathPart('cafe/genetree/id') Args(1) ActionClass('REST') {
  my ($self, $c, $id) = @_;
  my $s = $c->stash();
  try {
    my $gt = $c->model('Lookup')->find_genetree_by_stable_id($id);
    my $cafe = $c->model('Lookup')->find_cafe_by_genetree($gt);
    $self->_set_cafe_species_tree($c, $cafe);
    } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  }
}

sub get_genetree_cafe_by_species_member_id_GET { }

sub get_genetree_cafe_by_species_member_id : Chained('/') PathPart('cafe/genetree/member/id') Args(2) ActionClass('REST') {
  my ($self, $c, $species, $id) = @_;
  $c->request->param('species', $species);  # lookup method gets species from parameter

  try {
    my $gt = $c->model('Lookup')->find_genetree_by_member_id($id);
    my $cafe = $c->model('Lookup')->find_cafe_by_genetree($gt);
    $self->_set_cafe_species_tree($c, $cafe);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  }
}

sub get_genetree_cafe_by_symbol_GET { }

sub get_genetree_cafe_by_symbol : Chained('/') PathPart('cafe/genetree/member/symbol') Args(2) ActionClass('REST') {
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
    my $cafe = $c->model('Lookup')->find_cafe_by_genetree($gt);
    $self->_set_cafe_species_tree($c, $cafe);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  }
}

sub _set_cafe_species_tree {
  my ($self, $c, $cafe) = @_;
	if($self->is_content_type($c, $CONTENT_TYPE_REGEX)) {
  	my $hash = Bio::EnsEMBL::Compara::Utils::CAFETreeHash->convert($cafe);
		return $self->status_ok($c, entity => $hash);
  }
  return $self->status_ok($c, entity => $cafe);
}

with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;
