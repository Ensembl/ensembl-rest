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

package EnsEMBL::REST::Controller::Variation;

use Moose;
use namespace::autoclean;
use Try::Tiny;
use Bio::EnsEMBL::Utils::Scalar qw/check_ref/;
require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);
=pod

/variation/species/rs1333049

application/json

=cut

BEGIN {extends 'Catalyst::Controller::REST'; }
with 'EnsEMBL::REST::Role::PostLimiter';


sub species: Chained('/') PathPart('variation') CaptureArgs(1) {
  my ( $self, $c, $species) = @_;
  $c->stash(species => $species);
}

sub id: Chained('species') PathPart('') ActionClass('REST') {}

sub id_GET {
  my ($self, $c, $id) = @_;
  my $variation;
  try {
    $variation = $c->model('Variation')->fetch_variation($id);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  $self->status_ok($c, entity => $variation);
}

sub id_POST {
  my ($self, $c) = @_;
  my %variations;
  my $data = $c->request->data;
  my $id_list = $data->{ids} if exists $data->{ids};
  $self->assert_post_size($c,$id_list);
  foreach my $id (@$id_list) {
    try {
      my $variation_hash = $c->model('Variation')->fetch_variation($id);
      # $c->log->debug('Variation'.$variation_hash->{name}) if $variation_hash;
      $variations{$id} = $variation_hash if $variation_hash;
    } catch {$c->log->debug('Problems:'.$_)};
  }
  $self->status_ok($c, entity => \%variations);
}




__PACKAGE__->meta->make_immutable;

1;
