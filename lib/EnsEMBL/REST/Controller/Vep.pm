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

package EnsEMBL::REST::Controller::Vep;
use Moose;
use Bio::EnsEMBL::Variation::VariationFeature;
use namespace::autoclean;
require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);
BEGIN { extends 'Catalyst::Controller::REST'; }

use Try::Tiny;
__PACKAGE__->config( 'map' => { 'text/javascript' => ['JSONP'] } );

sub get_species : Chained("/") PathPart("vep") CaptureArgs(1) {
    my ( $self, $c, $species ) = @_;
    $c->stash->{species} = $species;
    try {
        $c->stash( variation_adaptor => $c->model('Registry')->get_adaptor( $species, 'Variation', 'Variation' ) );
        $c->stash(
          variation_feature_adaptor => $c->model('Registry')->get_adaptor( $species, 'Variation', 'VariationFeature' ) );
        $c->stash(
          structural_variation_feature_adaptor => $c->model('Registry')->get_adaptor( $species, 'Variation', 'StructuralVariationFeature' )
        );
    } catch {
        $c->go('ReturnError', 'from_ensembl', [$_]);
    };
}

sub get_bp_slice : Chained("get_species") PathPart("") CaptureArgs(1) {
    my ( $self, $c, $region ) = @_;
    my ($sr_name) = $c->model('Lookup')->decode_region( $region, 1, 1 );
    $c->model('Lookup')->find_slice( $sr_name );
}

sub get_rs_variations : Chained('get_species') PathPart('id') CaptureArgs(1) {
    my ( $self, $c, $rs_id ) = @_;
    my $v = $c->stash()->{variation_adaptor}->fetch_by_name($rs_id);
    $c->go( 'ReturnError', 'custom', [qq{No variation found for RS ID $rs_id}] ) unless $v;
    my $vfs = $c->stash()->{variation_feature_adaptor}->fetch_all_by_Variation($v);
    $c->stash( variation => $v, variation_features => $vfs );
}

