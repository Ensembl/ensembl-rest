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

__PACKAGE__->config(
  map => {
    'text/x-gff3' => [qw/View GFF3/],
  }
);

=pod

/variation/species/rs1333049

application/json
text/x-gff3

=cut

BEGIN {extends 'Catalyst::Controller::REST'; }


sub species: Chained('/') PathPart('variation') CaptureArgs(1) {
  my ( $self, $c, $species) = @_;
  $c->stash(species => $species);
}

sub id_GET {}


sub id: Chained('species') PathPart('') Args(1) ActionClass('REST') {
  my ($self, $c, $id) = @_;
  my $variation;
  try {
    $variation = $c->model('Variation')->fetch_variation($id);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [$_]);
  };
  $self->status_ok($c, entity => $variation);
}


__PACKAGE__->meta->make_immutable;

1;
