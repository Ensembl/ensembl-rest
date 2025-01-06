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

package EnsEMBL::REST::Controller::ga4gh::featureSets;

use Moose;
use namespace::autoclean;
use Try::Tiny;
use Data::Dumper;

## Needs tark

require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

=pod

POST requests : /ga4gh/featuresets/search -d { "datasetId": "Ensembl"}

GET requests: /ga4gh/featuresets/ensembl79

=cut

BEGIN {extends 'Catalyst::Controller::REST'; }



sub searchFeatureSets_POST {

  my ($self, $c) = @_;

  my $post_data = $c->req->data;

  ## A variantSet id is required
  $c->go( 'ReturnError', 'custom', [ ' Cannot find a "datasetId" key in your request' ] )
    unless exists $post_data->{datasetId}; 

 
  my $featureSet;

  try {
    $featureSet = $c->model('ga4gh::featureSets')->searchFeatureSets( $post_data );
  } catch {
    $c->go('ReturnError', 'from_ensembl', [$_]);
  };

  $self->status_ok($c, entity => $featureSet); 

}

sub searchFeatureSets: Chained('/') PathPart('ga4gh/featuresets/search') ActionClass('REST')  {}


## get method
## not too useful without access to archive
sub id: Chained('/') PathPart('ga4gh/featuresets') ActionClass('REST') {}

sub id_GET {

  my ($self, $c, $id) = @_;
  my $featureSet;
  try {
    $featureSet = $c->model('ga4gh::featuresets')->getFeatureSet($id);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  $self->status_ok($c, entity => $featureSet);
}



__PACKAGE__->meta->make_immutable;

1;
