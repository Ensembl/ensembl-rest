=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
Copyright [2016-2017] EMBL-European Bioinformatics Institute

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

# use Data::Dumper;

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
  $beacon->{id} = 'Ensembl ' . $db_assembly;
  $beacon->{name} = 'Ensembl ' . $db_assembly;

  $beacon->{apiVersion} = 'v0.3.0';
  $beacon->{organization} =  $self->get_beacon_organization($db_meta);
  $beacon->{description} = 'Human variant data from the Ensembl database';
  $beacon->{version} = $schema_version;

  $beacon->{welcomeUrl} = $welcomeURL;
  $beacon->{alternativeUrl} = $altURL;
  $beacon->{createDateTime} = undef;
  $beacon->{updateDateTime} = undef;
  $beacon->{datasets} = [$self->get_beacon_dataset($db_meta)];
  $beacon->{sampleAlleleRequests} = undef;
  $beacon->{info} = undef;
  
  return $beacon;

}

# returns ga4gh BeaconOrganization
sub get_beacon_organization {
  my ($self, $db_meta) = @_;

  my $organization;
  
  my $description = "Ensembl creates, integrates and distributes reference datasets"
                    . " and analysis tools that enable genomics."
                    . " We are based at EMBL-EBI and our software"
                    . " and data are freely available.";

  my $address = "EMBL-EBI, Wellcome Genome Campus, Hinxton, "
                . "Cambridgeshire, CB10 1SD, UK";

  # The welcome URL depends on the assembly requested
  my $db_assembly = $db_meta->{assembly};

  my $welcomeURL = "http://www.ensembl.org";
  if ($db_assembly eq 'GRCh37') {
    $welcomeURL = "http://grch37.ensembl.org";
  }

  my $contactURL = "http://www.ensembl.org/info/about/contact/index.html";
  my $logoURL = "http://www.ensembl.org/i/e-ensembl.png"; 

  # Unique identifier of the organization
  $organization->{id} = "Ensembl";
  $organization->{name} = "Ensembl";
  $organization->{description} = $description;
  $organization->{addresss} = $address;
  $organization->{welcomeUrl} = $welcomeURL;
  $organization->{contactUrl} = $contactURL;
  $organization->{logoUrl} = $logoURL;
  $organization->{info} = undef;
  return $organization;
}

sub get_beacon_dataset {
  my ($self, $db_meta) = @_;

  my $dataset;
  
  my $db_assembly = $db_meta->{assembly};
  my $schema_version = $db_meta->{schema_version};
  my $externalURL = 'http://www.ensembl.org';
  if ($db_assembly eq 'GRCh37') {
    $externalURL = 'http://grch37.ensembl.org';
  }

  $dataset->{id} = join(" ", 'Ensembl', $schema_version);
  $dataset->{name} = join(" ", 'Ensembl', $schema_version);
  $dataset->{description} = "Human variant data from the Ensembl database";
  $dataset->{assemblyId} = $db_assembly;
  $dataset->{createDateTime} = undef;
  $dataset->{updateDateTime} = undef;
  $dataset->{version} = $schema_version;
  $dataset->{variantCount} = undef;
  $dataset->{callCount} = undef;
  $dataset->{sampleCount} =  undef;
  $dataset->{externalUrl} = $externalURL; 
  $dataset->{info} = undef;
  return $dataset;
}

