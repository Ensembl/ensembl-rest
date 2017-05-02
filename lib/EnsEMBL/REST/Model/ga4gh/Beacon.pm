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
  
use Scalar::Util qw/weaken/;
with 'Catalyst::Component::InstancePerContext';

has 'context' => (is => 'ro',  weak_ref => 1);

 
sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  weaken($c);
  return $self->new({ context => $c, %$self, @args });
}

# returns ga4gh Beacon
sub get_beacon {
  my ($self) = @_;
  my $beacon;
  
  $beacon->{id} = "TBD";
  $beacon->{name} = "EMBL-EBI Ensembl";
  $beacon->{apiVersion} = "v0.3.0";
  $beacon->{organization} =  $self->get_beacon_organization();
  $beacon->{description} = "TBD";
  $beacon->{version} = "TBD";

  $beacon->{welcomeURL} = undef;
  $beacon->{alternativeURL} = undef;
  $beacon->{createDateTime} = undef;
  $beacon->{updateDateTime} = undef;
  $beacon->{datasets} = [];
  $beacon->{sampleAlleleRequests} = undef;
  $beacon->{info} = undef;
  
  return $beacon;

}

# returns ga4gh BeaconOrganization
sub get_beacon_organization {
  my ($self) = @_;

  my $organization;
  
  # Unique identifier of the organization
  $organization->{id} = "EMBL-EBI Ensembl";
  $organization->{name} = "EMB-EBI";
  $organization->{description} = "TBD";
  $organization->{addresss} = "TBD";
  $organization->{welcomeURL} = "TBD";
  $organization->{contactURL} = "TBD";
  $organization->{logoURL} = "TBD";
  $organization->{info} = undef;
  return $organization;
}

# TODO get the beaconID from getBeacon
sub beacon_query {
 
  my ($self, $data) = @_;

  my $beaconAlleleResponse;

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
	
  $beaconAlleleResponse->{beaconId} = "EMBL-EBI Ensembl";
  $beaconAlleleResponse->{exists} = $exists_JSON;
  $beaconAlleleResponse->{error} = undef;
  $beaconAlleleResponse->{alleleRequest} = undef;
  $beaconAlleleResponse->{datasetAlleleResponses} = undef;
  
  return $beaconAlleleResponse;				
  
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