sub my_chr_region : Chained("get_species") PathPart("chr_region") {
    my ( $self, $c ) = @_;
    $c->go( 'ReturnError', 'custom',
        [qq{/chr_region/ in uri is deprecated. See http://beta.rest.ensembl.org/info/vep for new format}] );
}

sub get_allele : Chained('get_bp_slice') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $allele ) = @_;
    my $s = $c->stash();
    if ( $allele !~ /^[ATGC-]+$/i && $allele !~ /INS|DUP|DEL|TDUP/i ) {
        my $error_msg = qq{Allele must be A,T,G, C, INS, DUP, TDUP or DEL [got: $allele]};
        $c->go( 'ReturnError', 'custom', [$error_msg] );
    }
    
    my $allele_string;
    
    if($allele =~ /INS|DUP|DEL|TDUP/i) {
      $allele_string = $allele;
    }
    else {
      my $reference_base;
      try {
          $reference_base = $s->{slice}->subseq( $s->{start}, $s->{end}, $s->{strand} );
          $s->{reference_base} = $reference_base;
      }
      catch {
          $c->log->fatal(qq{can't get reference base from slice});
          $c->go( 'ReturnError', 'from_ensembl', [$_] );
      };
      $c->go( 'ReturnError', 'custom', ["request for for consequence of [$allele] matches reference [$reference_base]"] )
        if $reference_base eq $allele;
      $allele_string = $reference_base . '/' . $allele;
    }
    $s->{allele_string} = $allele_string;
    $s->{allele}        = $allele;
}

sub get_consequences : Chained('get_allele') PathPart('consequences') Args(0) ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub get_consequences_GET {
    my ( $self, $c ) = @_;
    $c->forward('build_feature');
    $self->status_ok( $c, entity => { data => $c->stash->{consequences} } );
}

sub get_rs_consequences : Chained('get_rs_variations') PathPart('consequences') Args(0) ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub get_rs_consequences_GET {
    my ( $self, $c ) = @_;
    $c->forward('calc_consequences');
    $self->status_ok( $c, entity => { data => $c->stash->{consequences} } );
}

sub build_feature : Private {
    my ( $self, $c ) = @_;
    my $s  = $c->stash();
    
    my $vf;
    
    # build a StructuralVariationFeature
    if($s->{allele_string} !~ /\//) {
      
      # convert to SO term
      my $allele_string = $s->{allele_string};
      
      my %terms = (
          INS  => 'insertion',
          DEL  => 'deletion',
          TDUP => 'tandem_duplication',
          DUP  => 'duplication'
      );
      
      my $so_term = defined $terms{$allele_string} ? $terms{$allele_string} : $allele_string;
      
      $vf = try {
        Bio::EnsEMBL::Variation::StructuralVariationFeature->new(
          -start          => $s->{start},
          -end            => $s->{end},
          -strand         => $s->{strand},
          -class_SO_term  => $so_term,
          -slice          => $s->{slice},
          -adaptor        => $s->{structural_variation_feature_adaptor},
        );
      }
      catch {
        $c->log->fatal(qq{problem making Bio::EnsEMBL::Variation::StructuralVariationFeature object});
        $c->go( 'ReturnError', 'from_ensembl', [$_] );
      };
    }
    
    # build a VariationFeature
    else {
      $vf = try {
        Bio::EnsEMBL::Variation::VariationFeature->new(
          -start         => $s->{start},
          -end           => $s->{end},
          -strand        => $s->{strand},
          -allele_string => $s->{allele_string},
          -slice         => $s->{slice},
          -adaptor       => $s->{variation_feature_adaptor},
        );
      }
      catch {
        $c->log->fatal(qq{problem making Bio::EnsEMBL::Variation::VariationFeature object});
        $c->go( 'ReturnError', 'from_ensembl', [$_] );
      };
    }
    
    $s->{variation_features} = [$vf];
    $c->forward('calc_consequences');
    $self->status_ok( $c, entity => { data => $c->stash->{consequences} } );
}

sub calc_consequences : Private {
  my ( $self, $c ) = @_;
  my $s = $c->stash();

  my @all_results;
  my $vfs = $s->{variation_features};

  while ( my $vf = shift @{$vfs} ) {
    my $r = {
      location => {
        start        => ($vf->start()+0),
        end          => ($vf->end()+0),
        strand       => ($vf->strand()+0),
        name         => $vf->slice()->seq_region_name(),
        coord_system => $vf->slice()->coord_system()->name(),
      }
    };
    
    $r->{hgvs} = $vf->get_all_hgvs_notations if $vf->can('get_all_hgvs_notations');
    
    my $master_variant = $vf->can('variation') ? $vf->variation() : undef;
    if($master_variant) {
      $r->{name} = $master_variant->name();
      $r->{is_somatic} = ($master_variant->is_somatic() ? 1 : 0);
    }
    
    my $transcript_variants = $self->_encode_transcript_variants($c, $vf);
    my $regulatory_variants = $self->_encode_regulatory_variants($c, $vf);
    my $motif_variants = $self->_encode_motif_variants($c, $vf);
    
    $r->{transcripts} = $transcript_variants if @{$transcript_variants};
    $r->{regulatory} = $regulatory_variants if @{$regulatory_variants};
    $r->{motifs} = $motif_variants if @{$motif_variants};
    push(@all_results, $r);
  }

  $s->{consequences} = \@all_results;
}

my @NUMERIC_T_KEYS = qw/cdna_start cdna_end cds_start cds_end translation_start translation_end codon_position/;
my @NUMERIC_TVA_KEYS = qw/polyphen_score sift_score/;
sub _encode_transcript_variants {
  my ($self, $c, $vf) = @_;
  return $self->_process_variants($c, $vf, 'TranscriptVariations', sub {
    my ($tvs) = @_;
    my @results;
    foreach my $tv (@{$tvs}) {
      my $transcript = $tv->transcript();
      my $translation = $transcript->translation();
      my $gene = $transcript->get_Gene();
    
      my ($ccds) = grep { $_->database eq 'CCDS' } @{ $transcript->get_all_DBEntries };
      my @protein_features = map { { name => $_->hseqname(), db => $_->analysis->display_label }  } @{$tv->get_overlapping_ProteinFeatures()};
    
      my $r = {
        gene_id => $gene->stable_id(),
        transcript_id => $transcript->stable_id(),
        name => $gene->external_name(),
        biotype => $transcript->biotype(),
        is_canonical => ($transcript->is_canonical ? 1 : 0),
        
        cdna_start => $tv->cdna_start,
        cdna_end => $tv->cdna_end,
        cds_start => $tv->cds_start,
        cds_end => $tv->cds_end,
        translation_start => $tv->translation_start,
        translation_end => $tv->translation_end,
        intron_number => $tv->intron_number,
        exon_number => $tv->exon_number,
      };
      
      # may or may not be available
      for(qw(cdna_allele_string codon_position)) {
        $r->{$_} = $tv->$_ if $tv->can($_);
      }
      
      foreach my $key (@NUMERIC_T_KEYS) {
        my $v = $r->{$key};
        $r->{$key} = $v*1 if defined $v;
      }
      $r->{ccds} = $ccds->display_id if $ccds;
      $r->{translation_stable_id} = $translation->stable_id() if $translation;
      $r->{protein_features} = \@protein_features if @protein_features;

      #### START OF ALTERNATIVE ALLELES
      foreach my $tva (@{$tv->get_all_alternate_BaseVariationFeatureOverlapAlleles()}) {
        my $tva_r = {
          consequence_terms => $self->_overlap_consequences($tva),
          allele_string => $tva->can('allele_string') ? $tva->allele_string : $vf->class_SO_term
        };
        
        # may or may not be available
        $self->_add_fields($tva, $tva_r, qw(
          display_codon_allele_string
          codon_allele_string
          pep_allele_string
          polyphen_prediction
          polyphen_score
          sift_prediction
          sift_score
          hgvs_transcript
          hgvs_protein
        ));
        
        foreach my $key (@NUMERIC_TVA_KEYS) {
          my $v = $tva_r->{$key};
          $tva_r->{$key} = $v*1 if defined $v;
        }
        push @{$r->{alleles}}, $tva_r;
      }
    
      push(@results, $r);
    }
    return \@results;
  });
}

sub _encode_regulatory_variants {
  my ($self, $c, $vf) = @_;
  return $self->_process_variants($c, $vf, 'RegulatoryFeatureVariations', sub {
    my ($rfvs) = @_;
    my @results;
    foreach my $rfv (@{$rfvs}) {
      my $regulatory_feature = $rfv->feature;
      my $r = { 
        regulatory_feature_id => $regulatory_feature->stable_id,
        type => $regulatory_feature->feature_type->name,
      };
      foreach my $rfva (@{$rfv->get_all_alternate_BaseVariationFeatureOverlapAlleles()}) {
        my $rfva_r = {
          consequence_terms => $self->_overlap_consequences($rfva),
          is_reference => ($rfva->is_reference() ? 1 : 0),
          allele_string => $rfva->can('allele_string') ? $rfva->allele_string : $vf->class_SO_term
        };
        
        push @{$r->{alleles}}, $rfva_r;
      }
      push(@results, $r);
    }
    return \@results;
  });
}

sub _encode_motif_variants {
  my ($self, $c, $vf) = @_;
  return $self->_process_variants($c, $vf, 'MotifFeatureVariations', sub {
    my ($mfvs) = @_;
    my @results;
    foreach my $mfv (@{$mfvs}) {
      my $r = {
        type => $mfv->motif_feature->binding_matrix->feature_type->name,
      };
      
      if($vf->isa('Bio::EnsEMBL::Variation::VariationFeature')) {
        foreach my $mfva (@{$mfv->get_all_alternate_MotifFeatureVariationAlleles()}) {
          my $terms = $self->_overlap_consequences($mfva);
          my $allele = ($mfv->get_reference_BaseVariationFeatureOverlapAllele->feature_seq . '/' . $mfva->feature_seq);
          my $ra = { 
            allele_string => $allele,
            consequence_terms => $terms,
            is_reference => ($mfva->is_reference() ? 1 : 0),
            position => ($mfva->motif_start()*1),
          };
          my $delta = $mfva->motif_score_delta if $mfva->variation_feature_seq =~ /^[ACGT]+$/;
          $ra->{motif_score_change} = sprintf( "%.3f", $delta ) if defined $delta;
          $ra->{high_information_position} = ( $mfva->in_informative_position ? 1 : 0 );
          push @{$r->{alleles}} , $ra;
        }
      }
      push(@results, $r);
    }
    return \@results;
  });
}

sub _overlap_consequences {
  my ($self, $v) = @_;
  return [map { $_->SO_term } @{ $v->get_all_OverlapConsequences }];
}

sub _process_variants {
  my ($self, $c, $vf, $type, $callback) = @_;
  
  if($vf->isa('Bio::EnsEMBL::Variation::StructuralVariationFeature')) {
    $type =~ s/Variation/StructuralVariation/;
  }
  
  my $method = "get_all_$type";
  my $variations = try { 
    my $can = $vf->can($method);
    $can->($vf);
  }
  catch {
      $c->log->fatal(qq{problem fetching $type: $_});
      $c->go('ReturnError', 'from_ensembl', [$_] );
  };
  return $callback->($variations);
}

sub _add_fields {
  my ($self, $source, $target, @list) = @_;
  
  for(@list) {
    $target->{$_} = $source->$_ if $source->can($_);
  }
}

__PACKAGE__->meta->make_immutable;

