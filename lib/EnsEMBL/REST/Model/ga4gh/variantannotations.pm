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

package EnsEMBL::REST::Model::ga4gh::variantannotations;

use Moose;
extends 'Catalyst::Model';
use Catalyst::Exception;

use Bio::DB::Fasta;
use Bio::EnsEMBL::Variation::VariationFeature;
use Bio::EnsEMBL::Variation::DBSQL::VariationFeatureAdaptor;
use EnsEMBL::REST::Model::ga4gh::ga4gh_utils;
use Time::HiRes qw(gettimeofday);
use Data::Dumper;
use Scalar::Util qw/weaken/;
with 'Catalyst::Component::InstancePerContext';

has 'context' => (is => 'ro');

 
sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  weaken($c);
  return $self->new({ context => $c, %$self, @args });
}

sub searchVariantAnnotations {
 
  my ($self, $data ) = @_;

  $data->{species} = 'homo_sapiens'; 
  ## format look up lists if any specified
  $data->{required_features} = $self->extractRequired( $data->{featureIds}, 'features') if $data->{featureIds}->[0];
  $data->{required_effects}  = $self->extractRequired( $data->{effects}, 'SO' )          if $data->{effects}->[0];

  if ( $data->{variantAnnotationSetId} =~/compliance/){
    return $self->searchVariantAnnotations_compliance($data);
  }
  else{

    ## extract analysis date from variation database
    $data->{timestamp} = $self->get_timestamp();

    return $self->searchVariantAnnotations_database($data);
  }
}

sub searchVariantAnnotations_database {

  my ($self, $data ) = @_;

  ## annotation set id = Ensembl.version
  $data->{current_version} = $self->getEnsemblVersion($data);
  $data->{current_set} = 'Ensembl.' . $data->{current_version}; 

  Catalyst::Exception->throw( " No annotations available for this set: " . $data->{variantAnnotationSetId} )
    if defined $data->{variantAnnotationSetId}  && $data->{variantAnnotationSetId} ne $data->{current_set} && $data->{variantAnnotationSetId} ne 'Ensembl'; 


  ## loop over features if supplied
  return $self->searchVariantAnnotations_by_features( $data)
    if exists $data->{featureIds}->[0];

  ## search by region otherwise
  return $self->searchVariantAnnotations_by_region( $data)
    if exists $data->{start};

  warn "uncaught error in searchVariantAnnotations\n";

}


## get annotation by list of features
sub searchVariantAnnotations_by_features {

  my ($self, $data ) = @_;

  my @annotations;
  my $nextPageToken;

  my $c = $self->context();
 
  my $tra = $c->model('Registry')->get_adaptor($data->{species}, 'Core',      'Transcript');
  my $tva = $c->model('Registry')->get_adaptor($data->{species}, 'variation', 'TranscriptVariation');



  ## paging
  my $running_total = 0;

  my ($current_trans, $next_pos);
  my $ok_trans = 1;
  if (exists $data->{pageToken}){
     ($current_trans, $next_pos) = split/\_/, $data->{pageToken}; 
     $ok_trans = 0 ;
  }

  ## extract one transcripts worth at once for paging
  foreach my $req_feat ( @{$data->{featureIds}} ){

    $ok_trans = 1 if defined $current_trans && $req_feat eq $current_trans;
    next unless $ok_trans == 1;

    ## feature id is stable_id.version
    Catalyst::Exception->throw( " feature id $req_feat not recognised")
      unless $req_feat =~ /\./;

    my ($stable_id, $version) = split/\./,$req_feat;

    my $transcript = $tra->fetch_by_stable_id_version( $stable_id, $version );  
    Catalyst::Exception->throw( " feature $req_feat not found")
      if !$transcript;

    my $tvs;
    if(exists $data->{required_effects}){
      my @cons_terms = (keys %{$data->{required_effects} });

      my $constraint = " tv.consequence_types IN (";
      foreach my $cons(@cons_terms){ $constraint .= "\"$cons\",";}
      $constraint =~ s/\,$/\)/;
      $tvs = $tva->fetch_all_by_Transcripts_with_constraint([$transcript], $constraint );	
    }
    else{
      $tvs = $tva->fetch_all_by_Transcripts([$transcript]);
    }

    next unless scalar(@{$tvs}) > 0; 

    ## create an annotation record at the variation_feature level
    foreach my $tv (@{$tvs}){

      my $pos = $tv->variation_feature->seq_region_start();
      ## skip if already returned
      next if defined $next_pos && $pos < $next_pos;

      if($running_total == $data->{pageSize}){
        $nextPageToken = $req_feat . "_" . $pos;
        last;
      }

      my $var_ann;

      ## get consequences for each alt allele
      my $tvas = $tv->get_all_alternate_TranscriptVariationAlleles();
      foreach my $tva(@{$tvas}) {
        my $ga_annotation  = $self->formatTVA( $tva, $tv, $data->{required_effects} ) ;

        push @{$var_ann->{transcriptEffects}}, $ga_annotation if defined $ga_annotation->{featureId};

      }
      ## don't count or store until TV available
      next unless exists $var_ann->{transcriptEffects};

      $running_total++;
      $var_ann->{variantId} = $data->{current_version} .':'. $tv->variation_feature->variation_name();
      $var_ann->{variantAnnotationSetId} = $data->{current_set};
      $var_ann->{createDateTime} = $data->{timestamp};


      if( defined $tv->variation_feature->minor_allele() ) {    
        $var_ann->{info}  = {  "1KG_minor_allele"           =>  $tv->variation_feature->minor_allele(),
                               "1KG_minor_allele_frequency" =>  $tv->variation_feature->minor_allele_frequency()
                            };
      }
      else{ $var_ann->{info} = {};}
      ## Add ClinVar summary info
      my $clinsig = $tv->variation_feature->get_all_clinical_significance_states();
      $var_ann->{info}->{"ClinVar_classification"} = join(",",@{$clinsig}) if defined $clinsig->[0];

      push @annotations, $var_ann;
    }
  }


  ## may have no annotations if a transcript & consequence specified => return empty array
  return ({"variantAnnotations"  => \@annotations,
           "nextPageToken"       => $nextPageToken });
}



