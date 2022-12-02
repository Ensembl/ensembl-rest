=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
Copyright [2016-2022] EMBL-European Bioinformatics Institute

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

package EnsEMBL::REST::Model::ga4gh::Beacon;

use Moose;
extends 'Catalyst::Model';
use Catalyst::Exception;
use List::MoreUtils qw(uniq);
use EnsEMBL::REST::Model::ga4gh::ga4gh_utils;
use Bio::EnsEMBL::Variation::Utils::Sequence qw(trim_sequences);

use Scalar::Util qw/weaken/;
with 'Catalyst::Component::InstancePerContext';

# SO terms for structural variants
# There's more than one term for each SV type - use a list of SO terms
# CNV =~ DEL or DUP
has 'sv_so_terms' => ( isa => 'HashRef', is => 'ro', lazy => 1, default => sub {
  return {
    'INS'    => ['insertion'],
    'INS:ME' => ['mobile_element_insertion'],
    'DEL'    => ['deletion'],
    'DEL:ME' => ['mobile_element_deletion'],
    'CNV'    => ['copy_number_variation','copy_number_gain','copy_number_loss','deletion','duplication'],
    'DUP'    => ['duplication'],
    'INV'    => ['inversion'],
    'DUP:TANDEM' => ['tandem_duplication']
  };
});

has 'context' => (is => 'ro',  weak_ref => 1);

# Info for the variation sets that are going to be created
has 'variation_sets_info' => ( isa => 'HashRef', is => 'ro', lazy => 1, default => sub {
  return {
    'dbsnp' => 'Variants (including SNPs and indels) imported from dbSNP',
    'dgva'  => 'Variants imported from the Database of Genomic Variants Archive',
    'dbvar' => 'Variants imported from the NCBI database of human genomic structural variation'
  };
});

our $valid_dataset_ids = {};

sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  weaken($c);
  return $self->new({ context => $c, %$self, @args });
}

# TODO - Only look up assembly once

# returns ga4gh Beacon
sub get_beacon {
  my ($self) = @_;
  my $beacon;

  # The Beacon identifier depends on the assembly requested
  my $db_meta = $self->context->model('ga4gh::ga4gh_utils')->fetch_db_meta();

  my $db_assembly = $self->get_assembly();
  my $schema_version = $db_meta->{schema_version} || '';

  # Unique identifier of the Beacon
  my $beacon_id = 'org.ensembl.rest';
  my $beacon_name = 'EBI - Ensembl';
  if ($db_assembly) {
    # beacon id for grch38 is 'org.ensembl.rest' and for grch37 is 'org.ensembl.rest.grch37'
    $beacon_id = $beacon_id . '.' . lc $db_assembly if($db_assembly eq 'GRCh37');
    $beacon_name = $beacon_name . ' ' . $db_assembly;
  }

  my $return_beacon;
  $return_beacon->{meta} = $self->get_beacon_meta($db_assembly, $schema_version, $beacon_id, $beacon_name);
  $return_beacon->{response} = $self->get_beacon_response($db_assembly, $beacon_id, $beacon_name);

  return $return_beacon;
}

# framework -> responses -> beaconInformationalResponseMeta
# returns the meta information of the Beacon
sub get_beacon_meta {
  my ($self, $db_assembly, $schema_version, $beacon_id, $beacon_name) = @_;

  my $meta;

  my $altURL = 'https://www.ensembl.org';
  if ($db_assembly eq 'GRCh37') {
    $altURL = 'https://grch37.ensembl.org';
  }

  $meta->{beaconId} = $beacon_id;

  $meta->{apiVersion} = 'v2.0.0';
  $meta->{description} = 'Human variant data from the Ensembl database';
  $meta->{version} = $schema_version;

  $meta->{alternativeUrl} = $altURL;
  $meta->{createDateTime} = undef;
  $meta->{updateDateTime} = undef;
  $meta->{testMode} = JSON::false;

  my @returned_schemas;
  push (@returned_schemas, {entityType => 'info', schema => ''}); # add schema
  $meta->{returnedSchemas} = \@returned_schemas;

  return $meta;
}

sub get_meta {
  my ($self, $beacon_id) = @_;

  my $meta;

  $meta->{beaconId} = $beacon_id;
  $meta->{apiVersion} = 'v2.0.0';

  my @returned_schemas;
  push (@returned_schemas, {entityType => 'genomicVariant', schema => ''}); # add schema
  $meta->{returnedSchemas} = \@returned_schemas;

  $meta->{receivedRequestSummary}->{apiVersion} = 'v2.0.0';
  $meta->{receivedRequestSummary}->{requestedSchemas} = \@returned_schemas; # same as returnedSchemas (genomicVariant)
  $meta->{receivedRequestSummary}->{pagination}->{limit} = 0; # size of the page (default: 0). 0 returns all the results or the maximum allowed by the Beacon
  $meta->{receivedRequestSummary}->{pagination}->{skip} = 0; # number of pages to skip/skipped (default: 0)
  $meta->{receivedRequestSummary}->{requestedGranularity} = 'record';
  $meta->{createDateTime} = undef;
  $meta->{updateDateTime} = undef;
  $meta->{testMode} = JSON::false;
  $meta->{updateDateTime} = undef;
  $meta->{includeResultsetResponses} = undef;

  return $meta;
}

