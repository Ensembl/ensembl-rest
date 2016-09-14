=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
Copyright [2016] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::REST::Model::Registry;

use Moose;
use namespace::autoclean;
require EnsEMBL::REST;
our $LOOKUP_AVAILABLE = 0;
eval {
  require Bio::EnsEMBL::LookUp;
  require Bio::EnsEMBL::LookUp::RemoteLookUp;
  require Bio::EnsEMBL::DBSQL::TaxonomyDBAdaptor;
  require Bio::EnsEMBL::Utils::MetaData::DBSQL::GenomeInfoAdaptor;
  $LOOKUP_AVAILABLE = 1;
};
use feature 'switch';
use CHI;
use Bio::EnsEMBL::Utils::Exception qw/throw/;

extends 'Catalyst::Model';

has 'log' => ( is => 'ro', isa => 'Log::Log4perl::Logger', lazy => 1, default => sub {
  return Log::Log4perl->get_logger(__PACKAGE__);
});

# Manual host configuration
has 'host'    => ( is => 'ro', isa => 'Str' );
has 'port'    => ( is => 'ro', isa => 'Int' );
has 'user'    => ( is => 'ro', isa => 'Str' );
has 'pass'    => ( is => 'ro', isa => 'Str' );
has 'version' => ( is => 'ro', isa => 'Int' );
has 'verbose' => ( is => 'ro', isa => 'Bool' );

# File based config
has 'file' => ( is => 'ro', isa => 'Str' );

# Ensembl Genomes LookUp Support
has 'lookup_host'   => ( is => 'ro', isa => 'Str' );
has 'lookup_port'   => ( is => 'ro', isa => 'Int' );
has 'lookup_user'   => ( is => 'ro', isa => 'Str' );
has 'lookup_pass'   => ( is => 'ro', isa => 'Str' );
has 'lookup_dbname' => ( is => 'ro', isa => 'Str' );

# Avoid initiation of the registry
has 'skip_initation' => ( is => 'ro', isa => 'Bool' );

# Connection settings
has 'reconnect_interval'  => ( is => 'ro', isa => 'Num' );
has 'disconnect_if_idle'  => ( is => 'ro', isa => 'Bool' );
has 'reconnect_when_lost' => ( is => 'ro', isa => 'Bool' );
has 'no_caching'          => ( is => 'ro', isa => 'Bool' );
has 'connection_sharing'  => ( is => 'ro', isa => 'Bool' );
has 'no_version_check'    => ( is => 'ro', isa => 'Bool' );

# Preload settings
has 'preload'   => ( is => 'ro', isa => 'Bool', default => 1 );
has 'eqtl_dbs'  => (is => 'ro', isa => 'HashRef[Str]');

has '_eqtl_adaptors' => ( is => 'ro', isa => 'HashRef', lazy => 1, builder => '_get_eqtl_adaptor');

has 'compara_cache' => ( is => 'ro', isa => 'HashRef[Str]', lazy => 1, default => sub { {} });

has '_registry' => ( is => 'ro', lazy => 1, default => sub {
  my ($self) = @_;
  my $log = $self->log();
  $log->info('Loading the registry model object');
  my $class = 'Bio::EnsEMBL::Registry';
  Catalyst::Utils::ensure_class_loaded($class);
  $class->no_version_check(1);
  return $class if $self->skip_initation();

  my $load = 0;

  if($self->file()) {
    no warnings 'once';
    local $Bio::EnsEMBL::Registry::NEW_EVAL = 1;
    $log->info('Using the file location '.$self->file());
    $class->load_all($self->file());
    $load = 1;
  }
  elsif($self->host()) {
    $log->info('Using host settings from the configuration file');
    $class->load_registry_from_db(
      -HOST => $self->host(),
      -PORT => $self->port(),
      -USER => $self->user(),
      -PASS => $self->pass(),
      -DB_VERSION => $self->version(),
      -VERBOSE => $self->verbose()
    );
    $load = 1;
  }
  if(defined $self->lookup_host() && defined $self->lookup_port() && defined $self->lookup_dbname() && defined $self->lookup_user()) {
    if($LOOKUP_AVAILABLE) {
      $log->info('User submitted EnsemblGenomes lookup information. Building from this');
      $self->_lookup();
      $load = 1;
    }
    else {
      $log->error('You tried to use Bio::EnsEMBL::LookUp but this was not on your PERL5LIB');
    }
  }

  if(!$load) {
    confess "Cannot instantiate a registry; we have looked for configuration regarding a registry file, host information and ensembl genomes lookup. None were given. Please consult your configuration file and try again"
  }
  $self->_set_connection_policies($class);
  return $class;

});
has '_lookup' => ( is => 'rw', lazy => 1, builder => '_build_lookup');

