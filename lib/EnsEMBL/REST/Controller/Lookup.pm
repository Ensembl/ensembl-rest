package EnsEMBL::REST::Controller::Lookup;
use Moose;
use namespace::autoclean;
use Try::Tiny;

BEGIN {extends 'Catalyst::Controller::REST'; }

require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

sub id : Chained('') Args(1) PathPart('lookup/id') {
  my ($self, $c, $id) = @_;
  my ($species, $object_type, $db_type) = try {
    $c->model('Lookup')->find_object_location($id);
  }
  catch {
    $c->go('ReturnError', 'from_ensembl', [$_]);
  };
  $c->go('ReturnError', 'custom',  [qq{No valid lookup found for ID $id}]) unless $species;
  $self->status_ok( $c, entity => {id => $id, species => $species, object_type => $object_type, db_type => $db_type } ); 
}

sub id_GET {}

__PACKAGE__->meta->make_immutable;

1;
