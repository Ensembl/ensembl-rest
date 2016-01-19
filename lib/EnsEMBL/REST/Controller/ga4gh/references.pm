=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

GET requests: /ga4gh/references/id

=cut

BEGIN {extends 'Catalyst::Controller::REST'; }



sub searchReferences_POST {
  my ( $self, $c ) = @_;
 
  my $references;

  $c->go( 'ReturnError', 'custom', [ ' Cannot find "referenceSetId" key in your request' ] )
    unless exists $c->req->data->{referenceSetId} ;

  try {
    $references = $c->model('ga4gh::references')->fetch_references( $c->req->data );
  } catch {
    $c->go('ReturnError', 'from_ensembl', [$_]);
  };

  $self->status_ok($c, entity => $references); 

}

sub searchReferences: Chained('/') PathPart('ga4gh/references/search') ActionClass('REST')  {}



sub id: Chained('/') PathPart('ga4gh/references') ActionClass('REST') {}

sub id_GET {
  my ($self, $c, $id) = @_;
  my $references;

  $c->go( 'ReturnError', 'custom', [ ' Error - id required for GET request' ])
    unless defined $id;

  try {
    $references = $c->model('ga4gh::references')->getReference($id);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  $self->status_ok($c, entity => $references);
}



__PACKAGE__->meta->make_immutable;

1;