has '_species_info' => ( isa => 'ArrayRef', is => 'ro', lazy => 1, builder => '_build_species_info' );

sub _get_eqtl_adaptor {

  my ($self) = @_;
  my $eqtl_adaptors = {};

  if(! $self->eqtl_dbs) {
    $self->log->debug("No EQTL database files defined. /eqtl endpoints will fail:\n");
    return {}
  }
  # load if not loaded
  Catalyst::Utils::ensure_class_loaded('Bio::EnsEMBL::HDF5::EQTLAdaptor');

  for my $user_species (sort keys %{$self->eqtl_dbs}) {

    my $ensembl_species   = $self->get_alias($user_species);
    if(!$ensembl_species){
      my $msg = "Species $user_species is not available in Ensembl. Please consult your config file.";
      $self->log->fatal($msg);
      confess $msg;
    }

    my $core_a = $self->get_DBAdaptor($ensembl_species, 'core');
    my $var_a  = $self->get_DBAdaptor($ensembl_species, 'variation');

    my $file   = $self->eqtl_dbs->{$user_species};
    my $eqtl_a = Bio::EnsEMBL::HDF5::EQTLAdaptor->new(
      -filename        => $file,
      -core_db_adaptor => $core_a,
      -var_db_adaptor  => $var_a,
      );

    if(ref($eqtl_a) ne 'Bio::EnsEMBL::HDF5::EQTLAdaptor'){
      confess 'Could not get Bio::EnsEMBL::HDF5::EQTLAdaptor';
    }

    $eqtl_adaptors->{$ensembl_species} = $eqtl_a;
  }
  return $eqtl_adaptors;
}

sub _set_connection_policies {
  my ($self, $registry) = @_;

  my $log = $self->log();
  $log->info('Setting up connection policies');

  if($self->disconnect_if_idle()) {
    $log->info('Setting all DBAdaptors to disconnect when inactive');
    $registry->set_disconnect_when_inactive();
  }

  if($self->reconnect_when_lost()) {
    $log->info('Setting all DBAdaptors to reconnect when connections are lost');
    $registry->set_reconnect_when_lost();
  }

  if($self->no_caching()) {
    $log->info('Stopping caching in all adaptors and clearing out existing caches');
    $registry->no_cache_warnings(1);
    foreach my $dba (@{$registry->get_all_DBAdaptors()}) {
      $dba->no_cache(1);
    }
  }

  if($self->connection_sharing()) {
    $log->info('Connection sharing turned on');
    $self->_intern_db_connections($registry);
  }

  return;
}

sub _intern_db_connections {
  my ($self, $registry) = @_;
  my %single_connections;
  my $reconnect_interval = $self->reconnect_interval() || 0;
  Catalyst::Utils::ensure_class_loaded('Bio::EnsEMBL::DBSQL::ProxyDBConnection');
  my $log = $self->log();
  if($reconnect_interval) {
    $log->info('Using reconnect_interval of '.$reconnect_interval);
  }
  foreach my $dba (@{$registry->get_all_DBAdaptors()}) {
    my $dbc = $dba->dbc();
    my $dbname = $dbc->dbname();
    next unless $dbname; #skip if it had no DBNAME
    $dbc->disconnect_if_idle();
    my $key = join(q{!=!}, map { ($dbc->$_() || q{?}) } qw(host port username password driver) );
    if(! exists $single_connections{$key}) {
      $log->info(sprintf('New connection being generated for %s DB at %s@%s:%d', $dbc->driver(), $dbc->username(), $dbc->host(), $dbc->port()));
      $single_connections{$key} = $dbc;
    }
    my $new_dbc = Bio::EnsEMBL::DBSQL::ProxyDBConnection->new(-DBC => $single_connections{$key}, -DBNAME => $dbname, -RECONNECT_INTERVAL => $reconnect_interval);
    $dba->dbc($new_dbc);
  }
  return;
}

