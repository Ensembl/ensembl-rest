=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::REST::Controller::Overlap;

use Moose;
use namespace::autoclean;
use Try::Tiny;
use Bio::EnsEMBL::Utils::Scalar qw/check_ref/;
require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

__PACKAGE__->config(
  map => {
    'text/x-gff3' => [qw/View GFF3/],
    'text/x-bed' => [qw/View BED/],
  }
);

=pod

/overlap/region/human/X:1000000..2000000?feature=gene

feature = The type of feature to retrieve (gene/transcript/exon/variation/structural_variation/constrained/regulatory)
db_type = The DB type to use; important if someone is doing queries over a non-default DB (core/otherfeatures)
species_set = The compara species set name to look for constrained elements by (mammals)
logic_name = Logic name used for genes
so_term=sequence ontology term to limit variants to

application/json
text/x-gff3

=cut

BEGIN {extends 'Catalyst::Controller::REST'; }

has 'max_slice_length' => ( isa => 'Num', is => 'ro', default => 1e7);

sub species: Chained('/') PathPart('overlap/region') CaptureArgs(1) {
  my ( $self, $c, $species) = @_;
  $c->stash(species => $species);
}

sub region_GET {}

sub region: Chained('species') PathPart('') Args(1) ActionClass('REST') {
  my ($self, $c, $region) = @_;
  $c->stash()->{region} = $region;
  my $features;
  try {
    my $slice = $c->model('Lookup')->find_slice($region);
    $self->assert_slice_length($c, $slice);
    $features = $c->model('Overlap')->fetch_features();
  }
  catch {
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  $self->status_ok($c, entity => $features );
}

=pod

/overlap/id/ENSG00000157764

feature = The type of feature to retrieve (gene/transcript/exon/variation/structural_variation/constrained/regulatory)
db_type = The DB type to use; important if someone is doing queries over a non-default DB (core/otherfeatures)
species_set = The compara species set name to look for constrained elements by (mammals)
logic_name = Logic name used for genes
so_term=sequence ontology term to limit variants to

application/json
text/x-gff3

=cut

sub id_GET {}

sub id: Chained('/') PathPart('overlap/id') Args(1) ActionClass('REST') {
  my ($self, $c, $id) = @_;
  my $features;
  try {
    $c->log()->debug('Finding the object');
    my $feature = $c->model('Lookup')->find_object_by_stable_id($id);
    $c->go('ReturnError', 'custom', "The given stable ID does not point to a Feature. Cannot perform overlap") unless check_ref($feature, 'Bio::EnsEMBL::Feature');
    
    my $feature_slice = $feature->feature_Slice();
    my $coord_system = $feature_slice->coord_system();
    my $strand = 1;
    #Fetch the slice again so we are back on the +ve strand
    my $slice = $feature_slice->adaptor()->fetch_by_region(
      $coord_system->name(), 
      $feature_slice->seq_region_name(), $feature_slice->start(), $feature_slice->end(), $strand, 
      $coord_system->version()
    );
    # my $slice = $feature_slice;
    $c->stash->{slice} = $slice;

    $features = $c->model('Overlap')->fetch_features($slice);
  } catch {
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  $self->status_ok($c, entity => $features );
}

=pod

/overlap/translation/ENSP00000288602?type=Superfamily

feature = The type of feature to retrieve (default is protein_feature, but can also retrieve transcript_variation)
db_type = The DB type to use; important if someone is doing queries over a non-default DB (core/otherfeatures)
species_set = The compara species set name to look for constrained elements by (mammals)
so_term = sequence ontology term to limit variants to
somatic = Where to include somatic data or not

application/json
text/x-gff3

=cut

sub translation_GET {}

sub translation: Chained('/') PathPart('overlap/translation') Args(1) ActionClass('REST') {
  my ($self, $c, $id) = @_;
  my $features;
  try {
    $c->log()->debug('Finding the object');
    $c->request->param('object_type', 'translation');
    my $translation = $c->model('Lookup')->find_object_by_stable_id($id);
    $features = $c->model('Overlap')->fetch_protein_features($translation);
  } catch {
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  $self->status_ok($c, entity => $features );
}

with 'EnsEMBL::REST::Role::SliceLength';

__PACKAGE__->meta->make_immutable;

1;
