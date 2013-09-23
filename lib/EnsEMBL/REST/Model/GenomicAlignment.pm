package EnsEMBL::REST::Model::GenomicAlignment;

use Moose;

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
  my ($self, $slice, $align_slice) = @_;
  my $c = $self->context();
  my $alignments;

  #Get method
  my $method = $c->request->parameters->{method} || 'EPO';
  $c->go('ReturnError', 'custom', ["The method '$method' is not understood by this service"]) unless $allowed_values{method}{$method};

  #Get species_set
  my $species_set = $c->request->parameters->{species_set};

  #Get species_set_group
  my $species_set_group = $c->request->parameters->{species_set_group};
  #$c->go('ReturnError', 'custom', ["The species_set '$species_set_group' is not understood by this service"]) unless $allowed_values{species_set_group}{$species_set_group};

  #set default species_set_group only if species_set hasn't been set
  unless ($species_set || $species_set_group) {
    $species_set_group = 'mammals';
  }

  #Check that both $species_set and $species_set_group have not been set
  if ($species_set && $species_set_group) {
    $c->go('ReturnError', 'custom', ["Please define species_set OR species_set_group"]);
  }

  #Get masking
  my $mask = $c->request()->param('mask') || q{};
  if ($mask) {
    $c->go('ReturnError', 'custom', ["'$mask' is not an allowed value for masking"]) unless $allowed_values{mask}{$mask};
  }

  #If false, gets the low coverage segments as seperate objects
  my $compact_all_alignments = $c->request->parameters->{compact};

  #Get the compara DBAdaptor
  $c->forward('get_adaptors');
  
  #Get method_link_species_set from method and species_set or species_set_group parameters
  my $mlss;
  if ($species_set_group) {
    $mlss = $c->stash->{method_link_species_set_adaptor}->fetch_by_method_link_type_species_set_name($method, $species_set_group);    
    $c->go('ReturnError', 'custom', ["No method_link_specices_set found for method ${method} and species_set_group ${species_set_group} "]) if ! $mlss;
  }

  if ($species_set) {
    $species_set = (ref($species_set) eq 'ARRAY') ? $species_set : [$species_set];
    $mlss = $c->stash->{method_link_species_set_adaptor}->fetch_by_method_link_type_registry_aliases($method, $species_set);
    $c->go('ReturnError', 'custom', ["No method_link_specices_set found for method ${method} and species_set " . join ",", @${species_set} ]) if ! $mlss;
  }

  #Get list of species to display
  my $display_species;
  my $display_species_set = $c->request->parameters->{display_species_set};
  if ($display_species_set) {
    $display_species = (ref($display_species_set) eq 'ARRAY') ? $display_species_set : [$display_species_set];
  }

  #Get alignments
  if ($align_slice) {
    #Use AlignSlice method

    my $expanded = $c->request->parameters->{expanded} || 0;

    #Check overlap enums
    my $overlaps = $c->request()->param('overlaps') || q{};
    if ($overlaps) {
      $c->go('ReturnError', 'custom', ["'$overlaps' is not an allowed value for overlaps"]) unless $allowed_values{overlaps}{$overlaps};
    }

    #Reassign text to boolean arguments currently required by the API
    if ($overlaps eq "none") {
      $overlaps = 0;
    } elsif ($overlaps eq "all") {
      $overlaps = 1;
    }

    #Get AlignSlice object
    #??? what about target_slice???
    my $align_slice = $c->stash->{align_slice_adaptor}->fetch_by_Slice_MethodLinkSpeciesSet($slice, $mlss, $expanded, $overlaps);

    #Convert AlignSlice object into hash
    my $align_hash;
    my $these_alignments = $align_slice->summary_as_hash($display_species, $mask);

    $align_hash->{'alignments'} = ratify_summary($c, $these_alignments);
    push @$alignments, $align_hash;

  } else {
    #use GenomicAlignBlock or GenomicAlignTree method

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
    
    #Dump these alignments
    foreach my $this_genomic_align_block (@$genomic_align_blocks) {

      my $align_hash;

      #Convert GenomicAlignBlock/GenomicAlignTree object to a hash
      my $these_alignments = $this_genomic_align_block->summary_as_hash($display_species, $mask, $compact_all_alignments);

      #Get newick tree if EPO (the only alignment method which has trees)
      my $newick_trees;
      my $nh_format = 'simple'; #Only allow simple format for now
      if ($method eq "EPO") {
	my $newick_tree = $this_genomic_align_block->root->newick_format($nh_format);
	$align_hash->{'tree'} = $newick_tree;
      }

      #Tidy up memory
      if ($this_genomic_align_block->isa("Bio::EnsEMBL::Compara::GenomicAlignTree")) {
	deep_clean($this_genomic_align_block);
	$this_genomic_align_block->release_tree();
      } else {
	$this_genomic_align_block = undef;
      }

      #ensure numeric values are actually numeric
      $align_hash->{'alignments'} = ratify_summary($c, $these_alignments);
      push @$alignments, $align_hash;
    }
  }
  return $alignments;
}

sub deep_clean {
  my ($genomic_align_tree) = @_;

  my $all_nodes = $genomic_align_tree->get_all_nodes;
  foreach my $this_genomic_align_node (@$all_nodes) {
    my $this_genomic_align_group = $this_genomic_align_node->genomic_align_group;
    next if (!$this_genomic_align_group);
    foreach my $this_genomic_align (@{$this_genomic_align_group->get_all_GenomicAligns}) {
      foreach my $key (keys %$this_genomic_align) {
        if ($key eq "genomic_align_block") {
          foreach my $this_ga (@{$this_genomic_align->{$key}->get_all_GenomicAligns}) {
            my $gab = $this_ga->{genomic_align_block};
            my $gas = $gab->{genomic_align_array};
            if ($gas) {
              for (my $i = 0; $i < @$gas; $i++) {
                delete($gas->[$i]);
              }
            }

            delete($this_ga->{genomic_align_block}->{genomic_align_array});
            delete($this_ga->{genomic_align_block}->{reference_genomic_align});
            undef($this_ga);
          }
        }
        delete($this_genomic_align->{$key});
      }
      undef($this_genomic_align);
    }
    undef($this_genomic_align_group);
  }
}


#Have to do this to force JSON encoding to encode numerics as numerics
my @KNOWN_NUMERICS = qw( start end strand );

sub ratify_summary {
  my ($c, $summary) = @_;
  
  my $hash;
  my $seqs;
  foreach my $aln (@{$summary}) {
    foreach my $key (@KNOWN_NUMERICS) {
      my $v = $aln->{$key};
      #$c->log()->debug("key $key, $v\n");
      $aln->{$key} = ($v*1) if defined $v;
    }
    #push @$seqs, $aln;
  }
  #$hash->{aln} = $seqs;
  return $summary;

}

__PACKAGE__->meta->make_immutable;

1;