sub _build_lookup {
  my ($self) = @_;

  my $info_db =
	Bio::EnsEMBL::DBSQL::DBConnection->new(
									   -USER   => $self->lookup_user(),
									   -PASS   => $self->lookup_pass(),
									   -HOST   => $self->lookup_host(),
									   -PORT   => $self->lookup_port(),
									   -DBNAME => $self->lookup_dbname()
	);

  $info_db->reconnect_when_lost(1);

  my $tax_dba =
	Bio::EnsEMBL::DBSQL::TaxonomyDBAdaptor->new(
										  -USER   => $self->lookup_user(),
										  -PASS => $self->lookup_pass(),
										  -HOST => $self->lookup_host(),
										  -PORT => $self->lookup_port(),
										  -DBNAME => 'ncbi_taxonomy' );
  $tax_dba->dbc()->reconnect_when_lost(1);

  my $lookup =
	Bio::EnsEMBL::LookUp::RemoteLookUp->new(
		   Bio::EnsEMBL::Utils::MetaData::DBSQL::GenomeInfoAdaptor->new(
				 -DBC             => $info_db,
				 TAXONOMY_ADAPTOR => $tax_dba->get_TaxonomyNodeAdaptor()
		   ) );
  return $lookup;
} ## end sub _build_lookup

# Logic here is if we were told a compara name we use that
# If not we query the species for the "best" compara (normally depends on division)
# If no hit and the queried name was different from the default name then try that
# Return if we got a hit otherwise throw an error
sub get_best_compara_DBAdaptor {
  my ($self, $species, $request_compara_name, $default_compara) = @_;
  $default_compara = 'multi' if ! defined $default_compara;
  my $compara_name = $request_compara_name || $self->get_compara_name_for_species($species);
  if(!$compara_name) {
    throw "Cannot find a suitable compara database for the species $species. Try specifying a compara parameter";
  }
  my $dba = $self->get_DBAdaptor($compara_name, 'compara', 'no alias check');

  # If the compara name we used was not the same then we've got another bite at the cherry
  if(! $dba && $compara_name ne $default_compara) {
    $dba = $self->get_DBAdaptor($default_compara, 'compara', 'no alias check');
  }

  # Throw an error if we had no DBAdaptor
  if(!$dba) {
    throw "Cannot find a database adaptor for $compara_name or $default_compara. Please contact the server admin with this error message and URL";
  }

  return $dba;
}

sub get_DBAdaptor {
  my ($self, $species, $group, $no_alias_check) = @_;
  return $self->_registry()->get_DBAdaptor($species, $group, $no_alias_check);
}

sub get_adaptor {
  my ( $self, $species, $group, $type ) = @_;
  return $self->_registry()->get_adaptor( $species, $group, $type );
}

sub get_species_and_object_type {
  my ( $self, $stable_id, $object_type, $species, $db_type, $force_long_lookup, $use_archive ) = @_;
  return $self->_registry()->get_species_and_object_type($stable_id,$object_type, $species, $db_type, $force_long_lookup, $use_archive);
}

sub get_species {
  my ($self, $division) = @_;
  my $info = $self->_species_info();
  #have to force numerification again. It got lost ... somewhere
  return [ grep { $_ > 0 } map {$_->{release} += 0; $_} @{$info} ] unless $division;
  return [ grep { $_ > 0 } map {$_->{release} += 0; $_} grep { lc($_->{division}) eq lc($division) } @{$info}];
}

