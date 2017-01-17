# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
# Copyright [2016-2017] EMBL-European Bioinformatics Institute
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

sub fetch_LDFeatureContainer_variation_name {
  my ($self, $variation_name, $population_name) = @_;
  my $c = $self->context();
  my $species = $c->stash->{species};

  my $va = $c->model('Registry')->get_adaptor($species, 'Variation', 'Variation');
  my $ldfca = $c->model('Registry')->get_adaptor($species, 'Variation', 'LDFeatureContainer');

  my $window_size = $c->request->param('window_size') || 500; # default is 500KB
  Catalyst::Exception->throw("window_size needs to be a value between 0 and 500.") if (!looks_like_number($window_size));
  Catalyst::Exception->throw("window_size needs to be a value between 0 and 500.") if ($window_size > 500);
  Catalyst::Exception->throw("window_size needs to be a value between 0 and 500.") if ($window_size < 0);
  $window_size = floor($window_size);
  my $max_snp_distance = ($window_size / 2) * 1000;
  $ldfca->max_snp_distance($max_snp_distance);

  my $ld_config = $c->config->{'Model::LDFeatureContainer'};
  if ($ld_config && $ld_config->{use_vcf}) {
    $ldfca->db->use_vcf($ld_config->{use_vcf});
    $ldfca->db->vcf_config_file($ld_config->{vcf_config});
    $ldfca->db->vcf_root_dir($ld_config->{dir}) if (defined $ld_config->{dir});
  }
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
  return $self->to_array($ldfc)
}

sub fetch_LDFeatureContainer_slice {
  my ($self, $slice, $population_name) = @_;
  Catalyst::Exception->throw("No region given. Please specify a region to retrieve from this service.") if ! $slice;
  Catalyst::Exception->throw("Specified region is too large. Maximum allowed size for region is 500KB.") if ($slice->length > 500_000);
  my $c = $self->context();
  my $species = $c->stash->{species};

  my $ldfca = $c->model('Registry')->get_adaptor($species, 'Variation', 'LDFeatureContainer');

  my $ld_config = $c->config->{'Model::LDFeatureContainer'};
  if ($ld_config && $ld_config->{use_vcf}) {
    $ldfca->db->use_vcf($ld_config->{use_vcf});
    $ldfca->db->vcf_config_file($ld_config->{vcf_config});
    $ldfca->db->vcf_root_dir($ld_config->{dir}) if (defined $ld_config->{dir});
  }

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
    Catalyst::Exception->throw("LD computaion for region $chrom:$start-$end $population_name caused an error.");
  };
  return $self->to_array($ldfc)
}

sub fetch_LDFeatureContainer_pairwise {
  my ($self, $variation_name1, $variation_name2) = @_;
  my $c = $self->context();
  my $species = $c->stash->{species};

  my $va = $c->model('Registry')->get_adaptor($species, 'Variation', 'Variation');
  my $ldfca = $c->model('Registry')->get_adaptor($species, 'Variation', 'LDFeatureContainer');
  my $pa = $c->model('Registry')->get_adaptor($species, 'Variation', 'Population');

  my $ld_config = $c->config->{'Model::LDFeatureContainer'};
  if ($ld_config && $ld_config->{use_vcf}) {
    $ldfca->db->use_vcf($ld_config->{use_vcf});
    $ldfca->db->vcf_config_file($ld_config->{vcf_config});
    $ldfca->db->vcf_root_dir($ld_config->{dir}) if (defined $ld_config->{dir});
  }

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
      $c->log->error("LD endpoint for pairwise $variation_name1 $variation_name2 $population_name caused an error: $_");
      my $population_name = $population->name;
      Catalyst::Exception->throw("LD computation for $variation_name1 $variation_name2 $population_name caused an error.");
    };

    my $array = $self->to_array($ldfc);
    push @ldfcs, @$array;
  }
  return \@ldfcs;
}

sub to_array {
  my ($self, $LDFC, $population) = @_;
  my $c = $self->context();
  my $species = $c->stash->{species};
  my $pa = $c->model('Registry')->get_adaptor($species, 'Variation', 'Population');
  my $population_id2name = {};
  if ($population) {
    $population_id2name->{$population->dbID} = $population->name;
  }
  my $d_prime = $c->request->param('d_prime');
  my $r2 = $c->request->param('r2');
  my @LDFC_array = ();

  # we pass 1 to get_all_ld_values() so that it doesn't lazy load
  # VariationFeature objects - we only need the name here anyway
  foreach my $ld_hash (@{$LDFC->get_all_ld_values(1)}) {
    my $hash = {};
    $hash->{d_prime} = $ld_hash->{d_prime};
    next if ($d_prime && $hash->{d_prime} < $d_prime);
    $hash->{r2} = $ld_hash->{r2};
    next if ($r2 && $hash->{r2} < $r2);

    # fallback for tests as travis uses the release branch
    $hash->{variation1} = $ld_hash->{variation_name1} || $ld_hash->{variation1}->variation_name; 
    $hash->{variation2} = $ld_hash->{variation_name2} || $ld_hash->{variation2}->variation_name; 
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

with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;
