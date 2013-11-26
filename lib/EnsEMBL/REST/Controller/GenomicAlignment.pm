=head1 LICENSE

Copyright [1999-2013] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::REST::Controller::GenomicAlignment;
use Moose;
use namespace::autoclean;
use Try::Tiny;
require EnsEMBL::REST;

BEGIN { extends 'Catalyst::Controller::REST'; }

has 'max_slice_length' => ( isa => 'Num', is => 'ro', default => 1e6);

sub get_adaptors :Private {
  my ($self, $c) = @_;

  try {
    my $species = $c->stash()->{species};
    my $compara_dba = $c->model('Registry')->get_best_compara_DBAdaptor($species, $c->request()->param('compara'));
    my $mlssa = $compara_dba->get_MethodLinkSpeciesSetAdaptor();
    my $gdba = $compara_dba->get_GenomeDBAdaptor();
    my $asa = $compara_dba->get_AlignSliceAdaptor();
    my $gata = $compara_dba->get_GenomicAlignTreeAdaptor();
    my $gaba = $compara_dba->get_GenomicAlignBlockAdaptor();
    
    $c->stash(
      compara_dba => $compara_dba,
      method_link_species_set_adaptor => $mlssa,
      genome_db_adaptor => $gdba,
      align_slice_adaptor => $asa,
      genomic_align_tree_adaptor => $gata,
      genomic_align_block_adaptor => $gaba,
    );
  }
  catch {
    $c->go('ReturnError', 'from_ensembl', [$_]);
  };
}

sub get_slice_species : Chained("/") PathPart("alignment/slice/region") CaptureArgs(1) {
  my ( $self, $c, $species ) = @_;
  $c->stash->{species} = $species;
}

sub slice_region_GET { }

sub slice_region : Chained("get_slice_species") PathPart("") Args(1) ActionClass('REST') {
    my ( $self, $c, $region ) = @_;

    #getting AlignSlice alignments
    my $align_slice = 1;
    my $alignments;
    try {
      #$c->log()->debug('Finding the Slice');
      my $slice = $c->model('Lookup')->find_slice($region);

      #Check for maximum slice length
      $self->assert_slice_length($c, $slice);

      #$c->log()->debug('Finding the alignment');
      $alignments = $c->model('GenomicAlignment')->get_alignment($slice, $align_slice);
    } catch {
      $c->go('ReturnError', 'from_ensembl', [$_]);
    };
    $self->status_ok($c, entity => $alignments);
    return;
}

sub get_block_species : Chained("/") PathPart("alignment/block/region") CaptureArgs(1) {
  my ( $self, $c, $species ) = @_;
  $c->stash->{species} = $species;
}

sub block_region_GET { }

sub block_region : Chained("get_block_species") PathPart("") Args(1) ActionClass('REST') {
    my ( $self, $c, $region ) = @_;

    #getting GenomicAlignBlock or GenomicAlignTree alignments
    my $align_slice = 0;
    my $alignments;
    try {
      #$c->log()->debug('Finding the Slice');
      my $slice = $c->model('Lookup')->find_slice($region);

      #Check for maximum slice length
      $self->assert_slice_length($c, $slice);

      $alignments = $c->model('GenomicAlignment')->get_alignment($slice, $align_slice);
    } catch {
      $c->go('ReturnError', 'from_ensembl', [$_]);
    };
    $self->status_ok($c, entity => $alignments);
    return;
}


with 'EnsEMBL::REST::Role::SliceLength';

__PACKAGE__->meta->make_immutable;

1;