sub _build_species_info {
  my ($self) = @_;
  my @species;
  my $reg = $self->_registry();

  #Aliases is backwards i.e. alias -> species
  my %alias_lookup;
  while (my ($alias, $species) = each %{ $Bio::EnsEMBL::Registry::registry_register{_ALIAS} }) {
      push(@{$alias_lookup{$species}}, $alias); # iterate through the alias,species pairs & reverse
  }

  my @all_dbadaptors = grep {$_->dbc->dbname ne 'ncbi_taxonomy'} @{$Bio::EnsEMBL::Registry::registry_register{_DBA}};
  my @core_dbadaptors;
  my (%groups_lookup, %division_lookup, %common_lookup, %taxon_lookup, %display_lookup, %release_lookup, %assembly_lookup, %accession_lookup);
  my %processed_db;
  while(my $dba = shift @all_dbadaptors) {
    my $species = $dba->species();
    my $group = $dba->group();
    my $species_lc = ($species);
    push(@{$groups_lookup{$species_lc}}, $group);

    if($group eq 'core' && $species !~ /Ancestral/) {
      push(@core_dbadaptors, $dba);
      my $dbc = $dba->dbc();
      my $db_key = sprintf(
          "host=%s;port=%s;dbname=%s;user=%s;pass=%s",
          $dbc->host(),    $dbc->port(),
          $dbc->dbname(),  $dbc->username(), $dbc->password());

      if(! exists $processed_db{$db_key}) {
        my $mc = $dba->get_MetaContainer();
        my $schema_version = $mc->get_schema_version() * 1;

        if(!$dba->is_multispecies() && $species !~ /Ancestral/) {
          my $csa = $dba->get_CoordSystemAdaptor();
          $release_lookup{$species} = $schema_version;
          $division_lookup{$species} = $mc->get_division() || 'Ensembl';
          $common_lookup{$species} = $mc->get_common_name();
          $taxon_lookup{$species} = $mc->get_taxonomy_id();
          $display_lookup{$species} = $mc->get_display_name();
          $assembly_lookup{$species} = $csa->get_default_version();
          $accession_lookup{$species} = $mc->single_value_by_key('assembly.accession');
        }
        else {
          $dbc->sql_helper->execute_no_return(
            -SQL => q/select m1.meta_value, m2.meta_value, m3.meta_value, m4.meta_value
		from meta m1, meta m2, meta m3, meta m4
		where
		m1.species_id = m2.species_id
		and m1.species_id = m3.species_id
		and m1.species_id = m4.species_id
		and m1.meta_key = ?
		and m2.meta_key = ?
		and m3.meta_key = ?
		and m4.meta_key = ?/,
            -PARAMS => ['species.production_name', 'species.division', 'species.display_name', 'species.taxonomy_id'],
            -CALLBACK => sub {
              my ($row) = @_;
              $division_lookup{$row->[0]} = $row->[1];
              $display_lookup{$row->[0]} = $row->[2];
              $taxon_lookup{$row->[0]} = $row->[3];
              $release_lookup{$row->[0]} = $schema_version;
              return;
            }
          );
          $dbc->sql_helper->execute_no_return(
            -SQL => 'select m1.meta_value, m2.meta_value from meta m1 join meta m2 on (m1.species_id = m2.species_id) where m1.meta_key = ? and m2.meta_key =?',
            -PARAMS => ['species.production_name', 'assembly.default'],
            -CALLBACK => sub {
              my ($row) = @_;
              $assembly_lookup{$row->[0]} = $row->[1];
              return;
            }
          );
          $dbc->sql_helper->execute_no_return(
            -SQL => 'select m1.meta_value, m2.meta_value from meta m1 join meta m2 on (m1.species_id = m2.species_id) where m1.meta_key = ? and m2.meta_key =?',
            -PARAMS => ['species.production_name', 'assembly.accession'],
            -CALLBACK => sub {
              my ($row) = @_;
              $accession_lookup{$row->[0]} = $row->[1];
              return;
            }
          );
          $dbc->sql_helper->execute_no_return(
            -SQL => 'select m1.meta_value, m2.meta_value from meta m1 join meta m2 on (m1.species_id = m2.species_id) where m1.meta_key = ? and m2.meta_key =?',
            -PARAMS => ['species.production_name', 'species.common_name'],
            -CALLBACK => sub {
              my ($row) = @_;
              $common_lookup{$row->[0]} = $row->[1];
              return;
            }
          );
        }
        $processed_db{$db_key} = 1;
      }
    }
  }

  foreach my $dba (@core_dbadaptors) {
    my $species = $dba->species();
    my $species_lc = ($species);
    my $aliases_to_skip = {
        $species => 1,
    };
    if ($assembly_lookup{$species}) {   # Species like "Ancestral sequences" are not in %assembly_lookup
        # Automatically added by the Compara API when the Compara objects are preloaded.
        $aliases_to_skip->{ lc "$species $assembly_lookup{$species}" } = 1;
    }
    my $good_aliases = [grep {!$aliases_to_skip->{$_}} @{$alias_lookup{$species} || []}];
    my $info = {
      name => $species,
      release => $release_lookup{$species},
      aliases => $good_aliases,
      groups  => $groups_lookup{$species},
      division => $division_lookup{$species},
      common_name => $common_lookup{$species},
      display_name => $display_lookup{$species},
      taxon_id => $taxon_lookup{$species},
      accession => $accession_lookup{$species},
      assembly => $assembly_lookup{$species}
    };
    push(@species, $info);
  }

  return \@species;
}

