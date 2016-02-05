# Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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
  my ($self, $variation_name) = @_;
  Catalyst::Exception->throw("No variation given. Please specify a variation to retrieve from this service") if ! $variation_name;
  my $c = $self->context();
  my $species = $c->stash->{species};

  my $va = $c->model('Registry')->get_adaptor($species, 'Variation', 'Variation');
  my $ldfca = $c->model('Registry')->get_adaptor($species, 'Variation', 'LDFeatureContainer');

  my $window_size = $c->request->param('window_size') || 1000; # default is 1MB
  Catalyst::Exception->throw("window_size needs to be a value bewteen 0 and 1000.") if (!looks_like_number($window_size));
  Catalyst::Exception->throw("window_size needs to be a value bewteen 0 and 1000.") if ($window_size > 1000);
  my $max_snp_distance = ($window_size / 2) * 100;
  $ldfca->max_snp_distance($max_snp_distance);

  my $ld_config = $c->config->{'Model::LDFeatureContainer'};
  if ($ld_config && $ld_config->{use_vcf}) {
    $ldfca->db->use_vcf($ld_config->{use_vcf});
    $Bio::EnsEMBL::Variation::DBSQL::VCFCollectionAdaptor::CONFIG_FILE = $ld_config->{vcf_config};
    $ENV{ENSEMBL_VARIATION_VCF_ROOT_DIR} = $ld_config->{dir} if (defined $ld_config->{dir});
  }
  my $variation = $va->fetch_by_name($variation_name);
  Catalyst::Exception->throw("Could not fetch variation object for id: $variation_name.") if ! $variation;
  my $vfs = $variation->get_all_VariationFeatures();
  Catalyst::Exception->throw("Variant maps more than once to the genome.") if (scalar @$vfs > 1);
  Catalyst::Exception->throw("Could not retrieve a variation feature.") if (scalar @$vfs == 0);
  my $vf = $vfs->[0];

  my $population_name = $c->request->param('population_name');
  if ($population_name) {
    my $pa = $c->model('Registry')->get_adaptor($species, 'Variation', 'Population');     
    my $population = $pa->fetch_by_name($population_name);
    if (!$population) {
      Catalyst::Exception->throw("Could not fetch population object for population name: $population_name");
    }
    my $ldfc;
    try {
      $ldfc = $ldfca->fetch_by_VariationFeature($vf, $population);
    } catch {
      warn "caught error: $_";
    };
    return $self->to_array($ldfc)
  }
  my $ldfc = $ldfca->fetch_by_VariationFeature($vf);
  return $self->to_array($ldfc);
}

sub to_array {
  my ($self, $LDFC) = @_;
  my $c = $self->context();
  my $species = $c->stash->{species};
  my $pa = $c->model('Registry')->get_adaptor($species, 'Variation', 'Population');
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
    my $population = $pa->fetch_by_dbID($population_id);
    $hash->{population_name} = $population->name;
    push @LDFC_array, $hash;
  }
  return \@LDFC_array;
}

with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;
