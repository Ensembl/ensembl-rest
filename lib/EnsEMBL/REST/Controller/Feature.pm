package EnsEMBL::REST::Controller::Feature;

use Moose;
use namespace::autoclean;
use Try::Tiny;
require EnsEMBL::REST;
EnsEMBL::REST->turn_on_jsonp(__PACKAGE__);

__PACKAGE__->config(
  map => {
    'text/gff3' => [qw/View GFF3/],
  }
);

=pod

/feature/region/human/X:1000000..2000000?feature=gene

feature = The type of feature to retrieve (gene/transcript/exon/variation/structural_variation/constrained/regulatory)
db_type = The DB type to use; important if someone is doing queries over a non-default DB (core/otherfeatures)
species_set = The compara species set name to look for constrained elements by (mammals)
logic_name = Logic name used for genes
so_term=sequence ontology term to limit variants to

application/json
text/gff3

=cut

BEGIN {extends 'Catalyst::Controller::REST'; }

sub species: Chained('/') PathPart('feature/region') CaptureArgs(1) {
  my ( $self, $c, $species) = @_;
  $c->stash(species => $species);
}

sub region_GET {}

sub region: Chained('species') PathPart('') Args(1) ActionClass('REST') {
  my ($self, $c, $region) = @_;
  $c->stash()->{region} = $region;
  my $features;
  try {
    my $slice = $c->model('Lookup')->find_slice($c, $region);
    $self->assert_slice_length($c, $slice);
    $features = $c->model('Feature')->fetch_features($c);
  }
  catch {
    $c->go('ReturnError', 'from_ensembl', [$_]);
  };
  $self->status_ok($c, entity => $features );
}

sub default_length {
  return 5e6;
}

sub length_config_key {
  return 'Feature';
}

with 'EnsEMBL::REST::Role::SliceLength';

__PACKAGE__->meta->make_immutable;

1;
