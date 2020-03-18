=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
Copyright [2016-2020] EMBL-European Bioinformatics Institute

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

use EnsEMBL::REST::Model::ga4gh::ga4gh_utils;
use Bio::EnsEMBL::Variation::Utils::Sequence qw(trim_sequences); 

use Scalar::Util qw/weaken/;
with 'Catalyst::Component::InstancePerContext';

has 'context' => (is => 'ro',  weak_ref => 1);

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
  my $db_meta = $self->fetch_db_meta();

  my $db_assembly = $db_meta->{assembly} || '';
  my $schema_version = $db_meta->{schema_version} || '';

  my $welcomeURL = 'http://rest.ensembl.org';
  if ($db_assembly eq 'GRCh37') {
    $welcomeURL = 'http://grch37.ensembl.org';
  }

  my $altURL = 'http://www.ensembl.org';
  if ($db_assembly eq 'GRCh37') {
    $altURL = 'http://grch37.ensembl.org';
  }

  # Unique identifier of the Beacon
  my $beacon_id = 'ensembl';
  my $beacon_name = 'EBI - Ensembl';
  if ($db_assembly) {
    $beacon_id = $beacon_id . '.' . lc $db_assembly;
    $beacon_name = $beacon_name . ' ' . $db_assembly;
  }
  $beacon->{id} = $beacon_id;
  $beacon->{name} = $beacon_name;

  $beacon->{apiVersion} = 'v1.0.1';
  $beacon->{organization} =  $self->get_beacon_organization();
  $beacon->{description} = 'Human variant data from the Ensembl database';
  $beacon->{version} = $schema_version;

  $beacon->{welcomeUrl} = $welcomeURL;
  $beacon->{alternativeUrl} = $altURL;
  $beacon->{createDateTime} = undef;
  $beacon->{updateDateTime} = undef;
  $beacon->{datasets} = $self->get_beacon_all_datasets($db_meta);
  $beacon->{sampleAlleleRequests} = undef;
  $beacon->{info} = undef;
  
  return $beacon;

}

