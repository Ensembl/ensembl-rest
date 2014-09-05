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

package EnsEMBL::REST::Controller::Assembly;

use Moose;
use namespace::autoclean;
use Try::Tiny;
require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);


BEGIN {extends 'Catalyst::Controller::REST'; }

sub species: Chained('/') PathPart('info/assembly') CaptureArgs(1) {
  my ( $self, $c, $species) = @_;
  $c->stash(species => $species);
}

sub info_GET {}

sub info: Chained('species') PathPart('') Args(0) ActionClass('REST') {
  my ($self, $c) = @_;
  my $assembly_info;
  try {
    $assembly_info = $c->model('Assembly')->fetch_info(); 
  }
  catch {
      $c->go( 'ReturnError', 'from_ensembl', [$_] );
  };
  $self->status_ok( $c, entity => $assembly_info);
}

sub seq_region_GET {}

sub seq_region: Chained('species') PathPart('') Args(1) ActionClass('REST') {
  my ( $self, $c, $name) = @_;
  my $include_bands = $c->request->param('bands') || 0;
  my $slice = $c->model('Lookup')->find_slice($name);
  my $bands = $c->model('Assembly')->get_karyotype_info($slice) if $include_bands;
  if ($bands && scalar(@$bands) > 0) {
    $self->status_ok( $c, entity => { 
      length => $slice->length(),
      coordinate_system => $slice->coord_system()->name(),
      assembly_exception_type => $slice->assembly_exception_type(),
      is_chromosome => $slice->is_chromosome(),
      karyotype_band => $bands,
      assembly_name => $slice->coord_system()->version(),
    });
  } else {
    $self->status_ok( $c, entity => {
      length => $slice->length(),
      coordinate_system => $slice->coord_system()->name(),
      assembly_exception_type => $slice->assembly_exception_type(),
      is_chromosome => $slice->is_chromosome(),
      assembly_name => $slice->coord_system()->version(),
    });
  }
}

__PACKAGE__->meta->make_immutable;

1;
