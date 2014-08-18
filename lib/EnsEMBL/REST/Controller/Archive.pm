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

package EnsEMBL::REST::Controller::Archive;

use Moose;
use namespace::autoclean;
use Try::Tiny;
use Bio::EnsEMBL::Utils::Scalar qw/check_ref/;
use Data::Dumper;
require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

=pod

/archive/id:ENSG00000000001

application/json
text/x-gff3

=cut

BEGIN {extends 'Catalyst::Controller::REST'; }
with 'EnsEMBL::REST::Role::PostLimiter';

sub id: Chained('/') PathPart('archive/id') ActionClass('REST') {
  my ($self, $c, $id) = @_;
  $c->request->param('use_archive', 1);
}

sub id_GET {
  my ($self, $c, $id) = @_;
  my $archive;
  my $encoded;
  try {
    $archive = $self->_fetch_archive_by_id($c,$id);
    if (!$archive) {
      $c->go('ReturnError', 'custom', ["No archive found for $id"]);
    }
    $c->stash(entries => $archive);
    $encoded = $self->_encode($c,$archive);
    $c->log->debug(Dumper $encoded);
  }
  catch {
      $c->go( 'ReturnError', 'from_ensembl', [$_] );
  };
  $self->status_ok($c, entity => $encoded);
}

sub id_POST {
  my ($self, $c) = @_;
  
  my $payload = $c->req->data();
  my $ids = $payload->{id};
  $self->assert_message_size($c,$ids);
  try {
    foreach my $id (@$ids){
      my $archive = $self->_fetch_archive_by_id($c,$id);
      $c->stash(entries => $archive);
      my $enc = $self->_encode($c,$archive);

      # my $entity = $c->stash->{entity} if (defined($c->stash->{entity}));
      # push $entity,$enc;
      # $c->stash(entity => $entity);
      push @{$c->stash->{entity}},$enc;
    }

  }
  catch {
    $c->go( 'ReturnError', 'from_ensembl', [$_] );
  };
  $self->status_ok($c, entity => $c->stash->{entity});
}


sub _encode :Private{
  my ($self, $c, $archive) = @_;
  my ($enc, $peptide, @replacements);
  # my $aia = $c->model('Registry')->get_adaptor($c->stash()->{species},'Core','ArchiveStableID');
  $peptide = $archive->get_peptide if (!$archive->is_current);

  if (!$archive->is_current) {
    foreach my $successor (@{ $archive->get_all_successors }) {
      my $event = $archive->get_event($successor->stable_id);
      my $score = $event->score;
      push(@replacements, { stable_id => $successor->stable_id, score => $score });
    }
  }

  $enc = {
      id => $archive->stable_id,
      version => $archive->version,
      release => $archive->release,
      is_current => $archive->is_current,
      assembly => $archive->assembly,
      type => $archive->type,
      possible_replacement => \@replacements,
      latest => $archive->get_latest_incarnation->stable_id .".". $archive->get_latest_incarnation->version,
      peptide => $peptide,
  };
  return $enc;
}

sub _fetch_archive_by_id {
  my ($self,$c,$id) = @_;

  my ($stable_id, $version) = split(/\./, $id);
  my $archive;

  my @results = $c->model('Lookup')->find_object_location($stable_id, undef, 1);
  if (!@results) {
    return;
  }
  my $species = $results[0];
  my $adaptor = $c->model('Registry')->get_adaptor($species,'Core','ArchiveStableID');
  
  if ($version) {
    $archive = $adaptor->fetch_by_stable_id_version($stable_id, $version);
  } else {
    $archive = $adaptor->fetch_by_stable_id($stable_id);
  }
  return $archive;
}

__PACKAGE__->meta->make_immutable;

1;
