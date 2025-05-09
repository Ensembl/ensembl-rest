# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
# Copyright [2016-2025] EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http=>//www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package EnsEMBL::REST::Model::LDFeatureContainer;

use Moose;
use namespace::autoclean;
use Try::Tiny;
use POSIX qw/floor/;
use Scalar::Util qw/weaken looks_like_number/;
use Catalyst::Exception qw(throw);
extends 'Catalyst::Model';

with 'Catalyst::Component::InstancePerContext';

has 'context' => (is => 'ro', weak_ref => 1);

sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  weaken($c);
  return $self->new({ context => $c, %$self, @args });
}

# This will deal with errors caused when using unsupported species e.g. fly or species without a variation database e.g. gorilla  
sub _get_LDFeatureContainerAdaptor {
  my $self = shift;
  my $c = $self->context();
  my $species = $c->stash->{species};

  my $ldfca;
  try {
    $ldfca = $c->model('Registry')->get_adaptor($species, 'Variation', 'LDFeatureContainer');
  } catch {
    $c->go('ReturnError', 'from_ensembl', [ qq{$_} ]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [ qq{$_} ]);
    $c->log->error("LD endpoint caused an error: $_");
  };
  Catalyst::Exception->throw("Cannot compute LD for species: $species. The species doesn't have a variation database.") if (!$ldfca);
  my $ld_config = $c->config->{'Model::LDFeatureContainer'};
  if ($ld_config && $ld_config->{use_vcf}) {
    $ldfca->db->use_vcf($ld_config->{use_vcf});
    $ldfca->db->vcf_config_file($ld_config->{vcf_config});
    $ldfca->db->vcf_root_dir($ld_config->{dir}) if (defined $ld_config->{dir});
  }
  return $ldfca;
}

sub fetch_LDFeatureContainer_variation_name {
  my ($self, $variation_name, $population_name) = @_;
  my $c = $self->context();
  my $species = $c->stash->{species};

  my $ldfca = $self->_get_LDFeatureContainerAdaptor();
  my $va = $c->model('Registry')->get_adaptor($species, 'Variation', 'Variation');

  my $vf_attribs = $c->request->param('attribs');
  my $window_size = $c->request->param('window_size') || 500; # default is 500KB
  Catalyst::Exception->throw("window_size needs to be a value between 0 and 500.") if (!looks_like_number($window_size));
  Catalyst::Exception->throw("window_size needs to be a value between 0 and 500.") if ($window_size > 500);
  Catalyst::Exception->throw("window_size needs to be a value between 0 and 500.") if ($window_size < 0);
  $window_size = floor($window_size);
  my $max_snp_distance = ($window_size / 2) * 1000;
  $ldfca->max_snp_distance($max_snp_distance);

  my $variation = $va->fetch_by_name($variation_name);
  Catalyst::Exception->throw("Could not fetch variation object for id: $variation_name.") if ! $variation;
  my @vfs = grep { $_->slice->is_reference } @{$variation->get_all_VariationFeatures()};

  Catalyst::Exception->throw("Variant maps more than once to the genome.") if (scalar @vfs > 1);
  Catalyst::Exception->throw("Could not retrieve a variation feature.") if (scalar @vfs == 0);
  my $vf = $vfs[0];

  my $pa = $c->model('Registry')->get_adaptor($species, 'Variation', 'Population');     
  my $population = $pa->fetch_by_name($population_name);
  if (!$population) {
    Catalyst::Exception->throw("Could not fetch population object for population name: $population_name");
  }
  my $ldfc;
  try {
    $ldfc = $ldfca->fetch_by_VariationFeature($vf, $population);
  } catch {
    $c->log->error("LD endpoint for $variation_name $population_name $window_size caused an error: $_");
    Catalyst::Exception->throw("LD computation for $variation_name $population_name $window_size caused an error.");
  };
  return $self->to_array($ldfc, $vf_attribs);
}

sub fetch_LDFeatureContainer_slice {
  my ($self, $slice, $population_name) = @_;
  if (! $slice) {
    Catalyst::Exception->throw("No region given. Please specify a region to retrieve from this service.");
  }
  if (slice_overlaps_mhc_region($slice)) {
    my $mhc_region = get_mhc_region($slice);
    if ($slice->length > 10_000) {
      Catalyst::Exception->throw("Specified region overlaps MHC region $mhc_region and can therefore not be greater than 10KB.");
    }
  }
  if ($slice->length > 500_000) {
    Catalyst::Exception->throw("Specified region is too large. Maximum allowed size for region is 500KB.");
  }
  my $c = $self->context();
  my $species = $c->stash->{species};

  my $ldfca = $self->_get_LDFeatureContainerAdaptor();

  my $pa = $c->model('Registry')->get_adaptor($species, 'Variation', 'Population');     
  my $population = $pa->fetch_by_name($population_name);
  if (!$population) {
    Catalyst::Exception->throw("Could not fetch population object for population name: $population_name");
  }
  my $ldfc;
  try {
    $ldfc = $ldfca->fetch_by_Slice($slice, $population);
  } catch {
    my $chrom = $slice->seq_region_name; 
    my $start = $slice->start;
    my $end = $slice->end;
    $c->log->error("LD endpoint for region $chrom:$start-$end $population_name caused an error: $_");
    Catalyst::Exception->throw("LD computation for region $chrom:$start-$end $population_name caused an error.");
  };
  return $self->to_array($ldfc)
}

