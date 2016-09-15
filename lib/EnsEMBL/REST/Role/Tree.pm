=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
Copyright [2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::REST::Role::Tree;
use Moose::Role;
use namespace::autoclean;
use Bio::EnsEMBL::Compara::Graph::OrthoXMLWriter;
use Bio::EnsEMBL::Compara::Graph::GeneTreePhyloXMLWriter;
use Bio::EnsEMBL::Compara::Graph::GenomicAlignTreePhyloXMLWriter;
use Bio::EnsEMBL::Utils::Scalar qw/check_ref/;
use IO::String;

sub encode_phyloxml {
  my ($self, $c, $stash_key) = @_;

  $stash_key ||= 'rest';
  my $string_handle = IO::String->new();
  my $w;

  # GeneTree parameters
  $w = Bio::EnsEMBL::Compara::Graph::GeneTreePhyloXMLWriter->new(
    -SOURCE => 'Ensembl', -HANDLE => $string_handle
  );

  $w->aligned(1) if $c->request()->param('aligned') || $c->request()->param('phyloxml_aligned');
  my $sequence = $c->request->param('sequence') || $c->request()->param('phyloxml_sequence') || 'protein';
  $w->cdna(1) if $sequence eq 'cdna';
  $w->no_sequences(1) if $sequence eq 'none';

  my $trees = $c->stash->{$stash_key};

  my $roots;

  #genomic alignments
  if (ref($trees) eq 'ARRAY') {

    $w = Bio::EnsEMBL::Compara::Graph::GenomicAlignTreePhyloXMLWriter->new(
      -SOURCE => 'Ensembl', -HANDLE => $string_handle
    );

    #default aligned state is 1
    $w->aligned($c->stash->{"aligned"});

    #Set compact_alignments and no_branch_length option to Bio::EnsEMBL::Compara::Graph::PhyloXMLWriter
    $w->compact_alignments($c->stash->{'compact'});
    $w->no_branch_lengths($c->stash->{'no_branch_lengths'});
    
    foreach my $tree (@$trees) {
      if (check_ref($tree, 'Bio::EnsEMBL::Compara::GenomicAlignTree')) {
	push @$roots, $tree;
      } else {
	$c->go('ReturnError', 'custom', ["An array of Bio::EnsEMBL::Compara::GenomicAlignTree objects is currently only supported"]);
      }
    }
  } elsif ($c->namespace eq 'genetree') {
    #gene tree
    push @$roots, $trees;
  }
  $w->write_trees($roots);
  $w->finish();

  #Free tree structure
  ## mp12 17-Jul-2014: No needed since *PhyloXMLWriter's free the trees. But I suppose it doesn't harm to double check
  foreach my $root (@$roots) {
    $root->release_tree();
  }

  return $string_handle->string_ref();
}


sub encode_orthoxml {
  my ($self, $c, $stash_key) = @_;

  $stash_key ||= 'rest';
  my $string_handle = IO::String->new();
  my $w;

  # GeneTree parameters
  $w = Bio::EnsEMBL::Compara::Graph::OrthoXMLWriter->new(
    -SOURCE => 'Ensembl', -HANDLE => $string_handle
  );

  my $tree = $c->stash->{$stash_key};
  $w->write_trees($tree);
  $w->finish();

  return $string_handle->string_ref();
}


sub encode_nh {
  my ($self, $c, $stash_key) = @_;
  $stash_key ||= 'rest';
  my $gt = $c->stash->{$stash_key};
  my $nh_format = $c->request->param('nh_format') || 'simple';
  my $root = $gt->root();
  my $str = $root->newick_format($nh_format);
  if ($gt->can('release_tree')) {
    $gt->release_tree();
  } elsif ($root->can('release_tree')) {
    $root->release_tree();
  }
  return \$str;
}

around 'set_content_disposition' => sub {
  my ($orig, $self, $c, $ext, $stash_key) = @_;
  $stash_key ||= 'rest';
  my $tree = $c->stash->{$stash_key};

  if (check_ref($tree, "Bio::EnsEMBL::Compara::GeneTree")) {
    my $name = $tree->stable_id();
    return $self->$orig($c, $name, $ext);
  }
};

with 'EnsEMBL::REST::Role::Content';

1;
