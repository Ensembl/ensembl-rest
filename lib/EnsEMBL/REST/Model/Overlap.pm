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

package EnsEMBL::REST::Model::Overlap;

use Moose;
extends 'Catalyst::Model';
use Catalyst::Exception;
use Scalar::Util qw/weaken/;
use Bio::EnsEMBL::Feature;
use EnsEMBL::REST::EnsemblModel::TranscriptVariation;
use EnsEMBL::REST::EnsemblModel::TranslationSpliceSiteOverlap;
use EnsEMBL::REST::EnsemblModel::TranslationExon;
use EnsEMBL::REST::EnsemblModel::TranslationSlice;
use EnsEMBL::REST::EnsemblModel::TranslationProteinFeature;

use Bio::EnsEMBL::Utils::Scalar qw/wrap_array/;

has 'allowed_features' => ( isa => 'HashRef', is => 'ro', lazy => 1, default => sub {
  return {
    map { $_ => 1 } qw/gene transcript cds exon repeat simple misc variation somatic_variation structural_variation somatic_structural_variation constrained regulatory motif band mane/
  };
});

has 'allowed_translation_features' => ( isa => 'HashRef', is => 'ro', lazy => 1, default => sub {
  return {
    'transcript_variation'=> 1, 'protein_feature' => 1, 'residue_overlap' => 1, 'translation_exon' => 1, 'somatic_transcript_variation' => 1
  };
});

has 'context' => (is => 'ro', weak_ref => 1);

with 'Catalyst::Component::InstancePerContext', 'EnsEMBL::REST::Role::Content';

sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  weaken($c);
  return $self->new({ context => $c, %$self, @args });
}

sub fetch_features {
  my ($self) = @_;

  my $c = $self->context();
  my $is_gff3 = $self->is_content_type($c, 'text/x-gff3');
  my $is_bed = $self->is_content_type($c, 'text/x-bed');
  my $species = $c->stash->{species};

  my $allowed_features = $self->allowed_features();
  my $feature = $c->request->parameters->{feature};
  Catalyst::Exception->throw("No feature given. Please specify a feature to retrieve from this service") if ! $feature;
  my @features = map {lc($_)} ((ref($feature) eq 'ARRAY') ? @{$feature} : ($feature));

  # normalise cdna & cds since they're the same for bed. the processed_feature_types hash will deal with this
  # bed seraliser does the rest
  if($is_bed) {
    @features = map { ($_ eq 'cds') ? 'transcript' : $_ } @features;
  }

  # record when we've processed a feature type already
  my %processed_feature_types;

  my $slice = $c->stash()->{slice};
  my $vfa = $c->model('Registry')->get_adaptor($species, 'Variation', 'Variation');
  if ($vfa) {
    $vfa->db->include_failed_variations(0);
  }
  my @final_features;
  foreach my $feature_type (@features) {
    next if exists $processed_feature_types{$feature_type};
    next if $feature_type eq 'none';
    my $allowed = $allowed_features->{$feature_type};

    Catalyst::Exception->throw("The feature type $feature_type is not understood") if ! $allowed;
    my $load_exons = ($feature_type eq 'transcript' && $is_bed) ? 1 : 0;
    my $objects = $self->_trim_features($self->$feature_type($slice, $load_exons));
    if($is_gff3 || $is_bed) {
      push(@final_features, @{$objects});
    }
    else {
      push(@final_features, @{$self->to_hash($objects, $feature_type)});
    }
    $processed_feature_types{$feature_type} = 1;
  }

  return \@final_features;
}

