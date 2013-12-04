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

package EnsEMBL::REST::Builder::TreeHash;

use Moose;
use namespace::autoclean;
use Bio::EnsEMBL::Utils::Scalar qw(check_ref);

has 'aligned'       => ( isa => 'Bool', is => 'rw', default => 0);
has 'cdna'          => ( isa => 'Bool', is => 'rw', default => 0);
has 'no_sequences'  => ( isa => 'Bool', is => 'rw', default => 0);
has 'source'        => ( isa => 'Str', is => 'rw', default => 'ensembl');
has 'type'          => ( isa => 'Str', is => 'rw', default => 'gene tree');

sub convert {
  my ($self, $tree) = @_;
  
  return $self->_head_node($tree);
}

sub _head_node {
  my ($self, $tree) = @_;
  my $hash = {
    type => $self->type(),
    rooted => 1,
  };

  if($tree->can('stable_id')) {
    $hash->{id} = $tree->stable_id();
  }

  $hash->{tree} = 
    $self->_recursive_conversion($tree->root());

  return $hash;
}

sub _recursive_conversion {
  my ($self, $tree) = @_;;
  my $new_hash = $self->_convert_node($tree);
  if($tree->get_child_count()) {
    my @converted_children;
    foreach my $child (@{$tree->sorted_children()}) {
      my $converted_child = $self->_recursive_conversion($child);
      push(@converted_children, $converted_child);
    }
    $new_hash->{children} = \@converted_children;
  }
  return $new_hash;
}

sub _convert_node {
  my ($self, $node) = @_;
  my $hash;

  my $type  = $node->get_tagvalue('node_type');
  my $boot  = $node->get_tagvalue('bootstrap');
  my $tax   = $node->species_tree_node();

  $hash->{branch_length} = $node->distance_to_parent() + 0;
  if($tax) {
    $hash->{taxonomy} = { id => $tax->taxon_id + 0, scientific_name => $tax->node_name };
  }
  if($boot) {
    $hash->{confidence} = { type => "boostrap", value => $boot + 0 };
  }
  if($type) { # && $type ~~ [qw/duplication dubious/]) {
    $hash->{events} = { type => $type };
  }
  
  if(check_ref($node, 'Bio::EnsEMBL::Compara::GeneTreeMember')) {
    my $gene = $node->gene_member();

    $hash->{id} = { source => "EnsEMBL", accession => $gene->stable_id() };

    my $genome_db = $node->genome_db();
    my $taxid = $genome_db->taxon_id();
    $hash->{taxonomy} = 
      { id => $taxid + 0, scientific_name => $genome_db->taxon->scientific_name() }
	if $taxid;

    $hash->{sequence} = 
      { 
       # type     => 'protein', # are we sure we always have proteins?
       id       => [ { source => 'EnsEMBL', accession => $node->stable_id() } ],
       location => sprintf('%s:%d-%d',$gene->chr_name(), $gene->dnafrag_start(), $gene->dnafrag_end())
      };
    $hash->{sequence}->{name} = $node->display_label() if $node->display_label();

    if(! $self->no_sequences()) {
      my $aligned = $self->aligned();
      my $mol_seq;
      if($aligned) {
        $mol_seq = ($self->cdna()) ? $node->alignment_string('cds') : $node->alignment_string();
      }
      else {
        $mol_seq = ($self->cdna()) ? $node->other_sequence('cds') : $node->sequence();
      }

      $hash->{sequence}->{mol_seq} = { is_aligned => $aligned + 0, seq => $mol_seq };
    }
  }

  return $hash;
}

__PACKAGE__->meta()->make_immutable();

1;