# framework -> responses -> beaconInfoResults
# returns the results info of the Beacon
sub get_beacon_response {
  my ($self, $db_assembly, $beacon_id, $beacon_name) = @_;

  my $response;

  my $welcomeURL = 'https://rest.ensembl.org';
  if ($db_assembly eq 'GRCh37') {
    $welcomeURL = 'https://grch37.rest.ensembl.org';
  }

  $response->{apiVersion} = 'v2.0.0';
  $response->{id} = $beacon_id;
  $response->{name} = $beacon_name;
  $response->{welcomeUrl} = $welcomeURL;
  $response->{organization} =  $self->get_beacon_organization();
  $response->{environment} = 'prod';

  return $response;
}

# returns ga4gh BeaconOrganization
sub get_beacon_organization {
  my ($self) = @_;

  my $organization;
 
  my $description = "The European Bioinformatics Institute (EMBL-EBI) is part of EMBL, an international, innovative "
                      . "and interdisciplinary research organisation funded by 26 member states and two associate member states "
                      . "to provide the infrastructure needed to share data openly in the life sciences.";

  my $address = "EMBL-EBI, Wellcome Genome Campus, Hinxton, Cambridgeshire, CB10 1SD, UK";

  my $welcomeURL = "https://www.ebi.ac.uk/";
  my $contactURL = "https://www.ebi.ac.uk/support/";
  
# TODO add URL to logo
  my $logoURL; 

  # Unique identifier of the organization
  $organization->{id} = "ebi";
  $organization->{name} = "EMBL European Bioinformatics Institute";
  $organization->{description} = $description;
  $organization->{address} = $address;
  $organization->{welcomeUrl} = $welcomeURL;
  $organization->{contactUrl} = $contactURL;
  $organization->{logoUrl} = $logoURL;
  $organization->{info} = undef;
  return $organization;
}

sub get_beacon_all_datasets {
  my ($self, @variation_set_list) = @_; 

  my @beacon_datasets;

  my $c = $self->context();
  my $db_meta = $c->model('ga4gh::ga4gh_utils')->fetch_db_meta();

  my $variation_set_adaptor = $c->model('Registry')->get_adaptor('homo_sapiens', 'variation', 'variationset');

  if(!@variation_set_list) {
    @variation_set_list = @{$variation_set_adaptor->fetch_all()};
  }

  # dbSNP is not a variation_set but we need this set for Beacon
  # That is why we need to create a fake set called 'dbSNP' using an id that is not being used in the variation db
  my $dbsnp_set = create_var_set($c, 'dbSNP', $self->variation_sets_info->{'dbsnp'}, 'dbsnp');
  push(@variation_set_list, $dbsnp_set);
  # Also create variation sets for structural variants
  # Variation sets: DGVa and dbVar
  my $dgva_set = create_var_set($c, 'DGVa', $self->variation_sets_info->{'dgva'}, 'dgva');
  my $dbvar_set = create_var_set($c, 'dbVar', $self->variation_sets_info->{'dbvar'}, 'dbvar');
  push(@variation_set_list, $dgva_set);
  push(@variation_set_list, $dbvar_set);

  foreach my $dataset (@variation_set_list) {
    my $beacon_dataset = $self->get_beacon_dataset($db_meta, $dataset);
    $valid_dataset_ids->{$beacon_dataset->{id}} = 1 if(defined $beacon_dataset->{id});
    push(@beacon_datasets, $beacon_dataset); 
  }

  return \@beacon_datasets;
}

# Get a VariationSet and return a Beacon Dataset 
sub get_beacon_dataset {
  my ($self, $db_meta, $dataset) = @_;

  my $beacon_dataset;

  my $db_assembly = $db_meta->{assembly};
  my $externalURL = 'https://www.ensembl.org';
  if ($db_assembly eq 'GRCh37') {
    $externalURL = 'https://grch37.ensembl.org';
  }

  $beacon_dataset->{id} = $dataset->short_name();
  $beacon_dataset->{name} = $dataset->name();
  $beacon_dataset->{description} = $dataset->description();
  $beacon_dataset->{externalUrl} = $externalURL;

  $beacon_dataset->{dataUseConditions}->{'id'} = 'DUO:0000004';
  $beacon_dataset->{dataUseConditions}->{'label'} = 'no restriction';

  return $beacon_dataset;
}


