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

package EnsEMBL::REST::View::JSONHTML;

use Moose;
use namespace::autoclean;

extends 'EnsEMBL::REST::View::TextHTML';

sub get_content {
  my ($self, $c, $key) = @_;
  my $rest = $c->stash()->{$key};
  my $encode = $self->json()->encode($rest);
  return $encode;
}

with 'EnsEMBL::REST::Role::JSON';

__PACKAGE__->meta->make_immutable;

1;
