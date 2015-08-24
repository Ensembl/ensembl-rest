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

sub fetch_LDFeatureContainer_variation_id {
  my ($self, $variation_id) = @_;

  Catalyst::Exception->throw("No variation given. Please specify a variation to retrieve from this service") if ! $variation_id;

  my $ldfca = $self->_LDFCA();

  my $ldfc = $lfdca->fetch_by_VariationFeature();

  return $self->to_hash($ldfc);
}

sub fetch_LDFeatureContainer_region {
  my ($self, $region) = @_; 
    

}

# return LDFeatureContainerAdaptor
sub _LDFCA {
  my $self = shift;
  my $c = $self->context();
  my $species = $c->stash->{species};

  my $ldfca = $c->model('Registry')->get_adaptor($species, 'Variation', 'LDFeatureContainer');

  # use VCF if requested in config
  my $var_params = $c->config->{'Model::Variation'};
  if ($var_params && $var_params->{use_vcf}) {
    $ldfca->db->use_vcf($var_params->{use_vcf});
    $Bio::EnsEMBL::Variation::DBSQL::VCFCollectionAdaptor::CONFGI_FILE = $var_params->{vcf_config};
  }
  return $ldfca;
}

sub to_hash {
  my ($self, $LDFC, $d_prime, $r_square) = @_;
  my $c = $self->context();
  my $LDFC_hash;
 
  
 
  
}




