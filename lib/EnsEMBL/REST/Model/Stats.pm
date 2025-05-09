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

package EnsEMBL::REST::Model::Stats;

use Moose;
use Catalyst::Exception;
use Scalar::Util qw/weaken/;

extends 'Catalyst::Model';
with 'Catalyst::Component::InstancePerContext';

# Per instance variables
has 'context' => (is => 'ro', weak_ref => 1);

sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  weaken($c);
  return $self->new({ context => $c, %$self, @args });
}

sub species_stats {
    my ($self, $species) = @_;

    # Fetch the context, which allows us to fetch the Registry
    my $c = $self->context();
    my $registry = $c->model('Registry');

    # Create the GenomeContainer adaptor, return an error if we can't
    my $ga = $registry->get_adaptor($species, 'core', 'GenomeContainer');
    Catalyst::Exception->throw("No adaptor found for species $species") unless $ga;

    # Build the object to serialize
    my $genome = { assembly => $ga->get_assembly_name(),
		   accession => $ga->get_accession(),
		   coding_count => $ga->get_coding_count(),
		   ref_length => $ga->get_ref_length(),
		   transcript_count => $ga->get_transcript_count(),
		   
    };

    return $genome;
}

1;
