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
  try {
    $self->_get_archive($c, $id);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  $self->status_ok($c, entity => $c->stash->{archives}->[0]);
}

sub id_POST {
  my ($self, $c) = @_;
  
  my $payload = $c->req->data();
  my $ids = $payload->{id};
  $self->assert_post_size($c,$ids);
  foreach my $id (@$ids){
    try {
      $self->_get_archive($c, $id);
    }
  };
  $self->status_ok($c, entity => $c->stash->{archives});
}


sub _get_archive :Private{
  my ($self, $c, $id) = @_;
  $c->model('Lookup')->fetch_archive_by_id($id);
  my $s = $c->stash();
  my $archive = $s->{archive};
  my ($enc, $peptide, @replacements);
  $peptide = $archive->get_peptide if (!$archive->is_current);

  my $archive_stash = $s->{archives};

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

  push @$archive_stash, $enc;
  $s->{archives} = $archive_stash;

  return;
}

__PACKAGE__->meta->make_immutable;

1;