sub searchVariantAnnotations_by_region {

  my ($self, $data ) = @_; 

  my $c = $self->context(); 

  my $sla = $c->model('Registry')->get_adaptor($data->{species}, 'Core', 'Slice');

#  my $start = $data->{start};
# $start = $data->{pageToken} if defined $data->{pageToken};  
  my $start = (defined $data->{pageToken}? $data->{pageToken} : $data->{start});
  
  my $location = "$data->{referenceName}\:$start\-$data->{end}";
  my $slice = $sla->fetch_by_toplevel_location($location);

  Catalyst::Exception->throw("sequence  location: $location not available in this assembly") if !$slice;

  my ($annotations, $nextPageToken) =  $self->extractVFbySlice($data, $slice);

  return ({"variant_annotation"  => $annotations,
           "nextPageToken"       => $nextPageToken });
}

## get VF by slice and return appropriate number + next token 

sub extractVFbySlice{

  my $self  = shift;
  my $data  = shift;
  my $slice = shift;
  my $count = shift; ## handle multiple regions in one response. Is this a good idea?

  $count ||= 0;

  my @response;

  my $vfa = $self->context->model('Registry')->get_adaptor($data->{species}, 'Variation', 'VariationFeature');
  $vfa->db->include_failed_variations(0); ## don't extract multi-mapping variants

  my $vfs;
  if( exists $data->{required_effects}){

    my @cons_terms = (keys %{$data->{required_effects} });

    my $constraint; 
    foreach my $cons(@cons_terms){ 
      $constraint .= "vf.consequence_types like \"%$cons\%\" and ";}
      $constraint =~ s/and $//;

    $vfs = $vfa->fetch_all_by_Slice_constraint($slice, $constraint);
  }
  else{
     $vfs = $vfa->fetch_all_by_Slice($slice);
  }

  my $next_pos; ## save this for paging
  foreach my $vf(@{$vfs}){
     next unless $vf->{variation_name} =~/rs|COS/; ## Exclude non dbSNP/ COSMIC for now

    ## use next variant location as page token
    if ($count == $data->{pageSize}){
      $next_pos = $vf->seq_region_start();
      last;
    }

    ## filter by variant name if required
    next if defined $data->{variantName} && $vf->{variation_name} ne  $data->{variantName};

    ## extract & format - may not get a result if filtering applied
    my $var_an = $self->fetchByVF($vf, $data);
    if (exists $var_an->{variantId}){
      push @response, $var_an ;
      $count++;
    }
  }

  return ( \@response, $next_pos );

}

## extact and check annotation for a single variant

