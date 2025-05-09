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

package EnsEMBL::REST::Model::Regulatory;

use Moose;
use Catalyst::Exception qw(throw);
use Try::Tiny;
use Bio::EnsEMBL::Utils::Scalar qw/wrap_array/;
use Bio::EnsEMBL::Funcgen::BindingMatrix::Converter;
use Bio::EnsEMBL::Funcgen::BindingMatrix::Constants qw ( :all );
use Scalar::Util qw/weaken/;
extends 'Catalyst::Model';

with 'Catalyst::Component::InstancePerContext';

has 'context' => (is => 'ro', weak_ref => 1);

sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  weaken($c);
  return $self->new({ context => $c, %$self, @args });
}

sub get_binding_matrix {
    my ( $self, $binding_matrix_stable_id ) = @_;

    my $c       = $self->context();
    my $species = $c->stash->{species};
    my $binding_matrix_adaptor =
      $c->model('Registry')
      ->get_adaptor( $species, 'Funcgen', 'BindingMatrix' );
    my $binding_matrix =
      $binding_matrix_adaptor->fetch_by_stable_id($binding_matrix_stable_id);

    if ( !defined $binding_matrix ) {
        Catalyst::Exception->throw( 'Binding Matrix '
              . $binding_matrix_stable_id
              . ' not found. Please check spelling.' );
    }

    if ( defined $c->request->param('unit') ) {
        my $unit = $c->request->param('unit');
        $unit = ucfirst(lc($unit));
        my $valid_units = VALID_UNITS;
        if ( !grep $_ eq $unit, @{$valid_units} ) {
            Catalyst::Exception->throw( $unit
                  . ' is not a valid BindingMatrix unit. List of valid units: '
                  . join( ",", @{$valid_units} ) );
        }

        try {
            my $converter =
                Bio::EnsEMBL::Funcgen::BindingMatrix::Converter->new();

            if ($unit eq PROBABILITIES) {
                $binding_matrix =
                    $converter
                        ->from_frequencies_to_probabilities($binding_matrix);
            }

            if ($unit eq BITS) {
                $binding_matrix =
                    $converter->from_frequencies_to_bits($binding_matrix);
            }

            if ($unit eq WEIGHTS) {
                $binding_matrix =
                    $converter->from_frequencies_to_weights($binding_matrix);
            }
        }
        catch {
            Catalyst::Exception->throw(
                'Not possible to get the binding matrix with '
                    . $unit
                    . '. Please try a different unit');
        };
    }

    return $binding_matrix->summary_as_hash();
}

with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;
