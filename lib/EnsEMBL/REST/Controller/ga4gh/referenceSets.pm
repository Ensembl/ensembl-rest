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

package EnsEMBL::REST::Controller::ga4gh::referenceSets;

use Moose;
use namespace::autoclean;
use Try::Tiny;
use Data::Dumper;


require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

=pod

POST requests : /ga4gh/referencesets/search -d {}

GET requests: /ga4gh/referencesets/id

=cut

BEGIN {extends 'Catalyst::Controller::REST'; }



sub searchReferenceSets_POST {

  my ( $self, $c ) = @_;

  my $referenceSets;
  my $post_data = $c->req->data ;

  ## set a default page size if not supplied or not a number
  $post_data->{pageSize} = 10 unless (defined  $post_data->{pageSize} && $post_data->{pageSize} =~ /\d+/);

  try {
    $referenceSets = $c->model('ga4gh::referenceSets')->searchReferenceSet( $post_data );
  } catch {
    $c->go('ReturnError', 'from_ensembl', [$_]);
  };

  $self->status_ok($c, entity => $referenceSets); 

}

sub searchReferenceSets: Chained('/') PathPart('ga4gh/referencesets/search') ActionClass('REST')  {}


## get method
## not too useful while each server is tied to a specific assembly
sub id: Chained('/') PathPart('ga4gh/referencesets') ActionClass('REST') {}

sub id_GET {

  my ($self, $c, $id) = @_;
  my $referenceSet;

  $c->go( 'ReturnError', 'custom', [ ' Error - id required for GET request' ])
    unless defined $id;

  try {
    $referenceSet = $c->model('ga4gh::referencesets')->getReferenceSet($id);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };

  ## Return 404 for get requests on unknown ids
  $c->go( 'ReturnError', 'not_found', [qq{ referenceSet $id not found}]) unless defined $referenceSet;

  $self->status_ok($c, entity => $referenceSet);
}



__PACKAGE__->meta->make_immutable;

1;
