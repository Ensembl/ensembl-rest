package EnsEMBL::REST::Model::LDFeatureContainer;

use Moose;
use namespace::autoclean;
use Try::Tiny;

use Catalyst::Exception qw(throw);
extends 'Catalyst::Model';

with 'Catalyst::Component::InstancePerContext';

has 'context' => (is => 'ro');

sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  return $self->new({ context => $c, %$self, @args });
}

sub fetch_LDFeatureContainer_variation_name {
  my ($self, $variation_name) = @_;
  Catalyst::Exception->throw("No variation given. Please specify a variation to retrieve from this service") if ! $variation_name;
  my $c = $self->context();
  my $species = $c->stash->{species};

  my $va = $c->model('Registry')->get_adaptor($species, 'Variation', 'Variation');
  my $ldfca = $c->model('Registry')->get_adaptor($species, 'Variation', 'LDFeatureContainer');
  my $max_snp_distance = 25_000;
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
  foreach my $ld_hash (@{$LDFC->get_all_ld_values()}) {
    my $hash = {};
    $hash->{d_prime} = $ld_hash->{d_prime};
    next if ($d_prime && $hash->{d_prime} < $d_prime);
    $hash->{r2} = $ld_hash->{r2};
    next if ($r2 && $hash->{r2} < $r2);
    $hash->{variation1} = $ld_hash->{variation1}->variation_name; 
    $hash->{variation2} = $ld_hash->{variation2}->variation_name; 
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