sub fetchByVF{

  my $self = shift;
  my $vf   = shift;
  my $data = shift;


  my $var_ann;
  $var_ann->{variantId}              = $data->{current_version} .':'. $vf->variation_name();
  $var_ann->{variantAnnotationSetId} = $data->{current_set};
  $var_ann->{created}                = $data->{timestamp};


  my $tvs =  $vf->get_all_TranscriptVariations();
  return undef unless scalar(@{$tvs} > 0);

  foreach my $tv (@{$tvs}){   

    ## check if a feature list was specified
    next if scalar @{$data->{featureIds}}>0 && !exists $data->{required_features}->{ $tv->transcript()->stable_id_version()} ; 

    my $tvas = $tv->get_all_alternate_TranscriptVariationAlleles();
    foreach my $tva(@{$tvas}) {

      my $ga_annotation  = $self->formatTVA( $tva, $tv, $data->{required_effects} ) ;
      push @{$var_ann->{transcriptEffects}}, $ga_annotation if defined $ga_annotation;
    }
  }

  return unless exists $var_ann->{transcriptEffects}->[0];

  ## add 1KG global MAF as illustrative info
  if( defined $vf->minor_allele() ) {
    $var_ann->{info}  = {  "1KG_minor_allele"           =>  $vf->minor_allele(),
                           "1KG_minor_allele_frequency" =>  $vf->minor_allele_frequency()
                        };
  }
  else{
    $var_ann->{info}  ={};
  }
  ## Add ClinVar summary info
  my $clinsig = $vf->get_all_clinical_significance_states();
  $var_ann->{info}->{"ClinVar_classification"} = join(",",@{$clinsig}) if defined $clinsig->[0];

  return $var_ann;
}


sub formatTVA{

  my $self = shift;
  my $tva  = shift;
  my $tv   = shift;
  my $effects = shift;

  my $ga_annotation;


  ## get consequences 
  my $ocs = $tva->get_all_OverlapConsequences();

  ## consequence filter
  my $found_required = 1;
  $found_required    = 0 if defined $effects;

  foreach my $oc(@{$ocs}) {
    my $term = $oc->SO_term();
    my $acc  = $oc->SO_accession();

    $found_required = 1 if $effects->{$term};
    my $ontolTerm = { id             => $acc,
                      term           => $term,
                      sourceName     => 'Sequence Ontology',
                      sourceVersion  => undef      
                     };

    push @{$ga_annotation->{effects}}, $ontolTerm;
  }

  ## consequence filter
  return undef unless $found_required == 1;

  $ga_annotation->{alternateBase}       = $tva->variation_feature_seq();

  ## do HGVS 
  $ga_annotation->{hgvsAnnotation}->{genomic}    = $tva->hgvs_genomic();
  $ga_annotation->{hgvsAnnotation}->{transcript} = $tva->hgvs_transcript() || undef;
  $ga_annotation->{hgvsAnnotation}->{protein}    = $tva->hgvs_protein()    || undef;

  $ga_annotation->{featureId} = $tv->transcript()->stable_id_version();
  $ga_annotation->{id} = $tv->dbID();


  my $cdna_start = $tv->cdna_start();
  if( defined $cdna_start ){
    $ga_annotation->{cDNALocation}->{referenceSequence} = undef;
    $ga_annotation->{cDNALocation}->{alternateSequence} = $tva->variation_feature_seq();
    $ga_annotation->{cDNALocation}->{start}   =   $cdna_start  - 1;
    $ga_annotation->{cDNALocation}->{end}     =   $tv->cdna_end() + 0 ;
  }
 
  my $codon = $tva->codon() ;
  if( defined $codon ){
    $ga_annotation->{CDSLocation}->{referenceSequence} = $tv->get_reference_TranscriptVariationAllele->codon();
    $ga_annotation->{CDSLocation}->{alternateSequence} = $codon;
    $ga_annotation->{CDSLocation}->{start}      = $tv->cds_start() -1;
    $ga_annotation->{CDSLocation}->{end}        = $tv->cds_end() + 0;
  }


  my $peptide =  $tva->peptide();
  if( defined $peptide ){
    $ga_annotation->{proteinLocation}->{referenceSequence} = $tv->get_reference_TranscriptVariationAllele->peptide();
    $ga_annotation->{proteinLocation}->{alternateSequence} = $peptide;
    $ga_annotation->{proteinLocation}->{start}      = $tv->translation_start() - 1;
    $ga_annotation->{proteinLocation}->{end}        = $tv->translation_end() + 0;

    ## Extract protein impact information for missense variants
    my $protein_impact = $self->protein_impact($tva); 
    $ga_annotation->{analysisResults} = $protein_impact if @{$protein_impact} >0; 
  }

  return $ga_annotation;
}