# Main method
#  check the parameters
#  get the request
#  check if variant exists
#  returns the main Beacon response
# In v2 response has three parts:
#  1 - meta
#    1.1 - returnedSchemas
#    1.2 - receivedRequestSummary
#  2 - response
#  3 - responseSummary
sub beacon_query {

  my ($self, $data) = @_;
  my $beaconAlleleResponse;
  my $beaconError;

  # Check assembly requested is assembly of DB
  my $db_assembly = $self->get_assembly();

  # Unique identifier of the Beacon
  my $beacon_id = 'org.ensembl.rest';
  if ($db_assembly) {
    # beacon id for grch38 is 'org.ensembl.rest' and for grch37 is 'org.ensembl.rest.grch37'
    $beacon_id = $beacon_id . '.' . lc $db_assembly if($db_assembly eq 'GRCh37');
  }

  $beaconAlleleResponse->{meta} = $self->get_meta($beacon_id);
  # 'meta -> receivedRequestSummary' can include the includeResultsetResponses
  # add includeResultsetResponses to meta
  if (exists $data->{includeResultsetResponses}) {
    $beaconAlleleResponse->{meta}->{receivedRequestSummary}->{includeResultsetResponses} = $data->{includeResultsetResponses};
    $beaconAlleleResponse->{meta}->{includeResultsetResponses} = $data->{includeResultsetResponses};
  }
  else {
    # return the default (HIT)
    $beaconAlleleResponse->{meta}->{receivedRequestSummary}->{includeResultsetResponses} = 'HIT';
    $beaconAlleleResponse->{meta}->{includeResultsetResponses} = 'HIT';
  }

  my $beacon = $self->get_beacon();
  my $all_datasets = $self->get_beacon_all_datasets();
  $beaconError = $self->check_parameters($data); 

  # includeResultsetResponses can be:
  # ALL returns all datasets even those that don't have the queried variant
  # HIT returns only datasets that have the queried variant (default)
  # MISS means opposite to HIT value, only datasets that don't have the queried variant
  # NONE don't return datasets response
  my $incl_ds_response = 2; # HIT is the default
  if (exists $data->{includeResultsetResponses}) {
    if (uc $data->{includeResultsetResponses} eq 'ALL') {
      $incl_ds_response = 1;
    }
    elsif (uc $data->{includeResultsetResponses} eq 'NONE') {
      $incl_ds_response = 0;
    }
    elsif (uc $data->{includeResultsetResponses} eq 'MISS') {
      $incl_ds_response = 3;
    }
  }

  # Check if there is dataset ids in the input
  # Get list of dataset ids
  my @dataset_ids_list;

  if (exists $data->{datasetIds}) {
    @dataset_ids_list = split(',', $data->{datasetIds});
    $beaconAlleleResponse->{meta}->{receivedRequestSummary}->{datasetIds} = \@dataset_ids_list; 
  }

  $beaconAlleleResponse->{error} = $beaconError if($beaconError);
  $beaconAlleleResponse->{response}->{resultSets} = undef;

  my $response_summary;
  $response_summary->{exists} = undef;
  $response_summary->{numTotalResults} = 0;
  $beaconAlleleResponse->{responseSummary} = $response_summary;

  my $assemblyId = $data->{assemblyId};
  if (uc($db_assembly) ne uc($assemblyId)) {
      $beaconError = $self->get_beacon_error(400, "User provided assemblyId (" .
                                                  $assemblyId . ") does not match with dataset assembly (" . $db_assembly . ")");
      $beaconAlleleResponse->{error} = $beaconError;
      return $beaconAlleleResponse;
  }

  # check variant if only all parameters are valid
  if(!defined($beaconError)){
    my %input_coord;
    # Check allele exists 
    $input_coord{'reference_name'} = $data->{referenceName};
    $input_coord{'ref_allele'} = $data->{referenceBases};
    $input_coord{'alt_allele'} = $data->{alternateBases} ? $data->{alternateBases} : $data->{variantType};

    # Types of query:
    #  1) 'start' with no 'end'; can be done for SNV and small indels
    #  2) 'start' and 'end' (range query); any variant falling fully or partially within the range
    #  3) [start1, start2] and [end1, end2] (bracket query); can be used to match any contiguous genomic interval, e.g. for querying imprecise positions
    my @start_list = split /,/, $data->{start};
    my @end_list = split /,/, $data->{end} if ($data->{end});
    my $start_1 = $start_list[0] if($start_list[0]);
    my $start_2 = $start_list[1] if($start_list[1]);
    my $end_1 = $end_list[0] if($end_list[0]);
    my $end_2 = $end_list[1] if($end_list[1]);

    $input_coord{'start'} = $start_1;
    $input_coord{'start_max'} = $start_2 ? $start_2 : $input_coord{'start'};

    my $end;
    if($data->{end}) {
      $input_coord{'end'} = $end_2 ? $end_2 : $end_1;
      $input_coord{'end_min'} = $end_2 ? $end_1 : $input_coord{'end'};
    }
    else {
      $input_coord{'end'} = $input_coord{'start'};
      $input_coord{'end_min'} = $input_coord{'start'};
    }

    # Multiple dataset
    # check variant exists and report exists overall
    my ($exists, $dataset_response)  = $self->variant_exists(\%input_coord, $incl_ds_response, $assemblyId, \@dataset_ids_list);

    my $exists_JSON;
    if ($exists) {
      $exists_JSON = JSON::true;
    } else {
      $exists_JSON = JSON::false;
    }

    $beaconAlleleResponse->{responseSummary}->{exists} = $exists_JSON;

    # $dataset_response is an array ref in which each element is a dataset
    # NumTotalResults is the total number of results
    if($dataset_response){
      $beaconAlleleResponse->{responseSummary}->{numTotalResults} = scalar(@{$dataset_response});
    }

    if ($incl_ds_response) {
      $beaconAlleleResponse->{response}->{resultSets} = $dataset_response;
    }
  }
  return $beaconAlleleResponse;

}