sub fetch_protein_features {
  my ($self, $translation) = @_;

  my $c = $self->context();
  my $is_gff3 = $self->is_content_type($c, 'text/x-gff3');
  my $is_bed = $self->is_content_type($c, 'text/x-bed');

  my $feature = $c->request->parameters->{feature};
  my $allowed_features = $self->allowed_translation_features();

  my @final_features;
  $feature = 'protein_feature' if !( defined $feature);
  my @features = (ref($feature) eq 'ARRAY') ? @{$feature} : ($feature);

  if($is_gff3 || $is_bed) {
    $c->stash()->{slice} = EnsEMBL::REST::EnsemblModel::TranslationSlice->new(translation => $translation);
  }

  # record when we've processed a feature type already
  my %processed_feature_types;

  foreach my $feature_type (@features) {
    next if exists $processed_feature_types{$feature_type};
    $feature_type = lc($feature_type);
    my $allowed = $allowed_features->{$feature_type};
    Catalyst::Exception->throw("The feature type $feature_type is not understood") if ! $allowed;
    my $objects = $self->$feature_type($translation);
    if($is_gff3 || $is_bed) {
      push(@final_features, @{$objects});
    }
    else {
      push(@final_features, @{$self->to_hash($objects, $feature_type)});
    }
    $processed_feature_types{$feature_type} = 1;
  }
  return \@final_features;
}

sub fetch_feature {
  my ($self, $id) = @_;
  my $c = $self->context();
  $c->log()->debug('Finding the object');
  my $object = $c->model('Lookup')->find_object_by_stable_id($id);
  my $hash = {};
  if($object) {
    my $hashes = $self->to_hash([$object]);
    $hash = $hashes->[0];
  }
  return $hash;
}

#Have to do this to force JSON encoding to encode numerics as numerics
my @KNOWN_NUMERICS = qw( start end strand version );

sub to_hash {
  my ($self, $features, $feature_type) = @_;
  my @hashed;
  foreach my $feature (@{$features}) {

    my $hash;

    if (lc($feature_type)  eq 'regulatory') {
      $hash = $feature->summary_as_hash_2();
    } else {
      $hash = $feature->summary_as_hash();
    }

    foreach my $key (@KNOWN_NUMERICS) {
      my $v = $hash->{$key};
      $hash->{$key} = ($v*1) if defined $v;
    }
    if ($hash->{Name}) {
      $hash->{external_name} = $hash->{Name};
      delete $hash->{Name};
    }
    $hash->{feature_type} = $feature_type;
    if (lc($feature_type) eq 'transcript') {
      $hash->{is_canonical} = $feature->is_canonical;
    }
    if (lc($feature_type) eq 'gene') {
      $hash->{canonical_transcript} = $feature->canonical_transcript->stable_id.".".$feature->canonical_transcript->version;
    }
    if (lc($feature_type) eq 'protein_feature') {
      if (defined($hash->{description}) && !$hash->{description}) {
        $hash->{description} = $feature->{$feature_type}->{hdescription} if defined($feature->{$feature_type}->{hdescription});
      }
    }
    if (lc($feature_type) eq 'regulatory') {
      next if (!defined $hash->{description});
    }
    push(@hashed, $hash);
  }
  return \@hashed;
}

sub band {
  my ($self, $slice) = @_;
  if ($slice->is_chromosome) {
    return $slice->get_all_KaryotypeBands();
  } else {
    return;
  }
}

sub mane {
  my ($self, $slice) = @_;
  my $c = $self->context();
  my $transcripts = $slice->get_all_Transcripts();
  my $manes;
  foreach my $transcript (@$transcripts) {
    if ($transcript->is_mane) {
      push @$manes, $transcript->mane_transcript;
    }
  }
  return $manes;
}

sub gene {
  my ($self, $slice) = @_;
  my $c = $self->context();
  my ($dbtype, $load_transcripts, $source, $biotype) =
    (undef, undef, $c->request->parameters->{source}, $c->request->parameters->{biotype});
  return $slice->get_all_Genes($self->_get_logic_dbtype(), $load_transcripts, $source, $biotype);
}

sub transcript {
  my ($self, $slice, $load_exons) = @_;
  my $c = $self->context();
  my $biotype = $c->request->parameters->{biotype};
  my $transcripts = $slice->get_all_Transcripts($load_exons, $self->_get_logic_dbtype());
  if($biotype) {
    my %lookup = map { $_, 1 } @{wrap_array($biotype)};
    $transcripts = [ grep { $lookup{$_->biotype()} } @{$transcripts}];
  }
  return $transcripts;
}

