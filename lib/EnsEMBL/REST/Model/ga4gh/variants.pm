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

package EnsEMBL::REST::Model::ga4gh::variants;

use Moose;
extends 'Catalyst::Model';

use Bio::EnsEMBL::IO::Parser::VCF4Tabix;
use Bio::EnsEMBL::Variation::DBSQL::VCFCollectionAdaptor;

with 'Catalyst::Component::InstancePerContext';

has 'context' => (is => 'ro');


sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  return $self->new({ context => $c, %$self, @args });
}

sub fetch_gavariant {

  my ($self, $data ) = @_; 

  ## load callSet to variantSet link 
  $data = $self->get_set_info($data);

  ## exclude samples outside specified variantSet and variantSet with no required samples
  $data = $self->check_sample_info($data) if defined $data->{callSetIds}->[0] ;

  ## get variation data - pull out set by region & filter on variant name if supplied
  return $self->fetch_by_region($data);

}

## link sample names to variantSet for later filtering
sub get_set_info{

  my ($self, $data ) = @_;

  ## extract required variantSets if supplied
  if(defined $data->{variantSetIds}->[0] && $data->{variantSetIds}->[0] >0){  
    foreach my $set (@{$data->{variantSetIds}}){
      $data->{required_set}->{$set} = 1;
    }
  }

  ## extract required dataSets if supplied
  if(defined $data->{datasetIds}->[0] && $data->{datasetIds}->[0] >0){
    foreach my $dataset (@{$data->{datasetIds}}){
      $data->{required_dataset}->{$dataset} = 1;
    }
  }


  $Bio::EnsEMBL::Variation::DBSQL::VCFCollectionAdaptor::CONFIG_FILE = $self->{ga_config};
  my $vca = Bio::EnsEMBL::Variation::DBSQL::VCFCollectionAdaptor->new();

 
  foreach my $dataSet ( @{$vca->fetch_all} ){
    
    ## filter at dataSet level first if selection made
    next if defined $data->{datasetIds}->[0] && ! defined $data->{required_dataset}->{$dataSet->{id} } ;

    $dataSet->use_db(0);

    ## check reference name is supported
    my %avail_chr;
    foreach my $chr ( @{$dataSet->{chromosomes}} ){
      $avail_chr{$chr} = 1;
    }
    $self->context()->go( 'ReturnError', 'custom', [ " Failed to find the specified reference sequence"])
    unless defined $avail_chr{ $data->{referenceName} };

    ## derive required VCF file name/ location
    my $file = $dataSet->filename_template(); 
    $file =~ s/\#\#\#CHR\#\#\#/$data->{referenceName}/;

    ## loop over callSets
    $dataSet->{individual_populations} = $dataSet->{_raw_populations};
    foreach my $callset_id(keys %{$dataSet->{individual_populations}} ){

      my $variantSet_id = $dataSet->{individual_populations}->{$callset_id}->[0];

       ## limit by variant set if required
       next if defined $data->{variantSetIds}->[0] && ! defined $data->{required_set}->{$variantSet_id} ;

       ## save sample to variantSet link
       $data->{sample2set}->{$callset_id} = $dataSet->{individual_populations}->{$callset_id}->[0];

       ##if data is needed for this sample, save the file name       
       $data->{files}->{$dataSet->{id}} = $file;

     }
  }

  return $data;
}
  


## format sample names if filtering by sample required
## variantSet limitation takes presidence 
sub check_sample_info{

  my ($self, $data ) = @_;

  my %req_samples; ## store sample <-> variantSet link
  my %req_sets;    ## if samples are specified, don't look in sets not containing them

  foreach my $sample ( @{ $data->{callSetIds} } ){

   if (defined  $data->{sample2set}->{$sample}){ ## only set if set required or no set limit 
      $req_samples{$sample} = 1;
      $req_sets{ $data->{sample2set}->{$sample} } = 1;
    }
  }
 
  ## exit if the samples & sets are incompatible
  $self->context()->go( 'ReturnError', 'custom', [ " The specified callSets are not available in the specified variantSets"])
    unless scalar(keys %req_samples) >0;

  $data->{samples} = \%req_samples;

  ## reset variantSets to only those with samples
  $data->{required_set} = \%req_sets;
  
  return $data;
}


sub fetch_by_region{

  my $self = shift;
  my $data = shift;

  my $c = $self->context();

  ## if this is a new request set first token to start of region and set and dataset to 0  
  $data->{pageToken} = $data->{start} . "_0_0" unless exists  $data->{pageToken} && $data->{pageToken} =~/\d+/;


  ## get the next range of variation data for the token - should return slightly more than required
  my ($var_info, $current_dataset ) = $self->get_next_by_token($data);

  ## exit if none found
  $c->go( 'ReturnError', 'custom', [ " No variants are available for this region" ] )  
     unless defined $var_info && scalar(@{$var_info}) >0;
  
  ## get the correct number of GAvariants - returning by variantSet means 1var => many GAvar
  my @var_response;
  my $gavariant_count = 0;

  my $next_token;
  ## last reported position & setid
  my ($last_pos, $last_set, $curr_dataset ) = split/\_/,  $data->{pageToken} ;

  foreach my $ga_var( @{$var_info}){
   
    last if $gavariant_count == $data->{pageSize};
     
    ## last batch may have ended mid-variant - skip any which have been returned
    next if $ga_var->{start} == $last_pos &&  $ga_var->{variantSetId} <= $last_set;

    ## save var and count total
    $gavariant_count++;
    push @var_response, $ga_var;
      
    if($gavariant_count == $data->{pageSize}){
      ## set next token to position and set of last reported result  
      $next_token =  $ga_var->{start} ."_". $ga_var->{variantSetId} ."_" . $current_dataset ;
      last;
    }
  }

  return ({ "variants"      => \@var_response,
            "nextPageToken" => $next_token
          });
  
}


