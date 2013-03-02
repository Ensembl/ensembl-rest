package EnsEMBL::REST::Model::DatabaseIDLookup;

use Moose;
use namespace::autoclean;

extends 'Catalyst::Model';
with 'Catalyst::Component::InstancePerContext';

has 'long_lookup' => (isa => 'Bool', is => 'ro', builder => 'build_long_lookup');
has 'context' => (is => 'ro');

sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  return $self->new({ context => $c, %$self, @args });
}

sub build_long_lookup {
  return 0;
}

sub find_object_location {
  my ($self, $id, $object_type, $db_type, $species) = @_;
  my $reg = $self->context->model('Registry');
  
  my @captures;
  my $force_long_lookup = $self->long_lookup();
  
  if($object_type && $object_type eq 'predictiontranscript') {
    @captures = $self->find_prediction_transcript($id, $object_type, $db_type, $species);
  }
  else {
    $self->context->log->debug(sprintf('Looking for %s with %s and %s in %s', $id, ($object_type || q{?}), ($db_type || q{?}), ($species || q{?})));
    @captures = $reg->get_species_and_object_type($id, $object_type, $species, $db_type, $force_long_lookup);
  }
  
  return @captures;
}

sub find_prediction_transcript {
  my ($self, $id, $object_type, $db_type, $species) = @_;
  my $reg = $self->context->model('Registry');
  my $pred_trans_adaptor = $reg->get_adaptor($species, $db_type, $object_type);
  my $obj = $pred_trans_adaptor->fetch_by_stable_id($id);
  return ($species, $object_type, $db_type);
}

1;