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
  my $regf_id = shift ||
   Catalyst::Exception->throw("No regulatory feature stable ID given. Please specify an stable ID to retrieve from this service");

  my $c          = $self->context;
  my $ctype_name = $c->request->parameters->{cell_type};
  my $species    = $c->stash->{species};
  my $dba        = $c->model('Registry')->get_adaptor($species, 'funcgen') ||
    $c->go('ReturnError', 'custom', ["No funcgen DBAdaptor found for species $species"]);

  my ($fset);

  if(defined $ctype_name){
    $fset = $dba->get_FeatureSetAdaptor->fetch_by_name('RegulatoryFeatures:'.$ctype_name) ||  
     $c->go('ReturnError', 'custom', ["No $species regulatory FeatureSet available with name:\tRegulatoryFeatures:$ctype_name"]);
  }

  my $regf = $dba->get_RegulatoryFeatureAdaptor->fetch_by_stable_id($regf_id, $fset);
  
  if (! $regf) {
    $ctype_name = '('.$ctype_name.')' if defined $ctype_name;
    Catalyst::Exception->throw("$regf_id${ctype_name} not found for $species");
  }

  #Add support to include_attributes here by embedding hash summaries

  return $regf->summary_as_hash;
}


#If required look at Variation::to_hash for example of enriched hash
#and additional data types that can be embedded



with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;