sub cds {
  my ($self, $slice, $load_exons) = @_;
  my $transcripts = $self->transcript($slice, 0);
  my @cds;
  foreach my $transcript (@$transcripts) {
    push (@cds, @{ $transcript->get_all_CDS });
  }
  return \@cds;
}

sub exon {
  my ($self, $slice) = @_;
  my $transcripts = $self->transcript($slice, 0);
  my @exons;
  foreach my $transcript (@$transcripts) {
    foreach my $exon (@{ $transcript->get_all_ExonTranscripts}) {
      if (($slice->start <= $exon->seq_region_start && $exon->seq_region_start < $slice->end) || ($slice->start < $exon->seq_region_end && $exon->seq_region_end <= $slice->end) ||($slice->start >= $exon->seq_region_start && $slice->end <= $exon->seq_region_end) ) {
        push (@exons, $exon);
      }
    }
  }
  return \@exons;
}

sub repeat {
  my ($self, $slice) = @_;
  return $slice->get_all_RepeatFeatures();
}

sub protein_feature {
  my ($self, $translation) = @_;
  my $c = $self->context();
  my $type = $c->request->parameters->{type};
  my $protein_features = $translation->get_all_ProteinFeatures($type);
  return EnsEMBL::REST::EnsemblModel::TranslationProteinFeature->get_from_ProteinFeatures($protein_features, $translation);
}

sub transcript_variation {
  my ($self, $translation) = @_;
  my $c = $self->context();
  my $species = $c->stash->{species};
  my $type = $c->request->parameters->{type};
  my @vfs;
  my $transcript = $translation->transcript();
  my $transcript_variants;
  my $tva = $c->model('Registry')->get_adaptor($species, 'variation', 'TranscriptVariation');
  if (!$tva) { return []; }

  my $vfa = $c->model('Registry')->get_adaptor($species, 'variation', 'VariationFeature');
  my $vfs = $vfa->fetch_all_by_Slice($transcript->feature_Slice);
  $c->stash->{_cached_vfs} = $vfs;

  my $so_terms = $self->_get_SO_terms();
  if (scalar(@{$so_terms}) > 0) {
    $transcript_variants = $tva->fetch_all_by_Transcripts_SO_terms([$transcript], $so_terms);
  }
  else {
    $transcript_variants = $tva->fetch_all_by_Transcripts([$transcript]);
  }
  return $self->_filter_transcript_variation($transcript_variants);
}

sub somatic_transcript_variation {
  my ($self, $translation) = @_;
  my $c = $self->context();
  my $species = $c->stash->{species};
  my $type = $c->request->parameters->{type};
  my @vfs;
  my $transcript = $translation->transcript();
  my $transcript_variants;
  my $tva = $c->model('Registry')->get_adaptor($species, 'variation', 'TranscriptVariation');
  if (!$tva) { return []; }

  my $vfa = $c->model('Registry')->get_adaptor($species, 'variation', 'VariationFeature');
  my $vfs = $vfa->fetch_all_somatic_by_Slice($transcript->feature_Slice);
  $c->stash->{_cached_vfs} = $vfs;

  my $so_terms = $self->_get_SO_terms();
  if (scalar(@{$so_terms}) > 0) {
    # HACK FOR DATA BUG IN VARIATION DB
    $transcript_variants = [@{$tva->fetch_all_somatic_by_Transcripts_SO_terms([$transcript], $so_terms)}, @{$tva->fetch_all_by_Transcripts_SO_terms([$transcript], $so_terms)}];
    # $transcript_variants = $tva->fetch_all_somatic_by_Transcripts_SO_terms([$transcript]);
  }
  else {
    # HACK FOR DATA BUG IN VARIATION DB
    $transcript_variants = [@{$tva->fetch_all_somatic_by_Transcripts([$transcript])}, @{$tva->fetch_all_by_Transcripts([$transcript])}];
    # $transcript_variants = $tva->fetch_all_somatic_by_Transcripts([$transcript]);
  }
  return $self->_filter_transcript_variation($transcript_variants);
}