# TODO get the beaconID from getBeacon
sub beacon_query {
 
  my ($self, $data) = @_;

  my $beaconAlleleResponse;
  my $beaconError;

  my $beacon = $self->get_beacon();
  my $beaconAlleleRequest = $self->get_beacon_allele_request($data);

  $beaconAlleleResponse->{beaconId} = $beacon->{id};
  $beaconAlleleResponse->{exists} = undef;
  $beaconAlleleResponse->{error} = undef;
  $beaconAlleleResponse->{alleleRequest} = $beaconAlleleRequest;
  $beaconAlleleResponse->{datasetAlleleResponses} = undef;

  # Check assembly requested is assembly of DB
  my $db_assembly = $self->get_assembly();
  my $assemblyId = $data->{assemblyId};
  if (uc($db_assembly) ne uc($assemblyId)) {
      $beaconError = $self->get_beacon_error(100, "Assembly (" .
                                                  $assemblyId . ") not available");
      $beaconAlleleResponse->{error} = $beaconError;
      return $beaconAlleleResponse;
  }
  
  # Check allele exists
  my $reference_name = $data->{referenceName};
  my $start = $data->{start};
  my $ref_allele = $data->{referenceBases};
  my $alt_allele = $data->{alternateBases};
  my $exists = $self->variant_exists($reference_name,
                                       $start,
                                       $ref_allele,
                                       $alt_allele);

  my $exists_JSON = $exists;
  if ($exists) {
    $exists_JSON = JSON::true;
  } else {
    $exists_JSON = JSON::false;
  }
  $beaconAlleleResponse->{exists} = $exists_JSON;

  return $beaconAlleleResponse;				
  
}

# Get beacon_allele_request
sub get_beacon_allele_request {
  my ($self, $data) = @_;
  my $beaconAlleleRequest;

  for my $field (qw/referenceName start referenceBases alternateBases assemblyId/) {
	$beaconAlleleRequest->{$field} = $data->{$field};
  }
  $beaconAlleleRequest->{datasetIds} = undef;
  $beaconAlleleRequest->{includeDatasetResponses} = undef;

  return $beaconAlleleRequest;
}

sub get_beacon_error {
  my ($self, $error_code, $message) = @_;
 
  my $error = {
                "errorCode" => $error_code,
                "message"   => $message,
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
  my ($self)  = @_;

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
  my ($self, $reference_name, $start, $ref_allele, $alt_allele) = @_;

  my $c = $self->context();
  
  my $found = 0;
  my $slice_step = 5;

  # Position provided is zero-based
  my $start_pos  = $start + 1;
  my $chromosome = $reference_name;

  # Reference bases for this variant (starting from start). 
  # Accepted values: see the REF field in VCF 4.2 specification 
  # (http://samtools.github.io/hts-specs/VCFv4.2.pdf)

  my ($new_ref, $new_alt, $new_start, $new_end, $changed) =
        @{trim_sequences($ref_allele, $alt_allele, $start_pos, undef, 1)};

  my $slice_start = $start_pos - $slice_step;
  my $slice_end   = $start_pos + $slice_step;

  my $slice_adaptor = $c->model('Registry')->get_adaptor('homo_sapiens', 'core', 'slice');
  my $slice = $slice_adaptor->fetch_by_region('chromosome', $chromosome, $slice_start, $slice_end);

  my $variation_feature_adaptor = $c->model('Registry')->get_adaptor('homo_sapiens', 'variation', 'variationFeature');
  my $variation_features  = $variation_feature_adaptor->fetch_all_by_Slice($slice);

  if (! scalar(@$variation_features)) {
    return 0;
  }

  my ($seq_region_name, $seq_region_start, $seq_region_end, $strand);
  my ($allele_string);
  my ($ref_allele_string, $alt_alleles);

  foreach my $vf (@$variation_features) {
    $seq_region_name = $vf->seq_region_name();
    $seq_region_start = $vf->seq_region_start();
    $seq_region_end = $vf->seq_region_end();
    $allele_string = $vf->allele_string();
    $strand = $vf->strand();

    if ($strand != 1) {
        next;
    }

    if (($seq_region_start != $new_start) && ($seq_region_end != $new_end)) {
        next;
    }

    $ref_allele_string = $vf->ref_allele_string();
    $alt_alleles = $vf->alt_alleles();

    if ((uc($ref_allele_string) eq uc($new_ref))
      && (grep(/^$new_alt$/i, @{$alt_alleles}))) {
        $found=1;
        last;
    } else {
        $found=0;
    }
  }
  return $found;
}

with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;
