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

package EnsEMBL::REST::Controller::ga4gh::variantSet;

use Moose;
use namespace::autoclean;
use Try::Tiny;
use Data::Dumper;

require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

=pod

POST requests : /variantsets/search -d

{ "dataSetIds": [1],
  "pageToken":  null,
  "pageSize": 10
}

GET requests : /variantsets/:id

application/json

=cut

BEGIN {extends 'Catalyst::Controller::REST'; }


sub searchVariantSets_POST {
  my ( $self, $c ) = @_;
}


sub searchVariantSets: Chained('/') PathPart('ga4gh/variantsets/search') ActionClass('REST')  {

  my ( $self, $c ) = @_;
  my $post_data = $c->req->data;

  #$c->log->debug(Dumper $post_data);

  $c->go( 'ReturnError', 'custom', [ ' Cannot find "datasetId" key in your request'])
    unless exists $post_data->{datasetId};

  ## set a default page size if not supplied or not a number
  $post_data->{pageSize} = 10 unless (defined  $post_data->{pageSize} &&  
                                      $post_data->{pageSize} =~ /\d+/);


  my $variantSets;

  try {
    $variantSets = $c->model('ga4gh::variantSet')->fetch_variantSets($post_data);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [$_]);
  };

  $self->status_ok($c, entity => $variantSets);
}



sub id: Chained('/') PathPart('ga4gh/variantsets') ActionClass('REST') {}

sub id_GET {

  my ($self, $c, $id) = @_;

  $c->go( 'ReturnError', 'custom', [ ' Error - id required for GET request' ])
    unless defined $id;

  my $variantSet;
  try {
    $variantSet = $c->model('ga4gh::variantSet')->getVariantSet($id);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };

  ## Return 404 for get requests on unknown ids
  $c->go( 'ReturnError', 'not_found', [qq{ variantSet $id not found}]) unless defined $variantSet;
 
  $self->status_ok($c, entity => $variantSet);
}



__PACKAGE__->meta->make_immutable;

1;