sub _filter_transcript_variation {
  my ($self, $transcript_variants) = @_;
  my $type = $self->context->request->parameters->{type};
  my %cached_vfs = map {$_->dbID => $_} @{$self->context->stash->{_cached_vfs} || []};
  my @vfs;

  foreach my $tv (@{$transcript_variants}) {
    # filter out up/downstream TVs
    next unless $tv->cds_start || $tv->cds_end;

    if ($type && $tv->display_consequence !~ /$type/) { next ; }

    my $vf = $cached_vfs{$tv->{_variation_feature_id}};
    next unless $vf;
    $tv->variation_feature($vf);

    my $blessed_vf = EnsEMBL::REST::EnsemblModel::TranscriptVariation->new_from_variation_feature($vf, $tv);
    push(@vfs, $blessed_vf);
  }
  return \@vfs;
}

sub residue_overlap {
  my ($self, $translation) = @_;
  return EnsEMBL::REST::EnsemblModel::TranslationSpliceSiteOverlap->get_by_Translation($translation);
}

sub translation_exon {
  my ($self, $translation) = @_;
  return EnsEMBL::REST::EnsemblModel::TranslationExon->get_by_Translation($translation);
}

sub variation {
  my ($self, $slice) = @_;

  my $c = $self->context();
  my $vfa = $c->model('Registry')->get_adaptor($c->stash->{species}, 'variation', 'variationfeature');
  if (!$vfa) { return []; }

  if( $c->request->parameters->{variant_set}){
    my $set = $self->_get_VariationSet();
    return $vfa->fetch_all_by_Slice_VariationSet_SO_terms($slice, $set, $self->_get_SO_terms);
  }
  else{
    return $vfa->fetch_all_by_Slice_SO_terms($slice, $self->_get_SO_terms);
  }
}

sub structural_variation {
  my ($self, $slice) = @_;
  my $c = $self->context();
  my $svfa = $c->model('Registry')->get_adaptor($c->stash->{species}, 'variation', 'structuralvariationfeature');
  if (!$svfa) { return []; }
  return $svfa->fetch_all_by_Slice($slice);
}

sub somatic_variation {
  my ($self, $slice) = @_;
  my $c = $self->context();
  my $vfa = $c->model('Registry')->get_adaptor($c->stash->{species}, 'variation', 'variationfeature');
  if (!$vfa) { return []; }
  return $vfa->fetch_all_somatic_by_Slice_SO_terms($slice, $self->_get_SO_terms());
}

sub somatic_structural_variation {
  my ($self, $slice) = @_;
  my $c = $self->context();
  my $svfa = $c->model('Registry')->get_adaptor($c->stash->{species}, 'variation', 'structuralvariationfeature');
  if (!$svfa) { return []; }
  return $svfa->fetch_all_somatic_by_Slice($slice);
}

sub constrained {
  my ($self, $slice) = @_;
  my $c = $self->context();
  my $species_set = $c->request->parameters->{species_set} || 'mammals';
  my $compara_name = $c->model('Registry')->get_compara_name_for_species($c->stash()->{species});
  if (lc($compara_name) eq 'vertebrates') {
    $compara_name = 'multi';
  }
  my $mlssa = $c->model('Registry')->get_adaptor($compara_name, 'compara', 'MethodLinkSpeciesSet');
  Catalyst::Exception->throw("No adaptor found for compara Multi and adaptor MethodLinkSpeciesSet") if ! $mlssa;
  my $method_list = $mlssa->fetch_by_method_link_type_species_set_name('GERP_CONSTRAINED_ELEMENT', $species_set);
  my $cea = $c->model('Registry')->get_adaptor($compara_name, 'compara', 'ConstrainedElement');
  Catalyst::Exception->throw("No adaptor found for compara Multi and adaptor ConstrainedElement") if ! $cea;
  return $cea->fetch_all_by_MethodLinkSpeciesSet_Slice($method_list, $slice);
}


