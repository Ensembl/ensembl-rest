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

package EnsEMBL::REST::Controller::ga4gh::variants;

use Moose;
use namespace::autoclean;
use Try::Tiny;
use Data::Dumper;
use Bio::EnsEMBL::Utils::Scalar qw/check_ref/;
require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

=pod

POST requests : /ga4gh/variants/search -d

{ "variantSetId": 1,
 "variantName": '' ,
 "callSetIds": [],
 "referenceName": 7,
 "start":  140419275,
 "end": 140429275,
 "pageToken":  null,
 "pageSize": 10
}

GET requests: /ga4gh/variants/rs578140373


=cut

BEGIN {extends 'Catalyst::Controller::REST'; }


sub searchVariants_POST {
  my ( $self, $c ) = @_;

  my $post_data = $c->req->data;

#  $c->log->debug(Dumper $post_data);

  ## required by spec, so check early
  $c->go( 'ReturnError', 'custom', [ ' Cannot find "referenceName" key in your request' ] )
    unless exists $post_data->{referenceName} ;

  $c->go( 'ReturnError', 'custom', [ ' Cannot find "start" key in your request'])
    unless exists $post_data->{start};

  $c->go( 'ReturnError', 'custom', [ ' Cannot find "end" key in your request'])
    unless exists $post_data->{end};

  $c->go( 'ReturnError','custom', [ '"start" must not equal "end". Check your coordinates are expressed in zero-based half-open format' ])
    if ($post_data->{start} == $post_data->{end});
  # This occurence causes big problems in the underlying Tabix use. Bug in the IO layer may be fixed, but the users still shouldn't
  # be treating this endpoint like other Ensembl endpoints.

  $c->go( 'ReturnError', 'custom', [ '  End of interval cannot be greater than start of interval'])
    unless $post_data->{end} >= $post_data->{start};


  $c->go( 'ReturnError', 'custom', [ ' Cannot find "variantSetId" key in your request'])
    unless exists $post_data->{variantSetId};


  ## set a default page size if not supplied or not a number
  $post_data->{pageSize} = 10 unless (defined  $post_data->{pageSize} && $post_data->{pageSize} =~ /\d+/ );


  ## set a maximum page size 
  $post_data->{pageSize} =  1000 if $post_data->{pageSize} > 1000; 

  my $gavariant;

  try {
    $gavariant = $c->model('ga4gh::variants')->fetch_gavariant($post_data);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [$_]);
  };

  $self->status_ok($c, entity => $gavariant);


}

sub searchVariants: Chained('/') PathPart('ga4gh/variants/search') ActionClass('REST') {}



sub id: Chained('/') PathPart('ga4gh/variants') ActionClass('REST') {}

sub id_GET {

  my ($self, $c, $id) = @_;

  $c->go( 'ReturnError', 'custom', [ ' Error - id required for GET request' ])
    unless defined $id;

  my $variant;
  try {
    $variant = $c->model('ga4gh::variants')->getVariant($id);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };

  ## Return 404 for get requests on unknown ids
  $c->go( 'ReturnError', 'not_found', [qq{ variant $id not found}]) unless defined $variant;

  $self->status_ok($c, entity => $variant);
}


__PACKAGE__->meta->make_immutable;

1;
