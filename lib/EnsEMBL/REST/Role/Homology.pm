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

package EnsEMBL::REST::Role::Homology;
use Moose::Role;
use namespace::autoclean;
use Bio::EnsEMBL::ApiVersion;
use Bio::EnsEMBL::Compara::Graph::OrthoXMLWriter;
use Bio::EnsEMBL::Utils::Scalar qw/check_ref/;
use IO::String;

sub encode_orthoxml {
  my ($self, $c, $stash_key) = @_;

  $stash_key ||= 'rest';
  my $string_handle = IO::String->new();

  my $w = Bio::EnsEMBL::Compara::Graph::OrthoXMLWriter->new(
    -SOURCE => 'Ensembl', -SOURCE_VERSION => Bio::EnsEMBL::ApiVersion::software_version(), -HANDLE => $string_handle
  );

  my $homologies = $c->stash->{$stash_key};

  $w->write_homologies($homologies);
  $w->finish();

  return $string_handle->string_ref();
}


with 'EnsEMBL::REST::Role::Content';

1;
