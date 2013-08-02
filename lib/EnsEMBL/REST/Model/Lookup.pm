package EnsEMBL::REST::Model::Lookup;

use Moose;
use namespace::autoclean;
use Try::Tiny;

extends 'Catalyst::Model';
with 'Catalyst::Component::InstancePerContext';

# Config
has 'lookup_model' => ( is => 'ro', isa => 'Str', required => 1, default => 'DatabaseIDLookup' );

# Per instance variables
has 'context' => (is => 'ro');

sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  return $self->new({ context => $c, %$self, @args });
}

sub find_genetree_by_stable_id {
  my ($self, $id) = @_;
  my $gt;
  my $c = $self->context();
  my $compara_name = $c->request->parameters->{compara};
  my $reg = $c->model('Registry');
  
  #Force search to use compara as the DB type
  $c->request->parameters->{db_type} = 'compara' if ! $c->request->parameters->{db_type};
  
  #Try to do a lookup if the ID DB is there
  my $lookup = $reg->get_DBAdaptor('multi', 'stable_ids', 1);
  if($lookup) {
    my ($species, $object_type, $db_type) = $self->find_object_location($id);
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

sub find_genetree_by_member_id {
  my ($self,$id) = @_;
  my $c = $self->context();
  my $compara_name = $c->request->parameters->{compara}; 
  my $reg = $c->model('Registry');
 
  my ($species, $type, $db) = $c->model('Lookup')->find_object_location($id);
  $c->go('ReturnError', 'custom', ["Unable to find given object: $id"]) unless $species;
  
  my $dba = $reg->get_best_compara_DBAdaptor($species,$compara_name);
  my $ma = $dba->get_GeneMemberAdaptor;
  my $member = $ma->fetch_by_source_stable_id('ENSEMBLGENE',$id);
  $c->go('ReturnError', 'custom', ["Could not fetch GeneTree Member"]) unless $member;
  
  my $gta = $dba->get_GeneTreeAdaptor;
  my $gt = $gta->fetch_default_for_Member($member);
  return $gt;
}


#Find all the Method objects in the compara database
sub find_compara_methods {
  my ($self, $class) = @_;

  my $c = $self->context();

  #default is "multi"
  my $compara = $c->request->parameters->{compara} || 'multi'; 
  my $reg = $c->model('Registry');

  my $compara_dba = $reg->get_DBAdaptor($compara, "compara");
  my $methods = $compara_dba->get_MethodAdaptor->fetch_all_by_class_pattern($class);

  return $methods;
}

#Find all the species_set_groups for this method in the compara database 
sub find_compara_species_set_groups {
  my ($self, $method) = @_;

  my $c = $self->context();
  #default is "multi"
  my $compara = $c->request->parameters->{compara} || 'multi';

  my $reg = $c->model('Registry');

  my $compara_dba = $reg->get_DBAdaptor($compara, "compara");

  my $species_set_groups;

  #Get MethodLinkSpeciesSet object
  my $mlsss = $compara_dba->get_MethodLinkSpeciesSetAdaptor->fetch_all_by_method_link_type($method);
  foreach my $mlss (@$mlsss) {
    my $species_set = $mlss->species_set_obj();
    #find tag with value 'name'
    my $tag = $species_set->get_value_for_tag('name');
    push @$species_set_groups, $tag if ($tag);
  }
  return $species_set_groups if $species_set_groups;

  $c->go('ReturnError', 'custom', ["No species_set_groups found for method $method"]);

}

#Find all the species_sets for this method in the compara database 
sub find_compara_species_sets {
  my ($self, $method) = @_;

  my $c = $self->context();
  #default is "multi"
  my $compara = $c->request->parameters->{compara} || 'multi';

  my $reg = $c->model('Registry');

  my $compara_dba = $reg->get_DBAdaptor($compara, "compara");

  my $species_sets;

  #Get MethodLinkSpeciesSet object
  my $mlsss = $compara_dba->get_MethodLinkSpeciesSetAdaptor->fetch_all_by_method_link_type($method);
  foreach my $mlss (@$mlsss) {
    my $species_set;
    foreach my $genome_db (@{$mlss->species_set_obj->genome_dbs}) {
      push @$species_set,  $genome_db->name;
    }
    push @$species_sets, $species_set;
  }
  return $species_sets;
}

#Find all MethodLinkSpeciesSet objects for this method in the compara database
sub find_compara_method_link_species_sets {
  my ($self, $method) = @_;

  my $c = $self->context();
  #default is "multi"
  my $compara = $c->request->parameters->{compara} || 'multi'; 
  my $reg = $c->model('Registry');

  my $compara_dba = $reg->get_DBAdaptor($compara, "compara");

  my $method_link_species_set_array;
  my $mlsss = $compara_dba->get_MethodLinkSpeciesSetAdaptor->fetch_all_by_method_link_type($method);
  foreach my $mlss (@$mlsss) {
    #get species_set_group
    my $species_set_obj = $mlss->species_set_obj();
    my $tag = $species_set_obj->get_value_for_tag('name');
    
    #get species_set
    my $species_set;
    foreach my $genome_db (@{$mlss->species_set_obj->genome_dbs}) {
      push @$species_set,  $genome_db->name;
    }
    
    my $method_link_species_set;
    %$method_link_species_set = ("id" => ($mlss->dbID*1),
				 "name" => $mlss->name,
				 "method" => $method,
			         "species_set" => $species_set);
    $method_link_species_set->{"species_set_group"} = $tag if ($tag);
    push @$method_link_species_set_array, $method_link_species_set;
  }
  return $method_link_species_set_array;
}

# uses the request for more optional arguments
sub find_object_by_stable_id {
  my ($self, $id) = @_;
  my $c = $self->context();
  my $reg = $c->model('Registry');
  my ($species, $type, $db) = $self->find_object_location($id);
  return $self->find_object($id, $species, $type, $db);
}

sub find_object {
  my ($self, $id, $species, $type, $db) = @_;
  my $c = $self->context();
  my $reg = $c->model('Registry');
  $c->go('ReturnError', 'custom', [qq{Not possible to find an object with the ID '$id' in this release; no species found}]) unless $species;
  my $adaptor = $reg->get_adaptor($species, $db, $type);
  $c->log()->debug('Found an adaptor '.$adaptor);
  if(! $adaptor->can('fetch_by_stable_id')) {
    $c->go('ReturnError', 'custom', ["Object, $type, type's adaptor does not support fetching by a stable ID for ID '$id'"]);
  }
  my $final_obj = $adaptor->fetch_by_stable_id($id);
  $c->go('ReturnError', 'custom', ["No object found for ID $id"]) unless $final_obj;
  $c->stash()->{object} = $final_obj;
  return $final_obj;
}

sub find_objects_by_symbol {
  my ($self, $symbol) = @_;
  my $c = $self->context();
  my $db_type = $c->request->param('db_type') || 'core';
  my $external_db = $c->request->param('external_db');
  my @entries;  
  my @objects_to_try = $c->request->param('object') ? ($c->request->param('object')) : qw(gene transcript translation);
  foreach my $object_type (@objects_to_try) {
    my $object_adaptor = $c->model('Registry')->get_adaptor($c->stash->{'species'}, $db_type, $object_type);
    my $objects_linked_to_symbol = $object_adaptor->fetch_all_by_external_name($symbol, $external_db);
    while(my $obj = shift @{$objects_linked_to_symbol}) {
      $c->log()->debug("Found by symbol ".$symbol." ".$obj);
      push(@entries, $obj);
    }
  }
  
  return \@entries;
}
  

sub find_object_location {
  my ($self, $id, $no_long_lookup) = @_;
  my $c = $self->context();
  my $r = $c->request;
  my $log = $c->log();

  my ($object_type, $db_type, $species) = map { my $p = $r->param($_); $p; } qw/object_type db_type species/;
  my @captures;
  if($object_type && $object_type eq 'predictiontranscript') {
    @captures = $c->model('LongDatabaseIDLookup')->find_object_location($id, $object_type, $db_type, $species);
  }
  else {
    $c->log()->debug(sprintf('Looking for %s with %s and %s in %s', $id, ($object_type || q{?}), ($db_type || q{?}), ($species || q{?})));
    my $model_name = $self->lookup_model();
    $c->log()->debug('Using '.$model_name);
    my $lookup = $c->model($model_name);
    @captures = $lookup->find_object_location($id, $object_type, $db_type, $species);
    if(! @captures) {
      $c->log()->debug('Using long database lookup');
      @captures = $c->model('LongDatabaseIDLookup')->find_object_location($id, $object_type, $db_type, $species);
    }
  }

  if($log->is_debug()) {
    if(@captures && $captures[0]) {
      $log->debug(sprintf('Found %s, %s and %s', @captures));
    }
    else {
      $log->debug('Found no ID');
    }
  }

  return @captures;
}

sub find_slice {
  my ($self, $region) = @_;
  my $c = $self->context();
  my $s = $c->stash();
  # don't do this.
  my $species = $s->{species};
  # or this
  my $db_type = $s->{db_type} || 'core';
  my $adaptor = $c->model('Registry')->get_adaptor($species, $db_type, 'slice');
  $c->go('ReturnError', 'custom', ["Do not know anything about the species $species and core database"]) unless $adaptor;
  my $coord_system_name = $c->request->param('coord_system') || 'toplevel';
  my $coord_system_version = $c->request->param('coord_system_version');
  my ($no_warnings, $no_fuzz, $ucsc_matching) = (undef, undef, 1);
  my $slice = $adaptor->fetch_by_location($region, $coord_system_name, $coord_system_version, $no_warnings, $no_fuzz, $ucsc_matching);
  $c->go('ReturnError', 'custom', ["No slice found for location $region"]) unless $slice;
  $s->{slice} = $slice;
  return $slice;
}

sub decode_region {
  my ($self, $region, $no_warnings, $no_errors) = @_;
  my $c = $self->context();
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

sub ontology_accession_to_OntologyTerm {
  my ($self, $accession) = @_;
  my $c = $self->context();
  my $term_adaptor = $c->model('Registry')->get_ontology_term_adaptor();
  return $term_adaptor->fetch_by_accession($accession);
}

__PACKAGE__->meta->make_immutable;

1;