sub check_parameters {
  my ($self, $parameters) = @_;

  my $error = undef;

  my @required_fields = qw/referenceName referenceBases assemblyId/;

  if($parameters->{'alternateBases'}){
    push(@required_fields, 'alternateBases');
    push(@required_fields, 'start');
  }
  else{
    push(@required_fields, 'variantType');
    if($parameters->{'start'}){
      push(@required_fields, 'start');
      push(@required_fields, 'end');
    }
  }

  foreach my $key (@required_fields) {
    return $self->get_beacon_error('400', "Missing mandatory parameter $key")
      unless (exists $parameters->{$key});
  }

  my @optional_fields = qw/content-type callback datasetIds includeResultsetResponses/;

  my %allowed_fields = map { $_ => 1 } @required_fields,  @optional_fields;

  for my $key (keys %$parameters) {
    return $self->get_beacon_error('400', "Invalid parameter $key")
      unless (exists $allowed_fields{$key});
  }

  my %so_terms = %{$self->sv_so_terms()};

  # Note: Does not 
  #   allow a * that is VCF spec for ALT
  if($parameters->{referenceName} !~ /^([1-9]|1[0-9]|2[012]|X|Y|MT)$/i){
    $error = $self->get_beacon_error('400', "Invalid referenceName");
  }
  elsif($parameters->{start} && !$parameters->{end} && !$parameters->{alternateBases}){
    $error = $self->get_beacon_error('400', "Invalid parameters: start without end requires alternateBases");
  }
  elsif($parameters->{referenceBases} !~ /^([AGCT]+|N)$/i){
    $error = $self->get_beacon_error('400', "Invalid referenceBases");
  }
  elsif(defined($parameters->{alternateBases}) && $parameters->{alternateBases} !~ /^([AGCT]+|N)$/i){
    $error = $self->get_beacon_error('400', "Invalid alternateBases");
  }
  elsif(defined($parameters->{variantType}) && !defined($so_terms{$parameters->{variantType}})){
    $error = $self->get_beacon_error('400', "Invalid variantType");
  }
  elsif($parameters->{assemblyId} !~ /^(GRCh38|GRCh37)$/i){
    $error = $self->get_beacon_error('400', "Invalid assemblyId");
  }
  elsif(defined($parameters->{includeResultsetResponses}) && $parameters->{includeResultsetResponses} eq ''){
    $error = $self->get_beacon_error('400', "Invalid includeResultsetResponses");
  }
  elsif(defined($parameters->{datasetIds})){
    foreach my $dataset (split(',', $parameters->{datasetIds})){
      if(!$valid_dataset_ids->{$dataset}){
        $error = $self->get_beacon_error('400', "Invalid datasetId '$dataset'");
      }
    }
  }

  return $error;
}

sub get_beacon_error {
  my ($self, $error_code, $message) = @_;
 
  my $error = {
                "errorCode"    => $error_code,
                "errorMessage" => $message,
              };
  return $error;
}

# return the assembly
sub get_assembly {
  my ($self) = @_;
  my $db_meta = $self->context->model('ga4gh::ga4gh_utils')->fetch_db_meta();
  return $db_meta->{assembly};
}