sub get_comparas {
  my ($self) = @_;
  my @comparas;
  my $reg = $self->_registry();
  my $dbadaptors = $self->get_all_DBAdaptors('compara');
  foreach my $dba (@{$dbadaptors}) {
    my $name = $dba->species();
    my $mc = $self->get_adaptor($name, 'compara', 'metacontainer');
    my $info = {
      name => $name,
      release => $mc->get_schema_version(),
    };
    push(@comparas, $info);
  }
  $self->disconnect_DBAdaptors($dbadaptors);
  return \@comparas;
}

sub get_compara_name_for_species {
  my ($self, $species) = @_;
  if(! exists $self->compara_cache()->{$species}) {
    my $mc = $self->get_adaptor($species, 'core', 'metacontainer');
    my $compara_group = 'multi';
    my $division = $mc->single_value_by_key('species.division');
    if($division and $division ne 'Ensembl') {
      $division =~ s/^Ensembl//;
      $compara_group = lc($division);
    }
    $self->compara_cache()->{$species} = $compara_group;
  }

  return $self->compara_cache()->{$species};
}

sub get_unique_schema_versions {
  my ($self) = @_;
  my %hash;
  my $species_info = $self->_species_info();
  foreach my $species (@{$species_info}) {
    $hash{$species->{release}} = 1;
  }
  return [map { $_ *1 } keys %hash];
}

sub get_all_adaptors_by_type {
  my ($self, $species, $type) = @_;
  my $registry = $self->_registry();
  return [] if ! $registry->alias_exists($species);
  return $registry->get_all_adaptors(-species => $species, -type => $type);
}

sub get_all_DBAdaptors {
  my ($self, $group, $species) = @_;
  my %args;
  $args{-GROUP} = $group if $group;
  $args{-SPECIES} = $species if $species;
  return $self->_registry()->get_all_DBAdaptors(%args);
}

sub map_all_DBAdaptors {
  my ($self, $group, $filter) = @_;
  my $db_adaptors = $self->get_all_DBAdaptors($group);
  my @results = map { $filter->($_) } @{$db_adaptors};
  $self->disconnect_DBAdaptors($db_adaptors);
  return @results;
}

sub get_ontology_term_adaptor {
  my ($self) = @_;
  return $self->get_adaptor('multi','ontology', 'ontologyterm');
}

sub disconnect_DBAdaptors {
  my ($self, @db_adaptors) = @_;
  foreach my $dba (@db_adaptors) {
    next if ! defined $dba;
    if(ref($dba) eq 'ARRAY') {
      $self->disconnect_DBAdaptors(@{$dba});
      next;
    }
    $dba->dbc()->disconnect_if_idle();
  }
  return;
}

sub get_alias {
  my ($self, $alias) = @_;
  my $reg = $self->_registry();
  if($reg->alias_exists($alias)) {
    return $reg->get_alias($alias);
  }
  return;
}

after 'BUILD' => sub {
  my ($self) = @_;
  if($self->preload()) {
    my $log = $self->log();
    $log->info('Triggering preload of the registry');
    $self->_registry();
    $_->get_MethodLinkSpeciesSetAdaptor()->fetch_all() for @{ $self->get_all_DBAdaptors('compara') };
    $self->_build_species_info();
    $self->_eqtl_adaptors();
    $log->info('Done');
  }
  return;
};

sub get_eqtl_adaptor {
  my ($self, $species) = @_;

  return $self->_eqtl_adaptors->{$species};
}

__PACKAGE__->meta->make_immutable;

1;

