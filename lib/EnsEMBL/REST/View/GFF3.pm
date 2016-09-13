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

package EnsEMBL::REST::View::GFF3;
use Moose;
use namespace::autoclean;
use Bio::EnsEMBL::Utils::IO::GFFSerializer;
use IO::String;

extends 'Catalyst::View';

has 'default_source' => ( isa => 'Str', is => 'ro', default => '.' );

sub build_gff_serializer {
  my ($self, $c, $output_fh) = @_;
  my $ontology_adaptor = $c->model('Registry')->get_ontology_term_adaptor();  
  my $serializer = Bio::EnsEMBL::Utils::IO::GFFSerializer->new($ontology_adaptor, $output_fh, $self->default_source());
  return $serializer;
} 

sub process {
  my ($self, $c, $stash_key) = @_;
  $stash_key ||= 'rest';
  my $output_fh = IO::String->new();
  my $gff = $self->build_gff_serializer($c, $output_fh);
  my $features = $c->stash()->{$stash_key};
  my $slice = $c->stash()->{slice};
  $gff->print_main_header([$slice]);
  while(my $f = shift @{$features}) {
    $gff->print_feature($f);
  }
  $c->res->body(${$output_fh->string_ref()});
  $c->res->headers->header('Content-Type' => 'text/x-gff3');
  return 1;
}

with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;