# TODO  parameter for species
sub variant_exists {
  my ($self, $input_coords, $incl_ds_response, $assemblyId, $dataset_ids_list) = @_;

  my $ref_allele = $input_coords->{'ref_allele'};
  my $alt_allele = $input_coords->{'alt_allele'};

  my $c = $self->context();
 
  my $sv = 0; # structural variant
  my $found = 0; # variant found in dataset

  # List of variants found - response includes all variants found between startMin and endMax
  my @vf_found;
  # my @dataset_response;

  # Dataset error is always undef - there are no errors to be raised
  # Improve in the future
  my $error;

  # Datasets where variation was found
  # Dataset id => dataset object
  my %dataset_var_found;
  # Associates variation name with the datasets where it is found
  my %variant_dt;

  my $slice_step = 5;

  # Position provided is zero-based
  my $start_pos = $input_coords->{'start'} + 1;
  my $end_pos = $input_coords->{'end'} + 1;
  my $start_max_pos = $input_coords->{'start_max'} + 1;
  my $end_min_pos = $input_coords->{'end_min'} + 1;

  # Reference bases for this variant (starting from start).
  # Accepted values: see the REF field in VCF 4.2 specification 
  # (http://samtools.github.io/hts-specs/VCFv4.2.pdf)

  my ($new_ref, $new_alt, $new_start, $new_end, $changed) =
        @{trim_sequences($ref_allele, $alt_allele, $start_pos, $end_pos, 1)};

  my $slice_start = $start_pos - $slice_step;
  my $slice_end   = $end_pos + $slice_step;
  my $reference_name = $input_coords->{'reference_name'};

  my $slice_adaptor = $c->model('Registry')->get_adaptor('homo_sapiens', 'core', 'slice');
  my $slice = $slice_adaptor->fetch_by_region('chromosome', $reference_name, $slice_start, $slice_end);

  my $variation_feature_adaptor; 

  my %terms = %{$self->sv_so_terms()};

  if(defined($terms{$alt_allele})){
    $sv = 1; 
  }

  if($sv == 1) {
    $variation_feature_adaptor = $c->model('Registry')->get_adaptor('homo_sapiens', 'variation', 'StructuralVariationFeature'); 
  }
  else{
    $variation_feature_adaptor = $c->model('Registry')->get_adaptor('homo_sapiens', 'variation', 'variationFeature');
  }

  my $variation_features = $variation_feature_adaptor->fetch_all_by_Slice($slice);

  if (! scalar(@$variation_features)) {
    return (0);
  }

  my ($seq_region_name, $seq_region_start, $seq_region_end, $strand);
  my ($allele_string);
  my ($ref_allele_string, $alt_alleles);
  my ($so_term); 

  foreach my $vf (@$variation_features) {
    $seq_region_name = $vf->seq_region_name();
    $seq_region_start = $vf->seq_region_start();
    $seq_region_end = $vf->seq_region_end();
    $allele_string = $vf->allele_string();
    $strand = $vf->strand();

    if ($strand != 1) {
        next;
    }

    # Type of query
    my $bracket_query = 0;
    if($start_pos != $start_max_pos || $end_pos != $end_min_pos) {
      $bracket_query = 1;
    }

    # Precise match for snv or small indels - end does not make a difference
    if ($sv == 0 && ($seq_region_start != $start_pos) && ($seq_region_end != $end_pos)) {
      next;
    }
    # Match for structural variants
    if($sv == 1){
      # Bracket query
      next if($bracket_query && ($seq_region_start < $start_pos || $seq_region_start > $start_max_pos
              || $seq_region_end < $end_min_pos || $seq_region_end > $end_pos));

      # Range query
      next if ($seq_region_start < $start_pos || $seq_region_start >= $end_pos
              || $seq_region_end <= $start_pos || $seq_region_end > $end_pos);
    }

    # Variant is a SNV
    if ($sv == 0) {
      $ref_allele_string = $vf->ref_allele_string();
      $alt_alleles = $vf->alt_alleles();

      my $contains_alt = contains_value($alt_allele, $alt_alleles);
      my $contains_new_alt = contains_value($new_alt, $alt_alleles);

      # get variation source
      my $source_name = $vf->source_name();

      # Some ins/del have allele string 'G/-', others have TG/T
      # trim sequence doesn't always work
      if ( (uc($ref_allele_string) eq uc($ref_allele) || (uc($ref_allele_string) eq uc($new_ref)))
      && ($contains_alt || $contains_new_alt) ) {
        $found = 1;

        # Checks datasets only for variants that match
        my $datasets_found = $vf->get_all_VariationSets();
        
        my @list_datasetids;
        foreach my $set (@{$datasets_found}) {
          my $dt_id = $set->dbID();
          $dataset_var_found{$dt_id} = $set;
          push (@list_datasetids, $dt_id);
        }

        # We have to consider all dbSNP variants are in the dbSNP set (human)
        if(lc $source_name eq 'dbsnp') {
          my $dbsnp_set = create_var_set($c, 'dbSNP', $self->variation_sets_info->{'dbsnp'}, 'dbsnp');
          push (@list_datasetids, $dbsnp_set->dbID());
          $dataset_var_found{$dbsnp_set->dbID()} = $dbsnp_set;
        }

        $variant_dt{$vf->variation_name} = \@list_datasetids;

        if ($incl_ds_response) {
          push (@vf_found, $vf);
        }
      }
    }
    # Variant is a SV 
    else {
      $so_term = defined $terms{$alt_allele} ? $terms{$alt_allele} : $alt_allele;
      my $vf_so_term = $vf->class_SO_term();

      # get Structural Variation source
      my $source_name = $vf->source_name();

      my $contains_so_term = contains_value($vf_so_term, $so_term);

      if ($contains_so_term) {
        $found = 1;

        # Checks datasets only for variants that match
        my $datasets_found = $vf->get_all_VariationSets();

        my @list_datasetids;
        foreach my $set (@$datasets_found) {
          my $dt_id = $set->dbID();
          $dataset_var_found{$dt_id} = $set;
          push (@list_datasetids, $dt_id);
        }
        
        my $new_set;
        if(lc $source_name eq 'dgva') {
          $new_set = create_var_set($c, 'DGVa', $self->variation_sets_info->{'dgva'}, 'dgva');
        }
        elsif(lc $source_name eq 'dbvar') {
          $new_set = create_var_set($c, 'dbVar', $self->variation_sets_info->{'dbvar'}, 'dbvar');
        }
        
        if($new_set) {
          push (@list_datasetids, $new_set->dbID());
          $dataset_var_found{$new_set->dbID()} = $new_set;
        }
        
        $variant_dt{$vf->variation_name} = \@list_datasetids;

        if ($incl_ds_response) {
          push (@vf_found, $vf);
        }
      }
    }
  }

  my $dataset_response;

  # Include dataset response
  if ($incl_ds_response) {
    ($found, $dataset_response) = $self->get_dataset_response($c, $dataset_ids_list, \@vf_found, \%dataset_var_found, $assemblyId, $sv, \%variant_dt, $found, $incl_ds_response);
  }

  return ($found, $dataset_response);
}

