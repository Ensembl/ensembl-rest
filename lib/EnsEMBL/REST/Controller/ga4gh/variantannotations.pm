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

package EnsEMBL::REST::Controller::ga4gh::variantannotations;

use Moose;
use namespace::autoclean;
use Try::Tiny;
use Data::Dumper;
use Bio::EnsEMBL::Utils::Scalar qw/check_ref/;
require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

=pod

POST requests : /ga4gh/variantannotations/search -d

{ "annotationSetId": "Ensembl",
 "variantName": '' ,
 "referenceName": 7,
 "start":  140419275,
 "end": 140429275,
 "effects"  : [ {"source":"SO","name":"missense_variant","id":"SO:0001583"}]         
 "pageToken":  null,
 "pageSize": 10
}


=cut

BEGIN {extends 'Catalyst::Controller::REST'; }


sub searchVariantAnnotations_POST {
  my ( $self, $c ) = @_;

  my $post_data = $c->req->data;

#  $c->log->debug(Dumper $post_data);

  ## required by spec, so check early
  $c->go( 'ReturnError', 'custom', [ ' Cannot find "referenceName", "referenceId"  key in your request' ] )
    unless (exists $post_data->{referenceName} || exists $post_data->{referenceId});

  $c->go( 'ReturnError', 'custom', [ ' Cannot find "start" or "end" your request'])
    unless (exists $post_data->{start} && exists $post_data->{end});

  $c->go( 'ReturnError', 'custom', [ '  End of interval cannot be greater than start of interval'])
    if defined $post_data->{end} && 
       defined $post_data->{start} &&
       $post_data->{start} >= $post_data->{end};


  $c->go( 'ReturnError', 'custom', [ ' Cannot find "variantAnnotationSetId" key in your request'])
    unless exists $post_data->{variantAnnotationSetId};


  ## set a default page size if not supplied or not a number
  $post_data->{pageSize} = 50 unless (defined  $post_data->{pageSize} && $post_data->{pageSize} =~ /\d+/ );

  ## set a maximum page size 
  $post_data->{pageSize} =  1000 if $post_data->{pageSize} > 1000; 

  my $variant_annotation;

  try {
    $variant_annotation = $c->model('ga4gh::variantannotations')->searchVariantAnnotations($post_data);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [$_]);
  };

  $self->status_ok($c, entity => $variant_annotation);


}

sub searchVariantAnnotations: Chained('/') PathPart('ga4gh/variantannotations/search') ActionClass('REST') {}




__PACKAGE__->meta->make_immutable;

1;
