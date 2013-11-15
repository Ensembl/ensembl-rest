package EnsEMBL::REST::Controller::Archive;

use Moose;
use namespace::autoclean;
use Try::Tiny;
use Bio::EnsEMBL::Utils::Scalar qw/check_ref/;
require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

__PACKAGE__->config(
  map => {
    'text/x-gff3' => [qw/View GFF3/],
  }
);

=pod

/archive/id:ENSG00000000001

application/json
text/x-gff3

=cut

BEGIN {extends 'Catalyst::Controller::REST'; }

sub id_GET {}


sub id: Chained('/') PathPart('archive/id') Args(1) ActionClass('REST') {
  my ($self, $c, $id) = @_;
  my $archive;
  $c->request->param('use_archive', 1);
  my ($stable_id, $version) = split(/\./, $id);
  try {
    my @results = $c->model('Lookup')->find_object_location($stable_id, undef, 1);
    if (!@results) {
      $c->go('ReturnError', 'custom', ["$id not found in lookup"]);
    }
    my $species = $results[0];
    my $aia = $c->model('Registry')->get_adaptor($species,'Core','ArchiveStableID');
    if ($version) {
      $archive = $aia->fetch_by_stable_id_version($stable_id, $version);
    } else {
      $archive = $aia->fetch_by_stable_id($stable_id);
    }
    if (!$archive) {
      $c->go('ReturnError', 'custom', ["No archive found for $id"]);
    }
    $c->stash(entries => $archive);
    $c->forward('_encode');
  }
  catch {
      $c->go( 'ReturnError', 'from_ensembl', [$_] );
  };
  $self->status_ok($c, entity => $c->stash->{entity});
}

sub _encode :Private{
  my ($self, $c) = @_;
  my ($enc, $peptide, @replacements);
  my $archive = $c->stash()->{entries};
  my $aia = $c->model('Registry')->get_adaptor($c->stash()->{species},'Core','ArchiveStableID');
  $peptide = $archive->get_peptide if (!$archive->is_current);

  if (!$archive->is_current) {
    foreach my $successor (@{ $archive->get_all_successors }) {
      my $event = $archive->get_event($successor->stable_id);
      my $score = $event->score;
      push(@replacements, { stable_id => $successor->stable_id, score => $score });
    }
  }

  $enc = {
      ID => $archive->stable_id,
      version => $archive->version,
      release => $archive->release,
      is_current => $archive->is_current,
      assembly => $archive->assembly,
      type => $archive->type,
      possible_replacement => \@replacements,
      latest => $archive->get_latest_incarnation->stable_id .".". $archive->get_latest_incarnation->version,
      peptide => $peptide,
  };
  $c->stash(entity => $enc);
}

__PACKAGE__->meta->make_immutable;

1;
