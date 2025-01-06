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

package EnsEMBL::REST::Controller::ga4gh::callSet;

use Moose;
use namespace::autoclean;
use Try::Tiny;
use Data::Dumper;

require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

=pod

POST requests : ga4gh/callsets/search

{ "variantSetIds": [1],
 "name": '' ,
 "pageToken":  null,
 "pageSize": 10
}

GET: ga4gh/callsets/:id

=cut

BEGIN {extends 'Catalyst::Controller::REST'; }


sub searchCallSets_POST {
  my ( $self, $c ) = @_;

}

sub searchCallSets: Chained('/') PathPart('ga4gh/callsets/search') ActionClass('REST')  {

  my ( $self, $c ) = @_;
  my $post_data = $c->req->data;

#  $c->log->debug(Dumper $post_data);

  $c->go( 'ReturnError', 'custom', [ ' Cannot find "variantSetId" key in your request'])
    unless exists $post_data->{variantSetId};

  my $callSet;

  ## set a default page size if not supplied or not a number
  $post_data->{pageSize} = 10 unless (defined  $post_data->{pageSize} &&  $post_data->{pageSize} =~ /\d+/ );


  try {
    $callSet = $c->model('ga4gh::callSet')->fetch_callSets($post_data);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [$_]);
  };

  ## Return 404 for post requests on unknown VariantSet ids
  $c->go( 'ReturnError', 'not_found', [qq( VariantSet $post_data->{variantSetId} not found )]) unless defined $callSet;

  $self->status_ok($c, entity => $callSet);
}


sub id: Chained('/') PathPart('ga4gh/callsets') ActionClass('REST') {}

sub id_GET {

  my ($self, $c, $id) = @_;

  $c->go( 'ReturnError', 'custom', [ ' Error - id required for GET request' ])
    unless defined $id;

  my $callSet;

  try {
    $callSet = $c->model('ga4gh::callSet')->get_callSet($id);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };

  ## Return 404 for get requests on unknown ids
  $c->go( 'ReturnError', 'not_found', [qq{ callSet $id not found}]) unless defined $callSet;

  $self->status_ok($c, entity => $callSet);
}

__PACKAGE__->meta->make_immutable;

1;
