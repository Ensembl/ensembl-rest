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

package EnsEMBL::REST::Controller::ga4gh::references;

use Moose;
use namespace::autoclean;
use Try::Tiny;
use Data::Dumper;


require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

=pod

POST requests : /ga4gh/references/search -d { "referenceSetId": = "", 
                                              "md5checksums": [], 
                                              "accessions": [], 
                                              "pageSize": "", 
                                              "pageToken": "",
                                             }

GET /ga4gh/references/id
GET /ga4gh/references/{id}/bases?start=100&end=200

=cut

BEGIN {extends 'Catalyst::Controller::REST'; }



sub searchReferences_POST {
  my ( $self, $c ) = @_;

  my $references;

  my $post_data = $c->req->data;

  $c->go( 'ReturnError', 'custom', [ ' Cannot find "referenceSetId" key in your request' ] )
    unless exists $post_data->{referenceSetId} ;

   ## set a default page size if not supplied or not a number
   $post_data->{pageSize} = 50 unless (defined  $post_data->{pageSize} && $post_data->{pageSize} =~ /\d+/);


  try {
    $references = $c->model('ga4gh::references')->fetch_references( $post_data );
  } catch {
    $c->go('ReturnError', 'from_ensembl', [$_]);
  };

  $self->status_ok($c, entity => $references); 

}

sub searchReferences: Chained('/') PathPart('ga4gh/references/search') ActionClass('REST')  {}



sub id: Chained('/') PathPart('ga4gh/references') ActionClass('REST') {}

sub id_GET {
  my ($self, $c, $id, $bases) = @_;
  my $references;

  $c->go( 'ReturnError', 'custom', [ ' Error - id required for GET request' ])
    unless defined $id;

  try {
    $references = $c->model('ga4gh::references')->getReference($id, $bases);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };

  ## Return 404 for get requests on unknown ids
  $c->go( 'ReturnError', 'not_found', [qq{ reference $id not found}]) unless defined $references;

  $self->status_ok($c, entity => $references);
}



__PACKAGE__->meta->make_immutable;

1;
