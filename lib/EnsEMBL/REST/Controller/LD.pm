=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::REST::Controller::LD;
use Moose;
use namespace::autoclean;
use Try::Tiny;
use Bio::EnsEMBL::Utils::Scalar qw/check_ref/;
require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

BEGIN {extends 'Catalyst::Controller::REST';}
with 'EnsEMBL::REST::Role::PostLimiter';

sub species: Chained('/') PathPart('ld') CaptureArgs(1) {
  my ( $self, $c, $species) = @_;
  $c->stash(species => $species);
}

sub id: Chained('species') PathPart('') ActionClass('REST') {}

sub id_GET {
  my ($self, $c, $id) = @_;
  my $LDFeatureContainer;
  try {
    $LDFeatureContainer = $c->model('LDFeatureContainer')->fetch_LDFeatureContainer_variation_name($id);
  } catch {
    $c->go('ReturnError', 'from_ensembl', []) if $_ =~ /STACK/;    
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  $self->status_ok($c, entity => $LDFeatureContainer);
}

__PACKAGE__->meta->make_immutable;
1;