## extract & format sift and polyphen results
sub protein_impact{

  my $self = shift; 
  my $tva  = shift;

  my @analysisResults;

  my $sift_analysis;
  $sift_analysis->{result} = $tva->sift_prediction();
  $sift_analysis->{score}  = $tva->sift_score();
 
  if (defined $sift_analysis->{result}){
    ## TODO: define better id!
    $sift_analysis->{analysisId}    = 'SIFT.5.2.2';
    push @analysisResults , $sift_analysis;
  }    
      
  my $polyphen_analysis;
  $polyphen_analysis->{result} = $tva->polyphen_prediction();
  $polyphen_analysis->{score}  = $tva->polyphen_score();

  if (defined $polyphen_analysis->{result}){
    ## TODO: define better id!
    $polyphen_analysis->{analysisId}     = 'Polyphen.2.2.2_r405';
    push @analysisResults , $polyphen_analysis;
  }

  return \@analysisResults ;
}


## put required features ids/ SO accessions in a hash for look up

sub extractRequired{

  my $self     = shift;
  my $req_list = shift;
  my $type     = shift;
  my $req_hash;

  foreach my $required ( @{$req_list} ){
    $req_hash->{$required}         = 1 if $type eq 'features';
    $req_hash->{$required->{term}} = 1 if $type eq 'SO';
  }

  return $req_hash;
}

## create temp feature set name from curent db version
## replace with GA4GH id when format available

sub getEnsemblVersion{

  my $self = shift;
  my $data = shift;

  my $var_ad   = $self->context->model('Registry')->get_DBAdaptor('homo_sapiens', 'variation');
  my $var_meta = $var_ad->get_MetaContainer();

  return $var_meta->schema_version() ;
}