# Returns the dataset response
# Output: 
#    $found: variable was found in the datasets from input or all available datasets
#    @dataset_response: list of datasets response
sub get_dataset_response {
  my ($self, $c, $dataset_ids_list, $vf_found, $dataset_var_found, $assemblyId, $sv, $variant_dt, $found, $incl_ds_response) = @_;

  my %datasets;
  my $available_datasets = $self->get_all_datasets($c); # All datasets available
  my $variation_set_list = $self->get_datasets_input($c, $dataset_ids_list); # Datasets from input

 my @dataset_response;

  # Flag to check if there are any datasets from input
  my $has_dataset = 0;
  if(scalar @$dataset_ids_list > 0) {
    $has_dataset = 1;
  }

  # HIT - returns only datasets that have the queried variant
  # If has a list of datasets to query and a variant was found then print dataset response
  if ($incl_ds_response == 2 && $has_dataset && @$vf_found) {
    foreach my $dataset_id (keys %{$variation_set_list}) {
      if (exists $dataset_var_found->{$dataset_id}) {
        my $response = get_dataset_allele_response($dataset_var_found->{$dataset_id}, $assemblyId, 1, $vf_found, $sv, $variant_dt);
        push (@dataset_response, $response);
      }
    }

    # Variant wasn't found in any of the input datasets
    my @intersection = grep { exists $dataset_var_found->{$_} } keys %{$variation_set_list};
    if (scalar(@intersection) == 0) {
      $found = 0;
    }
  }
  # HIT - returns only datasets that have the queried variant
  # If it does not have a list of datasets then it the dataset response is going to be based on all available datasets
  elsif ($incl_ds_response == 2 && !$has_dataset && @$vf_found) {
    foreach my $dataset_id (keys %{$dataset_var_found}) {
      my $response = get_dataset_allele_response($dataset_var_found->{$dataset_id}, $assemblyId, 1, $vf_found, $sv, $variant_dt);
      push (@dataset_response, $response);
    }
  }

  # ALL - returns all datasets even those that don't have the queried variant
  # If there is a list of datasets then dataset response returns all of them, if not then returns all available datasets
  elsif ($incl_ds_response == 1) {
    %datasets = $has_dataset ? %{$variation_set_list} : %{$available_datasets};
    my $found_in_dataset = @$vf_found ? 1 : 0;
    foreach my $dataset_id (keys %datasets) {
      if (exists $dataset_var_found->{$dataset_id}) {
        my $response = get_dataset_allele_response($dataset_var_found->{$dataset_id}, $assemblyId, $found_in_dataset, $vf_found, $sv, $variant_dt);
        push (@dataset_response, $response);
      }
      else {
         my $response = get_dataset_allele_response($datasets{$dataset_id}, $assemblyId, 0, $vf_found, $sv, $variant_dt);
         push (@dataset_response, $response);
      }
    }
    # Variant wasn't found in any of the input datasets
    if ($has_dataset) {
      my @intersection = grep { exists $dataset_var_found->{$_} } keys %{$variation_set_list};
      if (scalar(@intersection) == 0) {
        $found = 0;
      }
    }
  }
  # MISS - means opposite to HIT value, only datasets that don't have the queried variant
  # Same as HIT but only the datasets that don't have the variant are returned
  elsif ($incl_ds_response == 3) {
    %datasets = $has_dataset ? %{$variation_set_list} : %{$available_datasets};
    foreach my $dataset_id (keys %datasets) {
      if (!exists $dataset_var_found->{$dataset_id}) {
        my $response = get_dataset_allele_response($datasets{$dataset_id}, $assemblyId, 0, $vf_found, $sv, $variant_dt);
        push (@dataset_response, $response);
      }
    }
    # Variant wasn't found in any of the input datasets
    if ($has_dataset) {
      my @intersection = grep { exists $dataset_var_found->{$_} } keys %{$variation_set_list};
      if (scalar(@intersection) == 0) {
        $found = 0;
      }
    }
  }

  return ($found, \@dataset_response);
}