# returns ga4gh BeaconOrganization
sub get_beacon_organization {
  my ($self) = @_;

  my $organization;
 
  my $description = "The European Bioinformatics Institute (EMBL-EBI) is part of EMBL, an international, innovative "
                      . "and interdisciplinary research organisation funded by 26 member states and two associate member states "
                      . "to provide the infrastructure needed to share data openly in the life sciences.";

  my $address = "EMBL-EBI, Wellcome Genome Campus, Hinxton, Cambridgeshire, CB10 1SD, UK";

  # The welcome URL depends on the assembly requested
  #my $db_assembly = $db_meta->{assembly};

  #my $welcomeURL = "http://www.ensembl.org";
  #if ($db_assembly eq 'GRCh37') {
  #  $welcomeURL = "http://grch37.ensembl.org";
  #}
  
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

# Get list of all available datasets (Beacon Datasets)
sub get_beacon_all_datasets {
  my ($self, $db_meta, @variation_set_list) = @_; 

  my @beacon_datasets;

  my $c = $self->context(); 

  my $variation_set_adaptor = $c->model('Registry')->get_adaptor('homo_sapiens', 'variation', 'variationset');

  if(!@variation_set_list) {
    @variation_set_list = @{$variation_set_adaptor->fetch_all()};
  }

  foreach my $dataset (@variation_set_list) {
    my $beacon_dataset = $self->get_beacon_dataset($db_meta, $dataset); 
    push(@beacon_datasets, $beacon_dataset); 
  }

  return \@beacon_datasets; 

}

# Get a VariationSet and return a Beacon Dataset 
sub get_beacon_dataset {
  my ($self, $db_meta, $dataset) = @_;

  my $beacon_dataset;

  my $db_assembly = $db_meta->{assembly};
  my $externalURL = 'http://www.ensembl.org';
  if ($db_assembly eq 'GRCh37') {
    $externalURL = 'http://grch37.ensembl.org';
  }

  $beacon_dataset->{id} = $dataset->short_name();
  $beacon_dataset->{name} = $dataset->name();
  $beacon_dataset->{description} = $dataset->description();
  $beacon_dataset->{assemblyId} = $db_assembly;
  $beacon_dataset->{createDateTime} = undef;
  $beacon_dataset->{updateDateTime} = undef;
  $beacon_dataset->{version} = $db_meta->{schema_version};
  $beacon_dataset->{variantCount} = undef;
  $beacon_dataset->{callCount} = undef;
  $beacon_dataset->{sampleCount} =  undef;
  $beacon_dataset->{externalUrl} = $externalURL; 
  $beacon_dataset->{info} = undef;
  return $beacon_dataset;
}

sub beacon_query {

  my ($self, $data) = @_;
  my $beaconAlleleResponse;
  my $beaconError;

  my $beacon = $self->get_beacon();

  $beaconError = $self->check_parameters($data); 

  my $beaconAlleleRequest = $self->get_beacon_allele_request($data);

  # includeDatasetResponses can be:
  # ALL returns all datasets even those that don't have the queried variant
  # HIT returns only datasets that have the queried variant
  # MISS means opposite to HIT value, only datasets that don't have the queried variant
  # NONE don't return datasets response
  my $incl_ds_response = 0; #NONE
  if (exists $data->{includeDatasetResponses}) {
    if ($data->{includeDatasetResponses} eq 'ALL') {
      $incl_ds_response = 1;
    }
    elsif ($data->{includeDatasetResponses} eq 'HIT') {
      $incl_ds_response = 2;
    }
    elsif ($data->{includeDatasetResponses} eq 'MISS') {
      $incl_ds_response = 3;
    }
  }

  # Check if there is dataset ids in the input
  # Get list of dataset ids
  my $has_dataset = 0;
  my @dataset_ids_list;

  if (exists $data->{datasetIds}) {
    $has_dataset = 1;
    @dataset_ids_list = split(',', $data->{datasetIds});
  }

  $beaconAlleleResponse->{beaconId} = $beacon->{id};
  $beaconAlleleResponse->{exists} = undef;
  $beaconAlleleResponse->{error} = $beaconError;
  $beaconAlleleResponse->{alleleRequest} = $beaconAlleleRequest;
  $beaconAlleleResponse->{datasetAlleleResponses} = undef;

  # Check assembly requested is assembly of DB
  my $db_assembly = $self->get_assembly();

  my $assemblyId = $data->{assemblyId};
  if (uc($db_assembly) ne uc($assemblyId)) {
      $beaconError = $self->get_beacon_error(400, "User provided assemblyId (" .
                                                  $assemblyId . ") does not match with dataset assembly (" . $db_assembly . ")");
      $beaconAlleleResponse->{error} = $beaconError;
      return $beaconAlleleResponse;
  }
 
  # check variant if only all parameters are valid
  if(!defined($beaconError)){
    # Check allele exists 
    my $reference_name = $data->{referenceName};
    my $ref_allele = $data->{referenceBases};
    my $alt_allele = $data->{alternateBases} ? $data->{alternateBases} : $data->{variantType};

    # SNV or small indels have a start
    # Structural variants can have start-end or startMin/startMax-endMin/endMax
    my $start = $data->{start} ? $data->{start} : $data->{startMin};
    my $start_max = $data->{startMax} ? $data->{startMax} : $start;

    my $end;
    if($data->{end}) {
      $end = $data->{end}; 
    }
    elsif($data->{endMax}) {
      $end = $data->{endMax};
    }
    else{
      $end = $start;
    }
    my $end_min = $data->{endMin} ? $data->{endMin} : $end;

    # Multiple dataset
    # check variant exists and report exists overall
    my ($exists, $dataset_response)  = $self->variant_exists($reference_name,$start,$start_max,$end,$end_min,$ref_allele,$alt_allele,$incl_ds_response, $assemblyId, \@dataset_ids_list, $has_dataset);

    my $exists_JSON;
    if ($exists) {
      $exists_JSON = JSON::true;
    } else {
      $exists_JSON = JSON::false;
    }
    $beaconAlleleResponse->{exists} = $exists_JSON;
    if ($incl_ds_response) {
      $beaconAlleleResponse->{datasetAlleleResponses} = $dataset_response;
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
    else{
      push(@required_fields, 'startMin');
      push(@required_fields, 'startMax');
      push(@required_fields, 'endMin');
      push(@required_fields, 'endMax');
    }
  }

  foreach my $key (@required_fields) {
    return $self->get_beacon_error('400', "Missing mandatory parameter $key")
      unless (exists $parameters->{$key});
  }

  my @optional_fields = qw/content-type callback datasetIds includeDatasetResponses/;

  my %allowed_fields = map { $_ => 1 } @required_fields,  @optional_fields;

  for my $key (keys %$parameters) {
    return $self->get_beacon_error('400', "Invalid parameter $key")
      unless (exists $allowed_fields{$key});
  }

  # Note: Does not 
  #   allow a * that is VCF spec for ALT
  if($parameters->{referenceName} !~ /^([1-9]|1[0-9]|2[012]|X|Y|MT)$/i){
    $error = $self->get_beacon_error('400', "Invalid referenceName");
  }
  elsif(defined($parameters->{start}) && $parameters->{start} !~ /^\d+$/){
    $error = $self->get_beacon_error('400', "Invalid start");
  }
  elsif(defined($parameters->{end}) && $parameters->{end} !~ /^\d+$/){
    $error = $self->get_beacon_error('400', "Invalid end");
  }
  elsif(defined($parameters->{startMin}) && $parameters->{startMin} !~ /^\d+$/){
    $error = $self->get_beacon_error('400', "Invalid startMin");
  }
  elsif(defined($parameters->{startMax}) && $parameters->{startMax} !~ /^\d+$/){
    $error = $self->get_beacon_error('400', "Invalid startMax");
  }
  elsif(defined($parameters->{endMin}) && $parameters->{endMin} !~ /^\d+$/){
    $error = $self->get_beacon_error('400', "Invalid endMin");
  }
  elsif(defined($parameters->{endMax}) && $parameters->{endMax} !~ /^\d+$/){
    $error = $self->get_beacon_error('400', "Invalid endMax");
  }
  elsif($parameters->{referenceBases} !~ /^([AGCT]+|N)$/i){
    $error = $self->get_beacon_error('400', "Invalid referenceBases");
  }
  elsif(defined($parameters->{alternateBases}) && $parameters->{alternateBases} !~ /^([AGCT]+|N)$/i){
    $error = $self->get_beacon_error('400', "Invalid alternateBases");
  }
  elsif(defined($parameters->{variantType}) && $parameters->{variantType} !~ /^(DEL|DEL\:ME|INS|INS\:ME|CNV|DUP|INV|DUP\:TANDEM)$/i){
    $error = $self->get_beacon_error('400', "Invalid variantType");
  }
  elsif($parameters->{assemblyId} !~ /^(GRCh38|GRCh37)$/i){
    $error = $self->get_beacon_error('400', "Invalid assemblyId");
  }
  elsif(defined($parameters->{includeDatasetResponses}) && $parameters->{includeDatasetResponses} eq ''){
    $error = $self->get_beacon_error('400', "Invalid includeDatasetResponses");
  }

  return $error; 
 
}

# Get beacon_allele_request
sub get_beacon_allele_request {
  my ($self, $data) = @_;
  my $beaconAlleleRequest;

  for my $field (qw/referenceName start referenceBases alternateBases variantType assemblyId/) {
    $beaconAlleleRequest->{$field} = $data->{$field};
  }

  if (exists $data->{start}) {
    $beaconAlleleRequest->{start} = int($data->{start});
  }

  if (exists $data->{end}) {
    $beaconAlleleRequest->{end} = int($data->{end});
  }
  if (exists $data->{startMin}) {
    $beaconAlleleRequest->{startMin} = int($data->{startMin});
  }
  if (exists $data->{startMax}) {
    $beaconAlleleRequest->{startMax} = int($data->{startMax});
  }
  if (exists $data->{endMin}) {
    $beaconAlleleRequest->{endMin} = int($data->{endMin});
  }
  if (exists $data->{endMax}) {
    $beaconAlleleRequest->{endMax} = int($data->{endMax});
  }

  $beaconAlleleRequest->{datasetIds} = undef;
  if (exists $data->{datasetIds}) {
    $beaconAlleleRequest->{datasetIds} = $data->{datasetIds};
  }

  $beaconAlleleRequest->{includeDatasetResponses} = undef;
  if (exists $data->{includeDatasetResponses}) {
    $beaconAlleleRequest->{includeDatasetResponses} = $data->{includeDatasetResponses};
  }
  return $beaconAlleleRequest;
}

sub get_beacon_error {
  my ($self, $error_code, $message) = @_;
 
  my $error = {
                "errorCode"    => $error_code,
                "errorMessage" => $message,
              };
  return $error;
}

sub get_assembly {
  my ($self) = @_;
  my $db_meta = $self->fetch_db_meta();
  return $db_meta->{assembly};
}

# Fetch required meta info 
# TODO place in utilities
sub fetch_db_meta {
  my ($self) = @_;

  # my $c = $self->context();-
  # $c->log()->info("for info");
  my $species = 'homo_sapiens';
  my $core_ad = $self->context->model('Registry')->get_DBAdaptor($species, 'Core');

  ## extract required meta data from core db
  my $cmeta_ext_sth = $core_ad->dbc->db_handle->prepare(qq[ select meta_key, meta_value from meta]);
  $cmeta_ext_sth->execute();
  my $core_meta = $cmeta_ext_sth->fetchall_arrayref();

  my %cmeta;
  foreach my $l(@{$core_meta}){
    $cmeta{$l->[0]} = $l->[1];
  }

  ## default ensembl set names/ids
  my $db_meta;
  $db_meta->{datasetId}      = "Ensembl";
  $db_meta->{id}             = join(".", "Ensembl",
                                         $cmeta{"schema_version"},
                                         $cmeta{"assembly.default"});
  $db_meta->{assembly}       = $cmeta{"assembly.default"};
  $db_meta->{schema_version} = $cmeta{"schema_version"};
 
  return $db_meta;
}

# TODO  parameter for species
# TODO  use assemblyID
# Assembly not taken to account, assembly of REST machine
sub variant_exists {
  my ($self, $reference_name, $start, $start_max, $end, $end_min, $ref_allele, 
           $alt_allele, $incl_ds_response, $assemblyId, $dataset_ids_list, $has_dataset) = @_;

  my $c = $self->context();
 
  my $sv = 0;
  my $found = 0;

  # List of variants found - response includes all variants found between startMin and endMax
  my @vf_found;

  # Dataset error is always undef - there are no errors to be raised
  # Improve in the future
  my $error;
  my @dataset_response;

  # Datasets where variation was found
  # Dataset id => dataset object
  my %dataset_var_found;
  # All available databases
  my %available_datasets;
  # Datasets specified in the input
  my %variation_set_list;
  # Associates variation name with the datasets where it is found
  my %variant_dt;

  my $slice_step = 5;

  # Position provided is zero-based
  my $start_pos = $start + 1;
  my $end_pos = $end + 1;
  my $start_max_pos = $start_max + 1;
  my $end_min_pos = $end_min + 1;
  my $chromosome = $reference_name;

  # Reference bases for this variant (starting from start).
  # Accepted values: see the REF field in VCF 4.2 specification 
  # (http://samtools.github.io/hts-specs/VCFv4.2.pdf)

  my ($new_ref, $new_alt, $new_start, $new_end, $changed) =
        @{trim_sequences($ref_allele, $alt_allele, $start_pos, $end_pos, 1)};

  my $slice_start = $start_pos - $slice_step;
  my $slice_end   = $end_pos + $slice_step;

  my $slice_adaptor = $c->model('Registry')->get_adaptor('homo_sapiens', 'core', 'slice');
  my $slice = $slice_adaptor->fetch_by_region('chromosome', $chromosome, $slice_start, $slice_end);

  my $variation_feature_adaptor; 

  if($alt_allele =~ /DEL|INS|CNV|DUP|INV|DUP:TANDEM|INS:ME|DEL:ME/){
    $sv = 1; 
  }

  if($sv == 1) {
    $variation_feature_adaptor = $c->model('Registry')->get_adaptor('homo_sapiens', 'variation', 'StructuralVariationFeature'); 
  }
  else{
    $variation_feature_adaptor = $c->model('Registry')->get_adaptor('homo_sapiens', 'variation', 'variationFeature');
  }

  my $variation_set_adaptor = $c->model('Registry')->get_adaptor('homo_sapiens', 'variation', 'variationset');

  # Get all available datasets
  my $variation_set = $variation_set_adaptor->fetch_all();
  foreach my $set (@$variation_set) {
    $available_datasets{$set->dbID()} = $set;
  }

  # Get datasets specified in the input
  foreach my $dataset_id (@{$dataset_ids_list}) {
    my $variation_set = $variation_set_adaptor->fetch_by_short_name($dataset_id);
    if ($variation_set) {
      $variation_set_list{$variation_set->dbID()} = $variation_set;
    }
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

    # Precise match for snv or small indels - end does not make a difference
    if ($sv == 0 && ($seq_region_start != $start_pos) && ($seq_region_end != $end_pos)) {
      next;
    }
    # Match for structural variants
    if($sv == 1){
      next if ($seq_region_start < $start_pos || $seq_region_start > $start_max_pos
              || $seq_region_end < $end_min_pos || $seq_region_end > $end_pos);
    }

    # Variant is a SNV
    if ($sv == 0) {
      $ref_allele_string = $vf->ref_allele_string();
      $alt_alleles = $vf->alt_alleles();

      my $contains_alt = contains_value($alt_allele, $alt_alleles);
      my $contains_new_alt = contains_value($new_alt, $alt_alleles);

      # Some ins/del have allele string 'G/-', others have TG/T
      # trim sequence doesn't always work
      if ( (uc($ref_allele_string) eq uc($ref_allele) || (uc($ref_allele_string) eq uc($new_ref)))
      && ($contains_alt || $contains_new_alt) ) {
        $found = 1;

        # Checks datasets only for variants that match
        my $datasets_found = $vf->get_all_VariationSets();
        my @list_datasetids;
        foreach my $set (@$datasets_found) {
          my $dt_id = $set->dbID();
          $dataset_var_found{$dt_id} = $set;
          push (@list_datasetids, $dt_id);
        }
        $variant_dt{$vf->variation_name} = \@list_datasetids;

        if ($incl_ds_response) {
          push (@vf_found, $vf);
        }
      }
    }
    # Variant is a SV 
    else {
      # convert to SO term
      # There's more than one term for each type - use a list of SO terms
      # CNV =~ DEL or DUP 
      my %terms = (
        'INS'    => ['insertion'],
        'INS:ME' => ['mobile_element_insertion'],
        'DEL'    => ['deletion'],
        'DEL:ME' => ['mobile_element_deletion'],
        'CNV'    => ['copy_number_variation','copy_number_gain','copy_number_loss','deletion','duplication'],
        'DUP'    => ['duplication'],
        'INV'    => ['inversion'],
        'DUP:TANDEM' => ['tandem_duplication']
      );

      $so_term = defined $terms{$alt_allele} ? $terms{$alt_allele} : $alt_allele;
      my $vf_so_term = $vf->class_SO_term();

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
        $variant_dt{$vf->variation_name} = \@list_datasetids;

        if ($incl_ds_response) {
          push (@vf_found, $vf);
        }
      }
    }
  }

  if ($incl_ds_response) {
    my %datasets;
    # HIT - returns only datasets that have the queried variant
    # If has a list of datasets to query and a variant was found then print dataset response
    if ($incl_ds_response == 2 && $has_dataset && @vf_found) {
      foreach my $dataset_id (keys %variation_set_list) {
        if (exists $dataset_var_found{$dataset_id}) {
          my $response = get_dataset_allele_response($dataset_var_found{$dataset_id}, $assemblyId, 1, \@vf_found, $error, $sv, \%variant_dt);
          push (@dataset_response, $response);
        }
      }

      # Variant wasn't found in any of the input datasets
      my @intersection = grep { exists $dataset_var_found{$_} } keys %variation_set_list;
      if (scalar(@intersection) == 0) {
        $found = 0;
      }
    }
    # HIT - returns only datasets that have the queried variant
    # If it does not have a list of datasets then it the dataset response is going to be based on all available datasets
    elsif ($incl_ds_response == 2 && !$has_dataset && @vf_found) {
      foreach my $dataset_id (keys %dataset_var_found) {
        my $response = get_dataset_allele_response($dataset_var_found{$dataset_id}, $assemblyId, 1, \@vf_found, $error, $sv, \%variant_dt);
        push (@dataset_response, $response);
      }
    }

    # ALL - returns all datasets even those that don't have the queried variant
    # If there is a list of datasets then dataset response returns all of them, if not then returns all available datasets
    elsif ($incl_ds_response == 1) {
      %datasets = $has_dataset ? %variation_set_list : %available_datasets;
      my $found_in_dataset = @vf_found ? 1 : 0;
      foreach my $dataset_id (keys %datasets) {
        if (exists $dataset_var_found{$dataset_id}) {
          my $response = get_dataset_allele_response($dataset_var_found{$dataset_id}, $assemblyId, $found_in_dataset, \@vf_found, $error, $sv, \%variant_dt);
          push (@dataset_response, $response);
        }
        else {
           my $response = get_dataset_allele_response($datasets{$dataset_id}, $assemblyId, 0, \@vf_found, $error, $sv, \%variant_dt);
           push (@dataset_response, $response);
        }
      }
      # Variant wasn't found in any of the input datasets
      if ($has_dataset) {
        my @intersection = grep { exists $dataset_var_found{$_} } keys %variation_set_list;
        if (scalar(@intersection) == 0) {
          $found = 0;
        }
      }
    }
    # MISS - means opposite to HIT value, only datasets that don't have the queried variant
    # Same as HIT but only the datasets that don't have the variant are returned
    elsif ($incl_ds_response == 3) {
      %datasets = $has_dataset ? %variation_set_list : %available_datasets;
      foreach my $dataset_id (keys %datasets) {
        if (!exists $dataset_var_found{$dataset_id}) {
          my $response = get_dataset_allele_response($datasets{$dataset_id}, $assemblyId, 0, \@vf_found, $error, $sv, \%variant_dt);
          push (@dataset_response, $response);
        }
      }
      # Variant wasn't found in any of the input datasets
      if ($has_dataset) {
        my @intersection = grep { exists $dataset_var_found{$_} } keys %variation_set_list;
        if (scalar(@intersection) == 0) {
          $found = 0;
        }
      }
    }
  }

  return ($found,\@dataset_response);
}

# Returns a BeaconDatasetAlleleResponse for a
# variant feature
# Assumes that it exists
sub get_dataset_allele_response {
  my ($dataset, $assemblyId, $found, $vf, $error, $sv, $variant_dt) = @_;

  my $dataset_id = $dataset->dbID();
  my $ds_response;

    $ds_response->{'datasetId'} = $dataset->short_name();
    $ds_response->{'exists'} = undef;
    $ds_response->{'error'} = undef;
    $ds_response->{'frequency'} = undef;
    $ds_response->{'callCount'} = undef;
    $ds_response->{'sampleCount'} = undef;
    $ds_response->{'note'} = undef;
    $ds_response->{'externalUrl'} = undef;
    $ds_response->{'info'} = undef;

    # Change 
    if (! defined $found) {
      $ds_response->{'error'} = $error;
      return $ds_response;
    }
    if ($found == 0) {
      $ds_response->{'variantCount'} = undef;
      $ds_response->{'exists'} = JSON::false;
      return $ds_response;
    }

    $ds_response->{'exists'} = JSON::true;

    my $externalURL = "http://www.ensembl.org";
    if ($assemblyId eq 'GRCh37') {
      $externalURL = "http://grch37.ensembl.org";
    }

    my @urls;

    if($vf) {
      my $var_name;
      my $delimiter;
      foreach my $variant (@{$vf}) {
        if($sv == 1) {
          $var_name = $variant->variation_name();
          $delimiter = "StructuralVariation/Explore?sv=";
        }
        else {
          $var_name = $variant->name();
          $delimiter = "Variation/Explore?v=";
        }

        # Checks if dataset_id is one of the datasets where variant is found
        # If it's not found then dataset response won't include this variant
        my %var_dataset = %{$variant_dt};
        my $datasets = $var_dataset{$var_name};
        my $contains = contains_value($dataset_id, $datasets);
        if($contains) {
          my $url_tmp = $externalURL . "/Homo_sapiens/" . $delimiter . $var_name;
          push @urls, $url_tmp;
        }
      }
      my $url = join(',', @urls);
      $externalURL = $url;
    }

    $ds_response->{'variantCount'} = scalar @urls;

    $ds_response->{'externalUrl'} = $externalURL;

  return $ds_response;
}

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