## extract genotypes & apply filtering
## input: array of strings - format : 'NA10000:0|1:44:23'
## output: hash with key: variantSetID and value: array of individual genotype hashes
sub sort_genotypes {
  my ($self, $geno_strings, $data) = @_;

  my %genotypes;

  foreach my $geno_string(@{$geno_strings}){

    my ($sample, $call, $qual) = split(/\:/,$geno_string,3);

    ## filter by individual if required
    next if defined $data->{callSetIds}->[0] && 
      !defined $data->{samples}->{$sample};

    my $gen_hash;
    $gen_hash->{callSetId}    = $sample;
    $gen_hash->{callSetName}  = $sample;

    my @g = split/\||\//, $call;
    foreach my $g(@g){
      ## force genotype to be numeric
      push @{$gen_hash->{genotype}}, $g*1;
    } 


    ## store genotypes by variationSetId
    if (defined $data->{sample2set}->{$sample}){
      push @{$genotypes{ $data->{sample2set}->{$sample}}}, $gen_hash 
    }
  }
  return \%genotypes;
}



## extract a batch of results for request and hold new start pos in token string
sub get_next_by_token{

  my ($self, $data) = @_;

  ## These are the last seq start and variantset and dataset reported
  my ($batch_start, $set_start, $dataset_start) = (split/\_/,$data->{pageToken});

  ## get one extra to see if it is worth sending new page token (only one set may be requested)
  my $limit = $data->{pageSize} + 1;

  ## reduce look up region to a size large enough to hold the requested number of variants??
  my $batch_end =  $data->{end};

  ## which data set are we paging through?
  my @datasetsreq = sort(keys %{$data->{files}});
  my $current_ds;
  foreach my $ds(@datasetsreq){

    if ($ds >= $dataset_start){
       $current_ds = $ds;
       last;
    }
  }
  
  return unless defined $current_ds;

  my $file = $self->{dir} .'/'. $data->{files}->{$current_ds};

  my $parser = Bio::EnsEMBL::IO::Parser::VCF4Tabix->open( $file ) || die "Failed to get parser : $!\n";
  $parser->seek($data->{referenceName},$batch_start,$batch_end);

  ## return these ordered by position & set id to allow pagination
  my @var;

  my $n = 0;


  while($n < $limit){
    
    $parser->next();
    my $name = $parser->get_IDs->[0];
    last unless defined $name ;
    ## add filter for variant name if require

    next if defined $data->{variantName} && $data->{variantName} =~/\w+/ &&  $data->{variantName} ne $name;

    my $raw_genotypes  = $parser->get_raw_individuals_info();
    ## extract arrays of genotypes by variantSet
    my $genotype_calls = $self->sort_genotypes($raw_genotypes, $data);

    my @sets_to_return; ## sort here for paging
    if(defined $data->{variantSetIds}->[0]){
      @sets_to_return = sort @{$data->{variantSetIds}};
    }
    else{
      @sets_to_return = sort (keys %{$genotype_calls});
    }
    ## loop over sets to divide up genotypes
    foreach my $set_required (@sets_to_return){

      ## check there are genotypes to return
      next unless exists $genotype_calls->{$set_required}->[0];

      $n++;
      my $variation_hash;

      $variation_hash->{variantSetId}    = $set_required;
      $variation_hash->{calls}           = $genotype_calls->{$set_required};

      $variation_hash->{name}            = $name;
      $variation_hash->{id}              = $name;
      $variation_hash->{referenceBases}  = $parser->get_reference;
      $variation_hash->{alternateBases}  = \@{$parser->get_alternatives};
      $variation_hash->{referenceName}   = $parser->get_seqname ;

      ## position is zero-based + closed start of interval 
      $variation_hash->{start}           = $parser->get_raw_start -1;
      ## open end of interval
      $variation_hash->{end}             = $parser->get_raw_end;

      push @var, $variation_hash;
    }
   
    ## exit if single required variant already found
    last if defined $data->{variantName} && $data->{variantName} =~/\w+/;
  }

  if ($n ==0){
    ## may be nothing in the specified dataset - increment dataset id and re-send
    $data->{pageToken} = $batch_start ."_". $set_start ."_".  $current_ds;
    $self->get_next_by_token($data);
 }

  ## this should not happen
#  $self->context()->go('ReturnError', 'custom', ["No data found in the required region"]) if $n ==0;
  
  return (\@var,$current_ds) ;

}



with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;
