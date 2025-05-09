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

package EnsEMBL::REST::Controller::ga4gh::features;

use Moose;
use namespace::autoclean;
use Try::Tiny;
use Data::Dumper;
require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

=pod

POST requests : /ga4gh/features/search -d

{ "featureSetId": "",
 "parentId": "",
 "start": "" ,
 "end": "",
 "referenceName": "", 
 "featureTypes:" [],
 "pageToken":  null,
 "pageSize": 10
}

GET requests: /ga4gh/features/id

 

=cut

BEGIN {extends 'Catalyst::Controller::REST'; }


sub searchFeatures_POST {
  my ( $self, $c ) = @_;

  my $post_data = $c->req->data;

  ## required by spec, so check early
  $c->go( 'ReturnError', 'custom', [ ' Cannot find "parentId" or "featureSetId" key in your request' ] )
    unless ((exists $post_data->{parentId}  && $post_data->{parentId} =~/\w+/) || 
            (exists $post_data->{featureSetId} && $post_data->{featureSetId} =~/\w+/)) ;

  $c->go( 'ReturnError', 'custom', [ ' Cannot find "referenceName" key in your request' ] )
    unless ( exists $post_data->{referenceName} && $post_data->{referenceName} =~/\w+/);

  $c->go( 'ReturnError', 'custom', [ ' Cannot find "start" key in your request' ] )
    unless ( exists $post_data->{start} && $post_data->{start} =~/\d+/);

  $c->go( 'ReturnError', 'custom', [ ' Cannot find "end" key in your request' ] )
    unless (exists $post_data->{end} && $post_data->{end} =~/\d+/); 

  $c->go( 'ReturnError', 'custom', [ ' End must be greater than start' ] )
    if (  $post_data->{end} < $post_data->{start});


  ## set a default page size if not supplied or not a number
  $post_data->{pageSize} = 200 unless (defined  $post_data->{pageSize} && $post_data->{pageSize} =~ /\d+/ );

  ## set a maximum page size 
  $post_data->{pageSize} =  200 if $post_data->{pageSize} > 1000; 

  my $features;

  try {
    $features = $c->model('ga4gh::features')->searchFeatures($post_data);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [$_]);
  };

  $self->status_ok($c, entity => $features);

}

sub searchFeatures: Chained('/') PathPart('ga4gh/features/search') ActionClass('REST') {}



sub id: Chained('/') PathPart('ga4gh/features') ActionClass('REST') {}

sub id_GET {
  my ($self, $c, $id) = @_;
  my $feature;

  try {
    $feature = $c->model('ga4gh::features')->getFeature($id);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  $self->status_ok($c, entity => $feature);
}




__PACKAGE__->meta->make_immutable;

1;
