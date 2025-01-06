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

package EnsEMBL::REST::Controller::ga4gh::Beacon;

use strict;
use Moose;
use namespace::autoclean;
use Try::Tiny;
# use Data::Dumper;
use JSON;
use Bio::EnsEMBL::Utils::Scalar qw/check_ref/;
require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

=pod

GET requests: /ga4gh/beacon

GET requests: /ga4gh/beacon/query

POST requests : /ga4gh/beacon/query -d

{ "referenceName": "15", 
  "start" : 20538669, 
  "referenceBases": "A", 
  "alternateBases": "G",
  "assemblyId" : "GRCh38" }
}

=cut

BEGIN {extends 'Catalyst::Controller::REST'; }
with 'EnsEMBL::REST::Role::PostLimiter';

# /ga4gh/beacon/

sub beacon_info: Path('') ActionClass('REST') {}

sub beacon_info_GET {
  my ($self, $c) = @_;
  my $beacon;
  
  try {
    $beacon = $c->model('ga4gh::Beacon')->get_beacon();
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  $self->status_ok($c, entity => $beacon);
  return;
}

# /ga4gh/beacon/query
# sub beacon_query: Path('query') ActionClass('REST') {}
# Note parameter checking not done in beacon_query as
# $c->request->parameters returns empty for POST 
# The key values pairs for POST obtained from $c->request->data
sub beacon_query: Path('query') ActionClass('REST')  {} 

sub beacon_query_GET {
  my ($self, $c) = @_;

  my $beacon_allele_response;
  
  try {
    $beacon_allele_response = $c->model('ga4gh::Beacon')->beacon_query($c->request->parameters);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  $self->status_ok($c, entity => $beacon_allele_response);
}

sub beacon_query_POST {
  my ($self, $c) = @_;
  
  my $beacon_allele_response;

  try {
    $beacon_allele_response = $c->model('ga4gh::Beacon')->beacon_query($c->request->data);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  $self->status_ok($c, entity => $beacon_allele_response);
}

__PACKAGE__->meta->make_immutable;

1;