sub fetch_LDFeatureContainer_pairwise {
  my ($self, $variation_name1, $variation_name2) = @_;
  my $c = $self->context();
  my $species = $c->stash->{species};

  my $ldfca = $self->_get_LDFeatureContainerAdaptor();
  my $va = $c->model('Registry')->get_adaptor($species, 'Variation', 'Variation');
  my $pa = $c->model('Registry')->get_adaptor($species, 'Variation', 'Population');

  my @vfs_pair = ();
  foreach my $variation_name ($variation_name1, $variation_name2) {
    my $variation = $va->fetch_by_name($variation_name);
    Catalyst::Exception->throw("Could not fetch variation object for id: $variation_name.") if ! $variation;
    my @vfs = grep { $_->slice->is_reference } @{$variation->get_all_VariationFeatures()};
    Catalyst::Exception->throw("Variant maps more than once to the genome.") if (scalar @vfs > 1);
    Catalyst::Exception->throw("Could not retrieve a variation feature.") if (scalar @vfs == 0);
    push @vfs_pair, $vfs[0];
  }

  my $population_name = $c->request->param('population_name');
  if ($population_name) {
    my $population = $pa->fetch_by_name($population_name);
    if (!$population) {
      Catalyst::Exception->throw("Could not fetch population object for population name: $population_name");
    }
    my $ldfc;
    try {
      $ldfc = $ldfca->fetch_by_VariationFeatures(\@vfs_pair, $population);
    } catch {
      $c->log->error("LD endpoint for pairwise $variation_name1 $variation_name2 $population_name caused an error: $_");
      Catalyst::Exception->throw("LD computation for $variation_name1 $variation_name2 $population_name caused an error.");
    };
    return $self->to_array($ldfc)
  }
  # compute LD for all LD populations
  my $ld_populations = $pa->fetch_all_LD_Populations;
  my @ldfcs = ();
  foreach my $population (@$ld_populations) {
    my $ldfc;
    try {
      $ldfc = $ldfca->fetch_by_VariationFeatures(\@vfs_pair, $population);
    } catch {
      my $population_name = $population->name;
      $c->log->error("LD endpoint for pairwise $variation_name1 $variation_name2 $population_name caused an error: $_");
      Catalyst::Exception->throw("LD computation for $variation_name1 $variation_name2 $population_name caused an error.");
    };

    my $array = $self->to_array($ldfc);
    push @ldfcs, @$array;
  }
  return \@ldfcs;
}

sub to_array {
  my ($self, $LDFC, $vf_attribs) = @_;
  my $c = $self->context();
  my $species = $c->stash->{species};
  my $pa = $c->model('Registry')->get_adaptor($species, 'Variation', 'Population');
  my $population_id2name = {};
  my $d_prime = $c->request->param('d_prime');
  my $r2 = $c->request->param('r2');
  my @LDFC_array = ();

  # we pass 1 to get_all_ld_values() so that it doesn't lazy load
  # VariationFeature objects - we only need the name here anyway
  my $no_vf_attribs = ($vf_attribs) ? 0 : 1;  
  foreach my $ld_hash (@{$LDFC->get_all_ld_values($no_vf_attribs)}) {
    my $hash = {};
    $hash->{d_prime} = $ld_hash->{d_prime};
    next if ($d_prime && $hash->{d_prime} < $d_prime);
    $hash->{r2} = $ld_hash->{r2};
    next if ($r2 && $hash->{r2} < $r2);

    # fallback for tests as travis uses the release branch
    if ($vf_attribs) {
     # only return attribs for variation2 which is used for computing LD stats with the input variation: variation1
     my $vf = $ld_hash->{variation2};
     $hash->{chr} = $vf->seq_region_name;
     $hash->{start} = $vf->seq_region_start;
     $hash->{end} = $vf->seq_region_end; 
     $hash->{strand} = $vf->seq_region_strand;
     $hash->{consequence_type} = $vf->display_consequence;
     $hash->{clinical_significance} = $vf->get_all_clinical_significance_states;
     $hash->{variation} = $ld_hash->{variation_name2} || $ld_hash->{variation2}->variation_name; 
    } else {
      $hash->{variation1} = $ld_hash->{variation_name1} || $ld_hash->{variation1}->variation_name; 
      $hash->{variation2} = $ld_hash->{variation_name2} || $ld_hash->{variation2}->variation_name; 
    }
    my $population_id = $ld_hash->{population_id};
    my $population_name = $population_id2name->{$population_id};
    if (!$population_name) {
      my $population = $pa->fetch_by_dbID($population_id);
      $population_name = $population->name;
    }
    $hash->{population_name} = $population_name;
    push @LDFC_array, $hash;
  }
  return \@LDFC_array;
}

my $mhc_regions = {
  GRCh37 => {chrom => 6, start => 28_477_797, end => 33_448_354},
  GRCh38 => {chrom => 6, start => 28_510_120, end => 33_480_577},
};

sub slice_overlaps_mhc_region {
  my $slice = shift;
  my $assembly = $slice->coord_system->version;
  return 0 unless (defined $mhc_regions->{$assembly});
  my $chrom = $slice->seq_region_name;
  if ($mhc_regions->{$assembly}->{chrom} == $chrom) {
    my $mhc_start = $mhc_regions->{$assembly}->{start};
    my $mhc_end = $mhc_regions->{$assembly}->{end};
    my $start = $slice->start;
    my $end = $slice->end;
    # complete overlap
    return 1 if ($start >= $mhc_start && $end <= $mhc_end); 
    # partial overlap
    return 1 if ($start > $mhc_start && $start < $mhc_end);
    return 1 if ($end > $mhc_start && $end < $mhc_end);
  } 
  return 0; 
}

sub get_mhc_region {
  my $slice = shift;
  my $assembly = $slice->coord_system->version;
  return q{} unless (defined $mhc_regions->{$assembly});
  return $mhc_regions->{$assembly}->{chrom} . ':' . $mhc_regions->{$assembly}->{start} . '-' .  $mhc_regions->{$assembly}->{end};
}


with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;