sub regulatory {
  my ($self, $slice) = @_;
  my $c          = $self->context();
  my $species    = $c->stash->{species};
  my $adaptor = $c->model('Registry')->get_adaptor($species, 'funcgen', 'RegulatoryFeature');
  return $adaptor->fetch_all_by_Slice($slice);
}

sub motif {
  my ($self, $slice) = @_;
  my $c       = $self->context;
  my $species = $c->stash->{species};
  my $mfa     = $c->model('Registry')->get_adaptor($species, 'funcgen', 'motiffeature') ||
   Catalyst::Exception->throw("No adaptor found for species $species, object MotifFeature and DB funcgen");
  return $mfa->fetch_all_by_Slice($slice);
}

sub simple {
  my ($self, $slice) = @_;
  my $c = $self->context();
  my ($logic_name, $db_type) = $self->_get_logic_dbtype();
  return $slice->get_all_SimpleFeatures($logic_name, undef, $db_type);
}

sub misc {
  my ($self, $slice) = @_;
  my $c = $self->context();
  my $db_type = $c->request->parameters->{db_type};
  my $misc_set = $c->request->parameters->{misc_set} || undef;
  return $slice->get_all_MiscFeatures($misc_set, $db_type);
}


sub _get_SO_terms {
  my ($self) = @_;
  my $c = $self->context();
  my $so_term = $c->request->parameters->{so_term};
  my $terms = (! defined $so_term)  ? []
                                    : (ref($so_term) eq 'ARRAY')
                                    ? $so_term
                                    : [$so_term];
  my @final_terms;
  foreach my $term (@{$terms}) {
    if($term =~ /^SO\:/) {
      my $ontology_term = $c->model('Lookup')->ontology_accession_to_OntologyTerm($term);
      if(!$ontology_term) {
        Catalyst::Exception->throw("The SO accession '${term}' could not be found in our ontology database");
      }
      if ($ontology_term->is_obsolete) {
        Catalyst::Exception->throw("The SO accession '${term}' is obsolete");
      }
      push(@final_terms, $ontology_term->name());
    }
    else {
      push(@final_terms, $term);
    }
  }
  return \@final_terms;
}

## look up variation set by short name
sub _get_VariationSet{
  my ($self) = @_;

  my $c =  $self->context;
  my $short_set_name = $c->request->parameters->{variant_set};

  ## check set exists
  my $vsa = $c->model('Registry')->get_adaptor($c->stash->{species}, 'variation', 'variationset');
  my $set = $vsa->fetch_by_short_name($short_set_name);

  if(!ref($set) || !$set->isa('Bio::EnsEMBL::Variation::VariationSet')) {
    Catalyst::Exception->throw("No VariationSet found with short name: $short_set_name");
  }
  return $set;
}

sub _get_logic_dbtype {
  my ($self) = @_;
  my $c = $self->context();
  my $logic_name = $c->request->parameters->{logic_name};
  my $db_type = $c->request->parameters->{db_type};
  return ($logic_name, $db_type);
}

sub _trim_features {
  my ($self, $features) = @_;
  my $c = $self->context();
  my ($trim_upstream, $trim_downstream) =
    ($c->request->parameters->{trim_upstream},
     $c->request->parameters->{trim_downstream});

  # skip if not interested in trimming
  return $features
    unless $trim_upstream or $trim_downstream;

  my $filtered_features;
  my $slice = $c->stash()->{slice};
  my ($sstart, $send, $strand) =
    ($slice->start, $slice->end, $slice->strand);
  my $circular = $slice->is_circular();

  foreach my $feature (@{$features}) {
    my $trim = 0;
    my ($start, $end) =
      ($feature->seq_region_start,
       $feature->seq_region_end);

    # customosised checks in case of
    # circular chrmosomes
    next if $circular and
      $self->has_to_be_trimmed_in_circ_chr($feature,
					   $trim_upstream,
					   $trim_downstream);

    if ($trim_upstream and $trim_downstream) {
      next if $start < $sstart or $end > $send;
    } elsif ($trim_upstream) {
      if ($strand == 1) {
	next if $start < $sstart;
      } else {
	next if $end > $send;
      }
    } elsif ($trim_downstream) {
      if ($strand == 1) {
	next if $end > $send;
      } else {
	next if $start < $sstart;
      }
    }

    push @{$filtered_features}, $feature;
  }

  return $filtered_features;
}

