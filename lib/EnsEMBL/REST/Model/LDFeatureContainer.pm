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
  Catalyst::Exception->throw("No variation given. Please specify a variation to retrieve from this service") if ! $variation_id;
  $self->_config();
  my $species = $c->stash->{species};
  my $va = $c->model('Registry')->get_adaptor($species, 'Variation', 'Variation');
  my $ldfca = $c->model('Registry')->get_adaptor($species, 'Variation', 'LDFeatureContainer');
  my $variation = $va->fetch_by_name($variation_name);
  Catalyst::Exception->throw("Could not fetch variation object.") if ! $variation_id;
  my $vfs = $variation->get_all_VariationFeatures();
  Catalyst::Exception->throw("Variant maps more than once to the genome.") if (scalar @$vfs > 1);
  Catalyst::Exception->throw("Could not retrieve a variation feature.") if (scalar @$vfs == 0);
  my $vf = $vfs->[0];
  my $ldfc = $ldfca->fetch_by_VariationFeature($vf);
  return $self->to_hash($ldfc);
}

sub fetch_LDFeatureContainer_slice {
  my ($self, $slice) = @_; 
  Catalyst::Exception->throw("No region given. Please specify a region to retrieve from this service") if ! $slice;
  $self->_config();
  my $species = $c->stash->{species};
  my $ldfca = $c->model('Registry')->get_adaptor($species, 'Variation', 'LDFeatureContainer');
  my $ldfc = $ldfca->fetch_by_Slice($slice);
  return $self->to_hash($ldfc);
}

sub _config {
  my $self = shift;
  my $c = $self->context();
  my $species = $c->stash->{species};

  # use VCF if requested in config
  my $var_params = $c->config->{'Model::Variation'};
  if ($var_params && $var_params->{use_vcf}) {
    $ldfca->db->use_vcf($var_params->{use_vcf});
    $Bio::EnsEMBL::Variation::DBSQL::VCFCollectionAdaptor::CONFIG_FILE = $var_params->{vcf_config};
  }
}

sub to_hash {
  my ($self, $LDFC, $d_prime, $r_square) = @_;
  my $c = $self->context();
  my $LDFC_hash;
}

with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;
