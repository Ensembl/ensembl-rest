package EnsEMBL::REST::Model::Lookup;

use Moose;
use namespace::autoclean;
use Try::Tiny;

extends 'Catalyst::Model';

sub find_genetree_by_stable_id {
  my ($self, $c, $id) = @_;
  my $gt;
  my $compara_name = $c->stash->{compara};
  my $reg = $c->model('Registry');
  
  #Force search to use compara as the DB type
  $c->request->parameters->{db_type} = 'compara' if ! $c->request->parameters->{db_type};
  
  #Try to do a lookup if the ID DB is there
  my $lookup = $reg->get_DBAdaptor('multi', 'stable_ids', 1);
  if($lookup) {
    my ($species, $object_type, $db_type) = $self->find_object_location($c, $id);
    if($species) {
      my $gta = $reg->get_adaptor($species, $db_type, $object_type);
      $c->go('ReturnError', 'custom', ["No adaptor found for ID $id, species $species, object $object_type and db $db_type"]) if ! $gta;
      $gt = $gta->fetch_by_stable_id($id);
    }
  }
  
  #If we haven't got one then do a linear search
  if(! $gt) {
    my $comparas = $c->model('Registry')->get_all_DBAdaptors('compara', $compara_name);
    foreach my $c (@{$comparas}) {
      my $gta = $c->get_GeneTreeAdaptor();
      $gt = $gta->fetch_by_stable_id($id);
      last if $gt;
    }
  }
  return $gt if $gt;
  $c->go('ReturnError', 'custom', ["No GeneTree found for ID $id"]);
}

# uses the request for more optional arguments
sub find_object_by_stable_id {
  my ($self, $c, $id) = @_;
  my $reg = $c->model('Registry');
  my ($species, $type, $db) = $self->find_object_location($c, $id);
  $c->go('ReturnError', 'custom', [qq{Not possible to find an object with the ID '$id' in this release}]) unless $species;
  my $adaptor = $reg->get_adaptor($species, $db, $type);
  $c->log()->debug('Found an adaptor '.$adaptor);
  my $final_obj = $adaptor->fetch_by_stable_id($id);
  $c->go('ReturnError', 'custom', ["No object found for ID $id"]) unless $final_obj;
  $c->stash()->{object} = $final_obj;
  return $final_obj;
}

sub find_object_location {
  my ($self, $c, $id, $no_long_lookup) = @_;
  my $r = $c->request;
  my $object_type = $r->param('object_type');
  my $db_type = $r->param('db_type');
  my $species = $r->param('species');
  my $reg = $c->model('Registry');
  
  my @captures;
  my $force_long_lookup = 0;
  
  if($object_type && $object_type eq 'predictiontranscript') {
    my $pred_trans_adaptor = $reg->get_adaptor($species, $db_type, $object_type);
    my $obj = $pred_trans_adaptor->fetch_by_stable_id($id);
    @captures = ($species, $object_type, $db_type);
  }
  else {
    $c->log()->debug(sprintf('Looking for %s with %s and %s', $id, ($object_type || q{?}), ($db_type || q{?})));
    @captures = $reg->get_species_and_object_type($id, $object_type, $species, $db_type);
    $force_long_lookup = 1 unless $no_long_lookup;
  }
  
  if(@captures && $captures[0]) {
    $c->log()->debug(sprintf('Found %s, %s and %s', @captures));
  }
  else {
    $c->log()->debug('Retrying with a long lookup forced on');
    @captures = $reg->get_species_and_object_type($id, $object_type, $species, $db_type, $force_long_lookup);
  }
  
  if(@captures && $captures[0]) {
    $c->log()->debug(sprintf('Found %s, %s and %s', @captures));
  }
  else {
    $c->log()->debug('Found no ID');
  }
  
  return @captures;
}

sub find_slice {
  my ($self, $c, $region) = @_;
  my $s = $c->stash();
  my $species = $s->{species};
  my $db_type = $s->{db_type} || 'core';
  my $adaptor = $c->model('Registry')->get_adaptor($species, $db_type, 'slice');
  $c->go('ReturnError', 'custom', ["Do not know anything about the species $species and core database"]) unless $adaptor;
  my $slice = $adaptor->fetch_by_toplevel_location($region);
  $c->go('ReturnError', 'custom', ["No slice found for location $region"]) unless $slice;
  $s->{slice} = $slice;
  return $slice;
}

sub decode_region {
  my ($self, $c, $region, $no_warnings, $no_errors) = @_;
  my $s = $c->stash();
  my $species = $s->{species};
  my $adaptor = $c->model('Registry')->get_adaptor($species, 'core', 'slice');
  $c->go('ReturnError', 'custom', ["Do not know anything about the species $species and core database"]) unless $adaptor;
  my ($sr_name, $start, $end, $strand) = $adaptor->parse_location_to_values($region, $no_warnings, $no_errors);
  $strand = 1 if ! defined $strand;
  $c->go('ReturnError', 'custom', ["Could not decode region $region"]) unless $sr_name;
  $s->{sr_name} = $sr_name;
  $s->{start} = $start;
  $s->{end} = $end;
  $s->{strand}= $strand;
  return ($sr_name, $start, $end, $strand);
}

__PACKAGE__->meta->make_immutable;

1;