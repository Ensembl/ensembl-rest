package EnsEMBL::REST::Controller::Lookup;
use Moose;
use namespace::autoclean;
use Try::Tiny;

BEGIN {extends 'Catalyst::Controller::REST'; }

require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

my $FORMAT_TYPES = { full => 1, condensed => 1 };

sub old_id_GET {}

sub old_id : Chained('') Args(1) PathPart('lookup') {
  my ($self, $c, $id) = @_;
  $c->go('/lookup/id', $id);
}

sub id : Chained('') Args(1) PathPart('lookup/id') {
  my ($self, $c, $id) = @_;

  # output format check
  my $format = $c->request->param('format') || 'condensed';
  $c->go('ReturnError', 'custom', [qq{The format '$format' is not an understood encoding}]) unless $FORMAT_TYPES->{$format};

  my $entity;
  try {
    my ($species, $object_type, $db) = $c->model('Lookup')->find_object_location($id);
    $c->go('ReturnError', 'custom',  [qq{No valid lookup found for ID $id}]) unless $species;
    $entity = {
      id          => $id,
      species     => $species,
      object_type => $object_type,
      db_type     => $db
    };
    
    if($format eq 'full') {
      my $obj = $c->model('Lookup')->find_object($id, $species, $object_type, $db);
      if($obj->can('summary_as_hash')) {
        my $summary_hash = $obj->summary_as_hash();
        $entity->{seq_region_name} = $summary_hash->{seq_region_name};
        $entity->{start} = $summary_hash->{start};
        $entity->{end} = $summary_hash->{end};
        $entity->{strand} = $summary_hash->{strand};
      }
      else {
        $c->go('ReturnError','custom',[qq{ID '$id' does not support 'full' format type. Please use 'condensed'}]);
      }
    }
  }
  catch {
    $c->go('ReturnError', 'from_ensembl', [$_]);
  };
  
  $self->status_ok( $c, entity => $entity);
}

sub id_GET {}

__PACKAGE__->meta->make_immutable;

1;
