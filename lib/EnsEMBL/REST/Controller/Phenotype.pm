=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
Copyright [2016-2018] EMBL-European Bioinformatics Institute

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

package EnsEMBL::REST::Controller::Phenotype;

use Moose;
use namespace::autoclean;
use Try::Tiny;
use Bio::EnsEMBL::Utils::Scalar qw/check_ref/;
require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);
=pod

/phenotype/accession/homo_sapiens/EFO_0003900
/phenotype/term/homo_sapiens/ciliopathy

application/json

=cut

BEGIN {extends 'Catalyst::Controller::REST'; }
with 'EnsEMBL::REST::Role::PostLimiter';


#/phenotype/accession/homo_sapiens/EFO_0003900

sub accession_GET {}

sub accession: Chained('/') PathPart('phenotype/accession') Args(2) ActionClass('REST') {

  my ($self, $c, $species, $accession) = @_;

  my $phenotype_features;

  try {
    $phenotype_features = $c->model('Phenotype')->fetch_by_accession($species, $accession);
  }
  catch {
    $c->log->debug('Problems:'.$_)
  };

  $self->status_ok($c, entity => $phenotype_features );
}


#/phenotype/term/homo_sapiens/ciliopathy

sub term_GET {}

sub term: Chained('/') PathPart('phenotype/term') Args(2) ActionClass('REST') {

  my ($self, $c, $species, $term) = @_;

  my $phenotype_features;

  try {
    $phenotype_features = $c->model('Phenotype')->fetch_by_term($species, $term);
  }
  catch {
    $c->log->debug('Problems:'.$_)
  };

  $self->status_ok($c, entity => $phenotype_features );
}



=pod

/phenotype/region/Homo_sapiens/X:1000000-2000000?feature_type=Variation;

feature_type = The type of feature associated with phenotype to retrieve (Variation/StructuralVariation/Gene/QTL).
only_phenotypes = Only returns associated phenotype description and mapped ontology accessions for a lighter output.

application/json
text/x-gff3

=cut

has 'max_slice_length' => ( isa => 'Num', is => 'ro', default => 1e7);

sub region_GET {}

sub region: Chained('/') PathPart('phenotype/region') Args(2) ActionClass('REST') {
  my ($self, $c, $species, $region) = @_;

   $c->stash()->{species} = $species; # Needed to be populated for the 'Lookup' service

  my $features;

  try {
    my ($sr_name) = $c->model('Lookup')->decode_region( $region, 1, 1 );
    my $slice = $c->model('Lookup')->find_slice($region);
    $self->assert_slice_length($c, $slice);
    $features = $c->model('Phenotype')->fetch_features_by_region($species, $slice);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  $self->status_ok($c, entity => $features );
}

with 'EnsEMBL::REST::Role::SliceLength';


__PACKAGE__->meta->make_immutable;

1;