sub _has_to_be_trimmed_in_circ_chr {
  my ($self, $feature, $trim_upstream, $trim_downstream) = @_;

  my $slice = $self->context()->stash()->{slice};

  my ($sstart, $send, $strand) =
    ($slice->start, $slice->end, $slice->strand);
  my $seq_region_len = $slice->seq_region_length();

  my ($seq_region_start, $seq_region_end) =
    ($feature->seq_region_start,
     $feature->seq_region_end);

  my $trim = 0;
  my ($start, $end);

  if ($strand == 1) { # Positive strand
    $start = $seq_region_start - $sstart + 1;
    $end   = $seq_region_end - $sstart + 1;

    #
    # TODO
    # can be optimised, assumed already the chromosome is know to be circular
    #
    if ($slice->is_circular()) {
      # Handle cicular chromosomes.

      if ($start > $end) {
	# Looking at a feature overlapping the chromsome origin.
	if ($end > $sstart) {
	  # Looking at the region in the beginning of the chromosome.
	  $start -= $seq_region_len;
	}

	$end += $seq_region_len if $end < 0;
      } else {
	if ($sstart > $send && $end < 0) {
	  # Looking at the region overlapping the chromosome
	  # origin and a feature which is at the beginning of the
	  # chromosome.
	  $start += $seq_region_len;
	  $end   += $seq_region_len;
	}
      }
    }

  } else { # Negative strand
    $start = $send - $seq_region_end + 1;
    $end = $send - $seq_region_start + 1;

    if ($slice->is_circular()) {
      if ($sstart > $send) { # slice spans origin or replication
	if ($seq_region_start >= $sstart) {
	  $end += $seq_region_len;
	  $start += $seq_region_len
	    if $seq_region_end > $sstart;

	} elsif ($seq_region_start <= $send) {
	  # do nothing
	} elsif ($seq_region_end >= $sstart) {
	  $start += $seq_region_len;
	  $end += $seq_region_len;

	} elsif ($seq_region_end <= $send) {
	  $end += $seq_region_len
	    if $end < 0;

	} elsif ($seq_region_start > $seq_region_end) {
	  $end += $seq_region_len;

	} else { }
      } else {
	if ($seq_region_start <= $send and $seq_region_end >= $sstart) {
	  # do nothing
	} elsif ($seq_region_start > $seq_region_end) {
	  if ($seq_region_start <= $send) {
	    $start -= $seq_region_len;

	  } elsif ($seq_region_end >= $sstart) {
	    $end += $seq_region_len;
	  } else { }
	}
      }

    }
  }

  if ($trim_upstream and $trim_downstream) {
    $trim = 1 if $start < 0 or $end > 0;
  } elsif ($trim_upstream) {
    if ($strand == 1) {
      $trim = 1 if $start < $0;
    } else {
      $trim = 1 if $end > $0;
    }
  } elsif ($trim_downstream) {
    if ($strand == 1) {
      $trim = 1 if $end > $0;
    } else {
      $trim = 1 if $start < $0;
    }
  }

  return $trim;
}

no warnings 'redefine';

sub Bio::EnsEMBL::Feature::summary_as_hash {
  my $self = shift;
  my %summary;
  $summary{'id'} = $self->display_id;
  $summary{'version'} = $self->version() if $self->version();
  $summary{'start'} = $self->seq_region_start;
  $summary{'end'} = $self->seq_region_end;
  $summary{'strand'} = $self->strand;
  $summary{'seq_region_name'} = $self->seq_region_name;
  $summary{'assembly_name'} = $self->slice->coord_system->version() if $self->slice();
  return \%summary;
}

__PACKAGE__->meta->make_immutable;

1;