# Returns a BeaconDatasetAlleleResponse for a variant feature
# Assumes that it exists
sub get_dataset_allele_response {
  my ($dataset, $assemblyId, $found, $vfs, $sv, $variant_dt) = @_;

  my $dataset_id = $dataset->dbID();
  my $ds_response;
  # for now dataset error is null
  my $error;

  $ds_response->{'id'} = $dataset->short_name();
  $ds_response->{'exists'} = undef;
  # $ds_response->{'error'} = undef;
  $ds_response->{'resultsCount'} = undef;
  $ds_response->{'results'} = undef;
  $ds_response->{'setType'} = 'dataset';
  $ds_response->{'info'}->{'counts'}->{'callCount'} = undef;
  $ds_response->{'info'}->{'counts'}->{'sampleCount'} = undef;

  # Change
  if (! defined $found) {
    $ds_response->{'error'} = $error;
    return $ds_response;
  }
  if ($found == 0) {
    $ds_response->{'info'}->{'counts'}->{'callCount'} = undef;
    $ds_response->{'exists'} = JSON::false;
    return $ds_response;
  }

  $ds_response->{'exists'} = JSON::true;

  my $url;
  my $externalURL = "https://www.ensembl.org";
  if ($assemblyId eq 'GRCh37') {
    $externalURL = "https://grch37.ensembl.org";
  }

  my @urls;

  # Array to store the results that include the variant info
  my @results_list = ();

  foreach my $variation_feature (@{$vfs}) {
    my $var_name;
    my $delimiter;

    # Format results variation
    # Using the Beacon v2 legacy SNV and Beacon v2 legacy CNV
    my $variation;
    my $variant_type;
    my $ref_bases; # Only for SNPs
    my $alt_bases; # Only for SNPs
    my $seq_region_name;
    my @var_alt_ids; # variantAlternativeIds (part of the identifiers)
    my @genes; # geneIds (part of MolecularAttributes)
    my @molecular_effects; # molecularEffects (part of MolecularAttributes)
    my @clinical; # clinicalInterpretations (part of variantLevelData)
    my %unique_phenotypes;
    my $var;

    if($sv == 1) {
      $var = $variation_feature->structural_variation();
      $variant_type = $variation_feature->class_SO_term(); # TODO - use correct terms
      $var_name = $variation_feature->variation_name();
      $delimiter = "StructuralVariation/Explore?sv=";

    }
    else {
      $variant_type = 'SNP';
      $var = $variation_feature->variation();
      $ref_bases = $variation_feature->ref_allele_string();
      $alt_bases = join(',', @{$variation_feature->alt_alleles()});

      $var_name = $variation_feature->name();
      $delimiter = "Variation/Explore?v=";
    }

    # Checks if dataset_id is one of the datasets where variant is found
    # If it's not found then dataset response won't include this variant
    my $datasets = $variant_dt->{$var_name};
    my $contains = contains_value($dataset_id, $datasets);
    if($contains) {
      my $url_tmp = $externalURL . "/Homo_sapiens/" . $delimiter . $var_name;
      push @urls, $url_tmp;

      my $source_name = $variation_feature->source_name();
      if($source_name eq 'dbSNP') {
        push @var_alt_ids, 'dbSNP:' . $var_name;
      }
      elsif($source_name eq 'COSMIC') {
        push @var_alt_ids, 'COSMIC:' . $var_name;
      }

      # Add other variant ids from variation synonyms
      # Only for SNPs
      if(!$sv) {
        foreach my $source (@{$var->get_all_synonym_sources()}) {
          if($source !~ /Archive dbSNP/) {
            my $synonyms = $var->get_all_synonyms($source);
            foreach my $source_id (@{$synonyms}) {
              push @var_alt_ids, $source . ':' . $source_id;
            }
          }
        }
      }

      my $gene_list = $variation_feature->get_overlapping_Genes();
      foreach my $gene (@{$gene_list}) {
        push @genes, $gene->external_name();
      }

      my $var_consequences = $variation_feature->get_all_OverlapConsequences();
      foreach my $consequence (@{$var_consequences}) {
        my $cons;
        $cons->{id} = $consequence->SO_accession();
        $cons->{label} = $consequence->SO_term();
        push @molecular_effects, $cons;
      }

      $variation->{'variantType'} = $variant_type;
      $variation->{'referenceBases'} = $variation_feature->ref_allele_string() if($ref_bases);
      $variation->{'alternateBases'} = join(',', @{$variation_feature->alt_alleles()}) if($alt_bases);
      $variation->{'location'}->{'type'} = 'SequenceLocation';
      $variation->{'location'}->{'sequence_id'} = $variation_feature->seq_region_name();
      $variation->{'location'}->{'interval'}->{'type'} = 'SequenceInterval';
      $variation->{'location'}->{'interval'}->{'start'}->{'type'} = 'Number';
      $variation->{'location'}->{'interval'}->{'start'}->{'value'} = $variation_feature->seq_region_start() - 1; # following GA4GH VRS specification
      $variation->{'location'}->{'interval'}->{'end'}->{'type'} = 'Number';
      $variation->{'location'}->{'interval'}->{'end'}->{'value'} = $variation_feature->seq_region_end();

      # Get phenotype features to attach to variantLevelData
      my $pheno_features = $var->get_all_PhenotypeFeatures();
      foreach my $pheno_feature (@{$pheno_features}) {
        my $pheno_desc = $pheno_feature->phenotype_description();
        my $ontology_acc = @{$pheno_feature->get_all_ontology_accessions()}[0];
        my $pheno;
        if($pheno_desc && $ontology_acc) {
          $pheno->{conditionId} = $pheno_desc;
          $pheno->{effect}->{id} = $ontology_acc;
          $pheno->{effect}->{label} = $pheno_desc;
          push @clinical, $pheno if (!$unique_phenotypes{$pheno_desc});
          $unique_phenotypes{$pheno_desc} = 1;
        }
      }
    }

    # Prepare the result
    my $result_details;
    $result_details->{variantInternalId} = $var_name;
    $result_details->{variation} = $variation;
    $result_details->{identifiers} = \@var_alt_ids if (scalar @var_alt_ids > 0);

    my @unique_genes = uniq @genes;
    $result_details->{MolecularAttributes}->{geneIds} = \@unique_genes if (scalar @unique_genes > 0);

    my @unique_molecular_effects = uniq @molecular_effects;
    $result_details->{MolecularAttributes}->{molecularEffects} = \@unique_molecular_effects if (scalar @unique_molecular_effects > 0);

    $result_details->{variantLevelData}->{clinicalInterpretations} = \@clinical;

    push(@results_list, $result_details) if $variation;
  }

  $ds_response->{'results'} = \@results_list;

  $ds_response->{'info'}->{'counts'}->{'callCount'} = scalar @urls;

  $ds_response->{'externalUrl'} = \@urls;

  return $ds_response;
}

