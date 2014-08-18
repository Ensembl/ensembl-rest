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

package EnsEMBL::REST::Controller::Lookup;
use Moose;
use namespace::autoclean;
use Try::Tiny;

BEGIN {extends 'Catalyst::Controller::REST'; }

require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

my $FORMAT_TYPES = { full => 1, condensed => 1 };

sub old_id_GET {}

sub old_id : Chained('') Args(1) PathPart('lookup') {
  my ($self, $c,$id) = @_;
  $c->go('/lookup/id', $id);
}

sub id : Chained('') PathPart('lookup/id') ActionClass('REST') {
  my ($self, $c, $id) = @_;

  # output format check
  my $format = $c->request->param('format') || 'full';
  $c->go('ReturnError', 'custom', [qq{The format '$format' is not an understood encoding}]) unless $FORMAT_TYPES->{$format};

}

sub id_GET {
  my ($self, $c, $id) = @_;
  my $features;
  try {
    $features = $c->model('Lookup')->find_and_locate_object($id);
    $c->go('ReturnError', 'custom',  [qq{No valid lookup found for ID $id}]) unless $features->{species};
  }
  catch {
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  $self->status_ok( $c, entity => $features);
}

sub id_POST {
  my ($self, $c) = @_;
  my $post_data = $c->req->data;

  my $id_list = $post_data->{'ids'};
  my $feature_hash;
  try {
    $feature_hash = $c->model('Lookup')->find_and_locate_list($id_list);
  };

  $self->status_ok( $c, entity => $feature_hash);
}

sub symbol : Chained('/') PathPart('lookup/symbol') ActionClass('REST') {
  my ($self, $c, $species, $symbol) = @_;
  unless (defined $species) { $c->go('ReturnError', 'custom', [qq{Species must be provided as part of the URL.}])}
  $c->stash(species => $species);

  # output format check
  my $format = $c->request->param('format') || 'full';
  $c->go('ReturnError', 'custom', [qq{The format '$format' is not an understood encoding}]) unless $FORMAT_TYPES->{$format};
}


sub symbol_GET {
  my ($self, $c, $species, $symbol) = @_;
  my $features;
  try {
    $features = $c->model('Lookup')->find_gene_by_symbol($symbol);
    $c->go('ReturnError', 'custom',  [qq{No valid lookup found for symbol $symbol}]) unless $features->{species};
  }
  catch {
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  $self->status_ok( $c, entity => $features);
}

sub symbol_POST {
  my ($self,$c) = @_;
  my $post_data = $c->req->data;
  unless (exists $post_data->{'symbols'}) {
    $c->go('ReturnError', 'custom', [qq{POST body must contain 'symbols' key with array of values}]);
  }
  my $symbol_list = $post_data->{'symbols'};
  my $feature_hash;
  try {
    $feature_hash = $c->model('Lookup')->find_genes_by_symbol_list($symbol_list);
  };
  # catch {
  #   $c->go('ReturnError','custom', [qq{$_}]);
  # };
  $self->status_ok( $c, entity => $feature_hash);
}

__PACKAGE__->meta->make_immutable;

1;
