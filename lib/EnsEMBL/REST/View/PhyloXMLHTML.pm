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

package EnsEMBL::REST::View::PhyloXMLHTML;
use Moose;
use namespace::autoclean;

extends 'EnsEMBL::REST::View::TextHTML';
 
sub get_content {
  my ($self, $c, $stash_key) = @_;
  return $self->encode_phyloxml($c, $stash_key);
}

with 'EnsEMBL::REST::Role::Tree';

__PACKAGE__->meta->make_immutable;

1;
