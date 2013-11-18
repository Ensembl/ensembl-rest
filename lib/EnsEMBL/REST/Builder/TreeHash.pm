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
  my $hash = $self->_head_node($tree);
  return $self->_recursive_conversion($tree->root(), $hash);
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

  return $hash;
}

sub _recursive_conversion {
  my ($self, $tree, $hash) = @_;;
  my $new_hash = $self->_convert_node($tree, $hash);
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

# If $hash is given we will add attributes to the hash. If not 
# then we will create a new one. 
sub _convert_node {
  my ($self, $node, $hash) = @_;
  $hash ||= {};

  my $type  = $node->get_tagvalue('node_type');
  my $boot  = $node->get_tagvalue('bootstrap');
  my $taxid = $node->get_tagvalue('taxon_id');
  my $tax   = $node->get_tagvalue('taxon_name');

  $hash->{branch_length} = $node->distance_to_parent() + 0;
  if($taxid) {
    $hash->{taxonomy} = { id => $taxid + 0, scientific_name => $tax };
  }
  if($boot) {
    $hash->{boostrap} = $boot + 0;
  }
  if($type && $type ~~ [qw/duplication dubious/]) {
      $hash->{event} = $type;
  }
  
  if(check_ref($node, 'Bio::EnsEMBL::Compara::GeneTreeMember')) {
    my $gene = $node->gene_member();
    $hash->{name} = $gene->stable_id();
    $hash->{genome_db_name} = $node->genome_db()->name();
    $hash->{sequence}->{accession} = $node->stable_id();
    $hash->{sequence}->{source} = $self->source();
    $hash->{sequence}->{name} = $node->display_label() if $node->display_label();
    $hash->{sequence}->{location} = sprintf('%s:%d-%d',$gene->chr_name(), $gene->chr_start(), $gene->chr_end());
    if(! $self->no_sequences()) {
      my $aligned = $self->aligned();
      my $mol_seq;
      if($aligned) {
        $mol_seq = ($self->cdna()) ? $node->alignment_string('cds') : $node->alignment_string();
      }
      else {
        $mol_seq = ($self->cdna()) ? $node->other_sequence('cds') : $node->sequence();
      }

      $hash->{sequence}->{seq} = $mol_seq;
      $hash->{sequence}->{aligned} = $aligned + 0;
    }
  }

  return $hash;
}

__PACKAGE__->meta()->make_immutable();

1;