sub searchVariantAnnotations_compliance{

  my $self = shift;
  my $data = shift;

  my $variantSetId = (split/\:/,  $data->{variantAnnotationSetId})[1];

  ##VCF collection object for the compliance annotation set
  $data->{vcf_collection} =  $self->context->model('ga4gh::ga4gh_utils')->fetch_VCFcollection_by_id( $variantSetId );
  Catalyst::Exception->throw(" Failed to find the specified variantAnnotationSetId")
    unless defined $data->{vcf_collection}; 

  ## look up filename from vcf collection object
  my $file  =  $data->{vcf_collection}->filename_template();

  $file =~ s/\#\#\#CHR\#\#\#/$data->{referenceName}/;

  # return these ordered by position for simple pagination
  my @var_ann;
  my $nextPageToken;
  ## VCF is 1-based; GA4GH is 0-based & open-closed 
  $data->{end}++;
  $data->{pageToken} = $data->{start} unless defined $data->{pageToken}  && $data->{pageToken}  =~/\d+/;

  ## exits here if unsupported chromosome requested
  return (\@var_ann, $nextPageToken) unless -e $file;
 
  my $parser = Bio::EnsEMBL::IO::Parser::VCF4Tabix->open( $file ) || die "Failed to get parser : $!\n";

  my $keys = $parser->get_metadata_key_list();
 
  ## find column headers
  my $meta = $parser->get_metadata_by_pragma("INFO");
  my @headers;

  foreach my $m(@{$meta}){
    next unless $m->{Description} =~/Functional annotations/;
    my $headers = (split/\'/, $m->{Description})[1]; 
    @headers = split/\|/, $headers;
  }

  ## need to supply SO accessions
  my $ont_ad   = $self->context->model('Registry')->get_adaptor('Multi', 'Ontology', 'OntologyTerm');

  $parser->seek($data->{referenceName}, $data->{pageToken}, $data->{end});

  my $n = 0;

  while($n < ($data->{pageSize} + 1)){

    my $got_something = $parser->next();
    last if $got_something ==0;

    my $name = $parser->get_IDs->[0];

    if ($n == $data->{pageSize} ){
      ## batch complete 
      ## save next position for new page token
      $nextPageToken = $parser->get_raw_start -1;
      last;
    }

    my $variation_hash;
    $name = $parser->get_seqname ."_". $parser->get_raw_start if $name eq "." ; ## create placeholder name 
    $variation_hash->{id}                      = $data->{variantAnnotationSetId} .":". $variantSetId .":".$name; 
    $variation_hash->{variantAnnotationSetId}  = $data->{variantAnnotationSetId};
    $variation_hash->{variantId}               = $variantSetId .":".$name;

    $variation_hash->{created}                 = $data->{vcf_collection}->created || undef;
    $variation_hash->{updated}                 = $data->{vcf_collection}->updated || undef; 


    ## format array of transcriptEffects
    my $var_info = $parser->get_info();

    ## could be multi-allelic
    my %hgvsg;
    my @hgvsg = split/\,/, $var_info->{"HGVS.g"};
    my @alts  = @{$parser->get_alternatives};
    for (my $n=0; $n < scalar @hgvsg; $n++){ 
      $hgvsg{$alts[$n]} = $hgvsg[$n];
    }

    my @effects = split/\,/, $var_info->{ANN};
    foreach my $effect (@effects){

      my @annot = split/\|/, $effect;
      my %annotation;

      for (my $an =0; $an < scalar @annot; $an++ ){
        ## add filter for feature name if required
        $headers[$an] =~ s/^\s+|\s+$//g;
        $annotation{$headers[$an]} = $annot[$an] if defined $annot[$an];
      }

      ## check if a consequence list was specified that this consequence is required
      next if scalar @{$data->{effects}}>0 && !exists $data->{required_effects}->{ $annotation{Annotation} } ;

      ## check if a feature list was specified that this feature is required
      next if scalar @{$data->{featureIds}}>0 && !exists $data->{required_features}->{ $annotation{Feature_ID} } ;

      my ($cdna_pos, $cdna_length ) = split /\//, $annotation{"cDNA.pos / cDNA.length"} 
        if defined $annotation{"cDNA.pos / cDNA.length"}; 

      my ($cds_pos, $cds_length )   = split /\//, $annotation{"CDS.pos / CDS.length"}
        if defined $annotation{"CDS.pos / CDS.length"} ;

      my ($aa_pos, $aa_length )     = split /\//, $annotation{"AA.pos / AA.length"}
        if defined $annotation{"AA.pos / AA.length"};

      my $id;
      my $ontology_terms = $ont_ad->fetch_all_by_name($annotation{Annotation}, 'SO');
      $id = $ontology_terms->[0]->accession() if defined $ontology_terms->[0];

      my $transcriptEffect = { id              => "placeholder",
                               featureId       => $annotation{Feature_ID},
                               alternateBases  => $annotation{Allele}, 
                               effects         => [{ id            => $id,
                                                    term           => $annotation{Annotation},
                                                    sourceName     => 'Sequence Ontology',
                                                    sourceVersion  => ''
                                                  }], 
                               hgvsAnnotation  => { genomic    => $hgvsg{$annotation{Allele}} || undef,
                                                    transcript => $annotation{"HGVS.c"} || undef,
                                                    protein    => $annotation{"HGVS.p"} || undef },
                               cDNALocation    => {},
                               CDSLocation     => {},
                               proteinLocation => {},
                               analysisResults => []
                             };

    $cdna_pos-- if defined $cdna_pos; 
    $transcriptEffect->{cDNALocation} = { start      => $cdna_pos || undef,
                                          end        => undef,
                                          referenceSequence => undef,
                                          alternateSequence => undef,
                                        }; 

    $cds_pos--;
    $transcriptEffect->{CDSLocation}   = { start      => $cds_pos || undef ,
                                           end        => undef,
                                           referenceSequence => undef,
                                           alternateSequence => undef,
                                         } ;

    $aa_pos--;
    $transcriptEffect->{proteinLocation} =  { start      => $aa_pos ||undef,
                                              end        => undef,
                                              referenceSequence => undef,
                                              alternateSequence => undef,
                                             } ;

      push @{$variation_hash->{transcriptEffects}}, $transcriptEffect;
    } 
    ## save if not filtered out & increment batchsize
    if ( exists $variation_hash->{transcriptEffects}->[0]){
      $n++;
      push @var_ann, $variation_hash;
    }
  }

  $parser->close();

  return ( {"variantAnnotations"  => \@var_ann,
            "nextPageToken"       => $nextPageToken });
}

## extract analysis date from variation database
sub get_timestamp{

  my $self = shift;
  my $var_ad   = $self->context->model('Registry')->get_DBAdaptor('homo_sapiens', 'variation');
  my $meta_ext_sth = $var_ad->dbc->db_handle->prepare(qq[ select meta_value from meta where meta_key = 'tv.timestamp']);
  $meta_ext_sth->execute();
  my $timestamp = $meta_ext_sth->fetchall_arrayref();
  return $timestamp->[0]->[0];

}

1;