# Get all datasets that are available in Ensembl Variation
# Return a hash key => dataset_id; value => dataset object
sub get_all_datasets {
  my $self = shift;
  my $c = shift;

  my %available_datasets;

  my $variation_set_adaptor = $c->model('Registry')->get_adaptor('homo_sapiens', 'variation', 'variationset');

  my $variation_set = $variation_set_adaptor->fetch_all();
  foreach my $set (@$variation_set) {
    $available_datasets{$set->dbID()} = $set;
  }

  # Add dbSNP to the set list
  my $dbsnp_set = create_var_set($c, 'dbSNP', $self->variation_sets_info->{'dbsnp'}, 'dbsnp');
  $available_datasets{$dbsnp_set->dbID()} = $dbsnp_set;
  my $dgva_set = create_var_set($c, 'DGVa', $self->variation_sets_info->{'dgva'}, 'dgva');
  $available_datasets{$dgva_set->dbID()} = $dgva_set;
  my $dbvar_set = create_var_set($c, 'dbVar', $self->variation_sets_info->{'dbvar'}, 'dbvar');
  $available_datasets{$dbvar_set->dbID()} = $dbvar_set;

  return \%available_datasets;
}

# Get datasets specified in the input
sub get_datasets_input {
  my $self = shift;
  my $c = shift;
  my $dataset_ids_list = shift;

  my %variation_set_list;

  my $variation_set_adaptor = $c->model('Registry')->get_adaptor('homo_sapiens', 'variation', 'variationset');

  foreach my $dataset_id (@{$dataset_ids_list}) {
    # If the dataset is dbSNP then add the dataset object to the list
    if(lc $dataset_id eq 'dbsnp') {
      my $dbsnp_set = create_var_set($c, 'dbSNP', $self->variation_sets_info->{'dbsnp'}, 'dbsnp');
      $variation_set_list{$dbsnp_set->dbID()} = $dbsnp_set;
    }
    elsif(lc $dataset_id eq 'dgva') {
      my $dgva_set = create_var_set($c, 'DGVa', $self->variation_sets_info->{'dgva'}, 'dgva');
      $variation_set_list{$dgva_set->dbID()} = $dgva_set;
    }
    elsif(lc $dataset_id eq 'dbvar') {
      my $dbvar_set = create_var_set($c, 'dbVar', $self->variation_sets_info->{'dbvar'}, 'dbvar');
      $variation_set_list{$dbvar_set->dbID()} = $dbvar_set;
    }
    else{
      my $variation_set = $variation_set_adaptor->fetch_by_short_name($dataset_id);
      if ($variation_set) {
        $variation_set_list{$variation_set->dbID()} = $variation_set;
      }
    }
  }

  return \%variation_set_list;
}

# Create the dbSNP variation set object - in the variation db dbSNP is not a variation set but we need one for Beacon
# Creates the sets for the Structural Variants
# SVs do not have a variation_set attached so we need to create two fake variation sets for Beacon
# One set for DGVa, another for dbVar
sub create_var_set {
  my $c = shift;
  my $name = shift;
  my $description = shift;
  my $short_name = shift;

  my $variation_set_adaptor = $c->model('Registry')->get_adaptor('homo_sapiens', 'variation', 'variationset');
  my $max_id = get_var_set_max($variation_set_adaptor);
  my $dbid;

  if($short_name eq 'dbsnp') {
    $dbid = $max_id + 1;
  }
  elsif($short_name eq 'dgva') {
    $dbid = $max_id + 2;
  }
  else {
    $dbid = $max_id + 3;
  }

  my $new_set = Bio::EnsEMBL::Variation::VariationSet->new(
                    -dbID => $dbid,
                    -adaptor => $variation_set_adaptor,
                    -name   => $name,
                    -description => $description,
                    -short_name => $short_name
                  );

  return $new_set;
}

# Returns the max variation_set_id from the Variation database
sub get_var_set_max {
  my $variation_set_adaptor = shift;

  # Get current max variation_set_id
  my $variation_sets = $variation_set_adaptor->fetch_all();
  my $max_id = 1;
  foreach my $var_set (@{$variation_sets}) {
    if($var_set->dbID() > $max_id) {
      $max_id = $var_set->dbID();
    }
  }

  return $max_id;
}

# Check if array contains a value
sub contains_value {
  my ($value, $array) = @_;

  foreach my $i ($array) {
    if(grep { $_ eq $value } @{$i}) {
      return 1;
    }
  }

  return;
}

with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;
