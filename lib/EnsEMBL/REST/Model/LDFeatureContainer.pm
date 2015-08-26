package EnsEMBL::REST::EnsemlModel::LDFeatureContainer;

use Moose;
use Catalyst::Exception qw(throw);
extends 'Catalyst::Model';

#with 'Catalyst::Component::InstancePerContext';

#has 'context' => (is => 'ro');

sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  return $self->new({ conext => $c, %$self, @args});
}

sub fetch_LDFeatureContainer_variation_name {
  my ($self, $variation_name) = @_;
  Catalyst::Exception->throw("No variation given. Please specify a variation to retrieve from this service") if ! $variation_name;
  my $c = $self->context();
  my $species = $c->stash->{species};
  my $va = $c->model('Registry')->get_adaptor($species, 'Variation', 'Variation');
  my $ldfca = $c->model('Registry')->get_adaptor($species, 'Variation', 'LDFeatureContainer');

  my $var_params = $c->config->{'Model::Variation'};
  if ($var_params && $var_params->{use_vcf}) {
    $ldfca->db->use_vcf($var_params->{use_vcf});
    $Bio::EnsEMBL::Variation::DBSQL::VCFCollectionAdaptor::CONFIG_FILE = $var_params->{vcf_config};
  }
  my $variation = $va->fetch_by_name($variation_name);
  Catalyst::Exception->throw("Could not fetch variation object for id: $variation_name.") if ! $variation;
  my $vfs = $variation->get_all_VariationFeatures();
  Catalyst::Exception->throw("Variant maps more than once to the genome.") if (scalar @$vfs > 1);
  Catalyst::Exception->throw("Could not retrieve a variation feature.") if (scalar @$vfs == 0);
  my $vf = $vfs->[0];

  my $d_prime = $c->request->param('d_prime');
  my $r2 = $c->request->param('r2');
  my @population_names = @{$c->request->param('population_id')};
  my @populations_ids = ();
  if (@population_names) {
    my $pa = $c->model('Registry')->get_adaptor($species, 'Variation', 'Population');     
    foreach my $name (@population_names) {
      my $population = $pa->fetch_by_name($name);
      if (!$population) {
        Catalyst::Exception->throw("Could not fetch population object for population name: $name");
      } else {
        push @population_ids, $population->dbID;
      }
    }
  }
  my $ldfc = $ldfca->fetch_by_VariationFeature($vf, );
  return $self->to_hash($ldfc);
}

sub fetch_LDFeatureContainer_slice {
  my ($self, $slice) = @_; 
  Catalyst::Exception->throw("No region given. Please specify a region to retrieve from this service") if ! $slice;
  $self->_config();
  my $c = $self->context();
  my $species = $c->stash->{species};
  my $ldfca = $c->model('Registry')->get_adaptor($species, 'Variation', 'LDFeatureContainer');
  my $var_params = $c->config->{'Model::Variation'};
  if ($var_params && $var_params->{use_vcf}) {
    $ldfca->db->use_vcf($var_params->{use_vcf});
    $Bio::EnsEMBL::Variation::DBSQL::VCFCollectionAdaptor::CONFIG_FILE = $var_params->{vcf_config};
  }
  my $ldfc = $ldfca->fetch_by_Slice($slice);
  return $self->to_hash($ldfc);
}

sub to_hash {
  my ($self, $LDFC) = @_;
  my $c = $self->context();
  my $LDFC_hash;
}

with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;
