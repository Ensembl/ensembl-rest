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

package EnsEMBL::REST::Model::Regulatory;

use Moose;
use Catalyst::Exception qw(throw);
extends 'Catalyst::Model';

with 'Catalyst::Component::InstancePerContext';

has 'context' => (is => 'ro');

sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  return $self->new({ context => $c, %$self, @args });
}

sub fetch_regulatory {
  my $self    = shift
  my $regf_id = shift;

  my $c = $self->context();
  my $species = $c->stash->{species};

  Catalyst::Exception->throw("No regulatory feature stable ID given. Please specify an stable ID to retrieve from this service") if ! $regf_id;

  my $rfa  = $c->model('Registry')->get_adaptor($species, 'Regulation', 'RegulatoryFeature');
  my $regf = $rfa->fetch_by_stable_id($regf_id);
  
  if (! $regf) {
    Catalyst::Exception->throw("$regf_id not found for $species");
  }

  return $regf->summary_as_hash;
}


#If required look at Variation::to_hash for example of enriched hash
#and additional data types that can be embedded



with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;
