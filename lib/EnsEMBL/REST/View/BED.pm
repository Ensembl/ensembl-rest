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

package EnsEMBL::REST::View::BED;
use Moose;
use namespace::autoclean;
use Bio::EnsEMBL::Utils::IO::BEDSerializer;
use IO::String;

extends 'Catalyst::View';

sub build_bed_serializer {
  my ($self, $c, $output_fh) = @_;
  my $serializer = Bio::EnsEMBL::Utils::IO::BEDSerializer->new($output_fh);
  return $serializer;
}

sub process {
  my ($self, $c, $stash_key) = @_;
  $stash_key ||= 'rest';
  my $output_fh = IO::String->new();
  my $ucsc_name_cache = {};
  my $features = $c->stash()->{$stash_key};
  my $bed = $self->build_bed_serializer($c, $output_fh);
  while (my $feature = shift @{$features}) {
    $bed->print_feature($feature, $ucsc_name_cache);
  }
  $c->res->body(${$output_fh->string_ref()});
  $c->res->headers->header('Content-Type' => 'text/x-bed');
  return 1;
}

with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;
