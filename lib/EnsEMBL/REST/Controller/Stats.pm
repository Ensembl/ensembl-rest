=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
Copyright [2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::REST::Controller::Stats;
use Moose;

BEGIN {extends 'Catalyst::Controller::REST'; }

with 'EnsEMBL::REST::Role::Active';

require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

sub species : Path('species') : ActionClass('REST') :Args(1) {}

sub species_GET {
    my ($self, $c, $species) = @_;

    # Check if the controller is active, return an error if we're turned off
    if(! $self->controller_active()) {
	$c->go('ReturnError', 'custom', [qq{This endpoint is not currently active}] );
    }

    # Go to the model for stats and ask for this specie's data
    my $genome = $c->model('Stats')->species_stats($species);

    # Send back the stats we've received
    $self->status_ok( $c, entity => $genome );
}

1;
