package EnsEMBL::REST::View::BED;
use Moose;
use namespace::autoclean;
use IO::String;

extends 'Catalyst::View';

sub process {
  my ($self, $c, $stash_key) = @_;
  $stash_key ||= 'rest';
  my $output_fh = IO::String->new();
  my $ucsc_name_cache = {};
  my $features = $c->stash()->{$stash_key};
  foreach my $feature (@{$features}) {
    $self->_write_Feature($output_fh, $feature, $ucsc_name_cache);
  }
  $c->res->body(${$output_fh->string_ref()});
  $c->res->headers->header('Content-Type' => 'text/x-bed');
  return 1;
}

sub _write_Feature {
  my ($self, $fh, $feature, $cache) = @_;
  return unless $feature;
  my $bed_array;
  if($feature->isa('Bio::EnsEMBL::Transcript')) {
    $bed_array = $self->_write_Transcript($feature, $cache);
  }
  else {
    $bed_array = $self->_feature_to_bed_array($feature, $cache);
  }
  my $bed_line = join("\t", @{$bed_array});
  print $fh $bed_line, "\n";
  return 1;
}

sub _write_Transcript {
  my ($self, $transcript) = @_;

  # Not liking this. If we are in this situation we need to re-fetch the transcript
  # just so the thing ends up on the right Slice!
  my $new_transcript = $transcript->transfer($transcript->slice()->seq_region_Slice());
  my $bed_array = $self->_feature_to_bed_array($transcript);
  my $bed_genomic_start = $bed_array->[1]; #remember this is in 0 coords
  my ($coding_start, $coding_end, $exon_starts_string, $exon_lengths_string, $exon_count, $rgb) = (0,0,q{},q{},0,0);
  
  # If we have a translation then we do some maths to calc the start of 
  # the thick sections. Otherwise we must have a ncRNA or pseudogene
  # and that thick section is just set to the transcript's end
  if($new_transcript->translation()) {
    # Rules are if it's got a coding start we will use it; if not we use the cDNA
    $coding_start = $self->_cdna_to_genome($new_transcript, $new_transcript->cdna_coding_start());
    $coding_start--;

    #Same again but for the end
    $coding_end = $self->_cdna_to_genome($new_transcript, $new_transcript->cdna_coding_end());
  }
  else {
    # apparently looking at UCSC's own BED output formats we do not need to bother
    # coverting $coding_start into 0 based coords for this one ... odd
    $coding_start = $new_transcript->seq_region_end();
    $coding_end = $coding_start;
  }

  # Now for the interesting bit. Exons are given relative to the bed start
  # so we need to calculate the offset. Lovely.
  # Also sort exons by start otherwise offset calcs are wrong
  foreach my $exon (sort { $a->seq_region_start() <=> $b->seq_region_start() } @{$new_transcript->get_all_Exons()}) {
    my $exon_start = $exon->seq_region_start();
    $exon_start--; #move into 0 coords
    my $offset = $exon_start - $bed_genomic_start; # just have to minus current start from the genomic start
    $exon_starts_string .= $offset.',';
    $exon_lengths_string .= $exon->length().',';
    $exon_count++;
  }

  push(@{$bed_array}, $coding_start, $coding_end, $rgb, $exon_count, $exon_lengths_string, $exon_starts_string);
  return $bed_array;
}

sub _cdna_to_genome {
  my ($self, $transcript, $coord) = @_;
  my @mapped = $transcript->cdna2genomic($coord, $coord);
  my $genomic_coord = $mapped[0]->start();
  return $genomic_coord;
}

=head2 _feature_to_bed_array

  Arg [1]     : Bio::EnsEMBL::Feature
                The Feature to encode
  Arg [2]     : HashRef
                Cache of retrieved Slice names.
  Description : Takes a feature and returns an extended BED record consumed up to field
                6 of the format (strand). Score is left as 0
  Returntype  : ArrayRef of fields encoded as
                [chr, start, end, display, 0, strand]

=cut

sub _feature_to_bed_array {
  my ($self, $feature, $cache) = @_;
  my $chr_name = $self->_feature_to_UCSC_name($feature, $cache);
  my $start = $feature->seq_region_start() - 1;
  my $end = $feature->seq_region_end();
  my $strand = ($feature->seq_region_strand() == -1) ? '-' : '+'; 
  my $display_id = $feature->display_id();
  return [ $chr_name, $start, $end, $display_id, 0, $strand ];
}

=head2 _feature_to_UCSC_name

  Arg [1]     : Bio::EnsEMBL::Feature
                Feature object whose seq_region_name must be converted
  Arg [2]     : HashRef
                Cache of retrieved names. Here because we are unaware of the
                lifetime of a View in Catalyst (is it persistent between requests)
  Description : Attempts to figure out what UCSC calls this Slice. First we
                consult the synonyms attached to the Slice, then ask if it is a chromsome
                (accounting for MT -> chrM) and adding a chr to the name if it was a reference
                Slice. If it was none of these the name is just passed through
  Returntype  : String of the UCSC name

=cut

sub _feature_to_UCSC_name {
  my ($self, $feature, $cache) = @_;
  my $seq_region_name = $feature->seq_region_name();

  #Return if the name was already defined (we assume we work within a single species)
  return $cache->{$seq_region_name} if exists $cache->{$seq_region_name};

  if(! $feature->can('slice')) {
    return $cache->{$seq_region_name} = $seq_region_name;
  }
  my $slice = $feature->slice();
  my $ucsc_name;
  my $has_adaptor = ($slice->adaptor()) ? 1 : 0;
  if($has_adaptor) { # if it's got an adaptor we can lookup synonyms
    my $synonyms = $slice->get_all_synonyms('UCSC');
    if(@{$synonyms}) {
      $ucsc_name = $synonyms->[0]->name();
    }
  }
  if(! defined $ucsc_name) {
    # if it's a chromosome then we can test a few more things
    if($slice->is_chromosome()) {
      #MT is a special case; it's chrM
      if($seq_region_name eq 'MT' ) {
        $ucsc_name = 'chrM';
      }
      # If it was a ref region add chr onto it (only check if we have an adaptor)
      elsif($has_adaptor && $slice->is_reference()) {
        $ucsc_name = 'chr'.$seq_region_name;
      }
    }
  }
  #Leave it as the seq region name otherwise
  $ucsc_name = $seq_region_name if ! defined $ucsc_name;
  $cache->{$seq_region_name} = $ucsc_name;
  return $ucsc_name;
}

with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;
