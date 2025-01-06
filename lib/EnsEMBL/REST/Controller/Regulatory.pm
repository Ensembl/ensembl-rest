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

package EnsEMBL::REST::Controller::Regulatory;

use Moose;
use namespace::autoclean;
use Try::Tiny;
use Bio::EnsEMBL::Utils::Scalar qw/check_ref/;
require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

=pod

/regulatory/species/ENSR00001348195

application/json

=cut

BEGIN {extends 'Catalyst::Controller::REST'; }

#protect against missing variables

sub species: Chained('/') PathPart('species') CaptureArgs(1) {
  my ( $self, $c, $species) = @_;

  unless (defined $species) { $c->go('ReturnError','custom',[qq{Species must be provided as part of the URL.}])} 
  $c->stash(species => $species);
}

# /species/:species/binding_matrix/:binding_matrix_stable_id/
sub binding_matrix : Chained('species') PathPart('binding_matrix') Args(1)
  ActionClass('REST') {
    my ( $self, $c, $binding_matrix_stable_id ) = @_;

    unless ( defined $binding_matrix_stable_id ) {
        $c->go( 'ReturnError', 'custom',
            [qq{Binding Matrix stable id must be provided as part of the URL.}]
        );
    }
}

sub binding_matrix_GET {
    my ( $self, $c, $binding_matrix_stable_id ) = @_;

    my $binding_matrix;
    try {
        $binding_matrix =
          $c->model('Regulatory')
          ->get_binding_matrix($binding_matrix_stable_id);
    }
    catch {
        $c->go( 'ReturnError', 'from_ensembl', [qq{$_}] ) if $_ =~ /STACK/;
        $c->go( 'ReturnError', 'custom', [qq{$_}] );
    };
    $self->status_ok( $c, entity => $binding_matrix );
}

__PACKAGE__->meta->make_immutable;

1;
