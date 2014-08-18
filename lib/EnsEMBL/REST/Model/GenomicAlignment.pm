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

package EnsEMBL::REST::Model::GenomicAlignment;
use Bio::EnsEMBL::Utils::Scalar qw/check_ref/;

use Moose;
use Catalyst::Exception;

extends 'Catalyst::Model';
with 'Catalyst::Component::InstancePerContext';

# Per instance variables
has 'context' => (is => 'ro');

my %allowed_values = (
  mask     => { map { $_, 1} qw(soft hard) },
  method   => { map { $_, 1} qw(EPO EPO_LOW_COVERAGE PECAN LASTZ_NET BLASTZ_NET TRANSLATED_BLAT_NET) },
  overlaps => { map { $_, 1} qw(none all restrict) },
#  species_set_group => { map { $_, 1} qw(mammals amniotes fish birds) },
);

sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  return $self->new({ context => $c, %$self, @args });
}

sub get_alignment {
  my ($self, $slice) = @_;
  my $c = $self->context();
  my $alignments;

  #Get method
  my $method = $c->request->parameters->{method} || 'EPO';
  Catalyst::Exception->throw("The method '$method' is not understood by this service") unless $allowed_values{method}{$method};

  #Get species_set
  my $species_set = $c->request->parameters->{species_set};

  #Get species_set_group
  my $species_set_group = $c->request->parameters->{species_set_group};

  #set default species_set_group only if species_set hasn't been set
  unless ($species_set || $species_set_group) {
    $species_set_group = 'mammals';
  }

  #Check that both $species_set and $species_set_group have not been set
  if ($species_set && $species_set_group) {
    Catalyst::Exception->throw("Please define species_set OR species_set_group");
  }

  #Get masking
  my $mask = $c->request()->param('mask') || q{};
  if ($mask) {
    Catalyst::Exception->throw("'$mask' is not an allowed value for masking") unless $allowed_values{mask}{$mask};
  }

  #Get the compara DBAdaptor
  $c->forward('get_adaptors');
  
  #Get method_link_species_set from method and species_set or species_set_group parameters
  my $mlss;
  if ($species_set_group) {
    $mlss = $c->stash->{method_link_species_set_adaptor}->fetch_by_method_link_type_species_set_name($method, $species_set_group);    
    Catalyst::Exception->throw("No method_link_specices_set found for method ${method} and species_set_group ${species_set_group} ") if ! $mlss;
  }
  if ($species_set) {
    $species_set = (ref($species_set) eq 'ARRAY') ? $species_set : [$species_set];
    $mlss = $c->stash->{method_link_species_set_adaptor}->fetch_by_method_link_type_registry_aliases($method, $species_set);
    Catalyst::Exception->throw("No method_link_specices_set found for method ${method} and species_set " . join ",", @${species_set} ) if ! $mlss;
  }

  #Get list of species to display
  my $display_species;
  my $display_species_set = $c->request->parameters->{display_species_set};
  if ($display_species_set) {
    $display_species = (ref($display_species_set) eq 'ARRAY') ? $display_species_set : [$display_species_set];
  }

  #Get alignments
  #Get either the genomic_align_block_adaptor or genomic_align_tree_adaptor
  my $genomic_align_set_adaptor;
  if ($mlss->method->class =~ /GenomicAlignTree/) {
    $genomic_align_set_adaptor = $c->stash->{genomic_align_tree_adaptor};
  } else {
    $genomic_align_set_adaptor = $c->stash->{genomic_align_block_adaptor};
  }
  
  # Fetching all the GenomicAlignBlock/GenomicAlignTree objects corresponding to this Slice:
  my $genomic_align_blocks =
    $genomic_align_set_adaptor->fetch_all_by_MethodLinkSpeciesSet_Slice($mlss, $slice, undef, undef, 'restrict');
  
  my $new_genomic_align_trees;
  foreach my $this_genomic_align_tree (@$genomic_align_blocks) {
    
    #Convert GenomicAlignBlock object into a GenomicAlignTree object
    if ($mlss->method->class =~ /GenomicAlignBlock/) {
      $this_genomic_align_tree = $this_genomic_align_tree->get_GenomicAlignTree();
    } else {
      $this_genomic_align_tree->annotate_node_type();
    }

    #Must have new object here because of potential tree pruning (calls minimize_tree)
    $this_genomic_align_tree->repeatmask($mask);
    my $new_tree = $this_genomic_align_tree->prune($display_species);
    push @$new_genomic_align_trees, $new_tree;
  }
  
  return  $new_genomic_align_trees;
}

sub get_tree_as_hash {
  my ($self, $genomic_align_trees) = @_;
  my $c = $self->context();

   #If false, gets the low coverage segments as seperate objects
  my $compact_alignments = $c->stash->{compact};

  #Use aligned (true) or original (false) sequence
  my $aligned = $c->stash->{aligned};

  #Do not display branch lengths if true
  my $no_branch_lengths = $c->stash->{"no_branch_lengths"};

  my $alignments;
  #Dump these alignments
   foreach my $this_genomic_align_tree (@$genomic_align_trees) {
     my $align_hash;
   
     #Convert GenomicAlignTree object to a hash
     my $these_alignments = $this_genomic_align_tree->summary_as_hash($compact_alignments, $aligned);
    
     #Get newick tree if have GenomicAlignTree object
     my $newick_trees;
     
     #Only have ancestral sequences for EPO alignments
     my $nh_format;
     if ($this_genomic_align_tree->method_link_species_set->method->class =~ /ancestral_alignment/) {
       $nh_format = 'full';
     } else {
       $nh_format = 'simple';
     }
    
     if (check_ref($this_genomic_align_tree, 'Bio::EnsEMBL::Compara::GenomicAlignTree')) {
       my $newick_tree ;
       if ($no_branch_lengths) {
	 $newick_tree = $this_genomic_align_tree->root->newick_format("ryo", '%{^-n}');
       } else {
	 $newick_tree = $this_genomic_align_tree->root->newick_format($nh_format);
       }
       $align_hash->{'tree'} = $newick_tree;
     }

     #Tidy up memory
     if ($this_genomic_align_tree->isa("Bio::EnsEMBL::Compara::GenomicAlignTree")) {
       $this_genomic_align_tree->release_tree();
     } else {
       $this_genomic_align_tree = undef;
     }
    
     #ensure numeric values are actually numeric
     $align_hash->{'alignments'} = ratify_summary($these_alignments);
     push @$alignments, $align_hash;
   }
   return $alignments;
}

#Have to do this to force JSON encoding to encode numerics as numerics
my @KNOWN_NUMERICS = qw( start end strand );

sub ratify_summary {
  my ($summary) = @_;
  
  my $hash;
  my $seqs;
  foreach my $aln (@{$summary}) {
    foreach my $key (@KNOWN_NUMERICS) {
      my $v = $aln->{$key};
      $aln->{$key} = ($v*1) if defined $v;
    }
    #push @$seqs, $aln;
  }
  #$hash->{aln} = $seqs;
  return $summary;

}

__PACKAGE__->meta->make_immutable;

1;
