package EnsEMBL::REST::Model::Registry;

use Moose;
use namespace::autoclean;
use EnsEMBL::REST;
use feature 'switch';

extends 'Catalyst::Model';

has 'log' => ( is => 'ro', isa => 'Log::Log4perl::Logger', lazy => 1, default => sub {
  return Log::Log4perl->get_logger(__PACKAGE__);
});

has '_registry' => ( is => 'ro', lazy => 0, default => sub {
  my ($self) = @_;
  my $log = $self->log();
  $log->info('Loading the registry model object');
  my $class = 'Bio::EnsEMBL::Registry';
  Catalyst::Utils::ensure_class_loaded($class);
  $class->no_version_check(1);
  my $cfg = EnsEMBL::REST->config()->{Registry};
  if($cfg->{file}) {
    local $Bio::EnsEMBL::Registry::NEW_EVAL = 1;
    $log->info('Using the file location '.$cfg->{file});
    $class->load_all($cfg->{file});
  }
  elsif($cfg->{host}) {
    $log->info('Using host settings from the configuration file');
    $class->load_registry_from_db(
      -HOST => $cfg->{host},
      -PORT => $cfg->{port},
      -USER => $cfg->{user},
      -PASS => $cfg->{pass},  
      -DB_VERSION => $cfg->{version},
      -VERBOSE => $cfg->{verbose}
    );
  }
  else {
    confess "Cannot instantiate a registry. Please consult your configuration file and try again"
  }
  $self->_set_connection_policies($class, $cfg);
  return $class;
});

sub _set_connection_policies {
  my ($self, $registry, $cfg) = @_;
  
  my $log = $self->log();
  $log->info('Setting up connection policies');
  
  if($cfg->{disconnect_if_idle}) {
    $log->info('Setting all DBAdaptors to disconnect when inactive');
    $registry->set_disconnect_when_inactive();
  }
  
  if($cfg->{reconnect_when_lost}) {
    $log->info('Setting all DBAdaptors to reconnect when connections are lost');
    $registry->set_reconnect_when_lost();
  }
  
  if($cfg->{no_caching}) {
    $log->info('Stopping caching in all adaptors and clearing out existing caches');
    $registry->no_cache_warnings(1);
    foreach my $dba (@{$registry->get_all_DBAdaptors()}) {
      $dba->no_cache(1);
    }
  }
  
  if($cfg->{connection_sharing}) {
    $log->info('Connection sharing turned on');
    $self->_intern_db_connections($registry, $cfg);
  }
  
  return;
}

sub _intern_db_connections {
  my ($self, $registry, $cfg) = @_;
  my %single_connections;
  my $reconnect_interval = $cfg->{reconnect_interval} || 0;
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
    my $key = join(q{!=!}, map { ($dbc->$_() || q{?}) } qw/host port username password driver/ );
    if(! exists $single_connections{$key}) {
      $log->info(sprintf('New connection being generated for %s DB at %s@%s:%d', $dbc->driver(), $dbc->username(), $dbc->host(), $dbc->port()));
      $single_connections{$key} = $dbc;
    }
    my $new_dbc = Bio::EnsEMBL::DBSQL::ProxyDBConnection->new(-DBC => $single_connections{$key}, -DBNAME => $dbname, -RECONNECT_INTERVAL => $reconnect_interval);
    $dba->dbc($new_dbc);
  }
  return;
}

sub get_DBAdaptor {
  my ($self, $species, $group) = @_;
  return $self->_registry()->get_DBAdaptor($species, $group);
}

sub get_adaptor {
  my ( $self, $species, $group, $type ) = @_;
  return $self->_registry()->get_adaptor( $species, $group, $type );
}

sub get_species_and_object_type {
  my ( $self, $stable_id, $object_type, $species, $db_type, $force_long_lookup ) = @_;
  return $self->_registry()->get_species_and_object_type($stable_id,$object_type, $species, $db_type, $force_long_lookup);
}

sub get_species {
  my ($self) = @_;
  my @species;
  my $reg = $self->_registry();
  my $dbadaptors = $self->get_all_DBAdaptors('core');
  foreach my $dba (@{$dbadaptors}) {
    my $species = $dba->species();
    my $mc = $self->get_adaptor($species, 'core', 'metacontainer');
    my $info = {
      name => $species,
      release => $mc->get_schema_version(),
      aliases => $self->_registry()->get_all_aliases($species),
      groups  => [ map { $_->group() } @{$self->get_all_DBAdaptors(undef, $species)}]
    };
    push(@species, $info);
  }
  $self->disconnect_DBAdaptors($dbadaptors);
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

sub get_unique_schema_versions {
  my ($self) = @_;
  my %hash;
  my @dbadaptors = grep { $_->group() eq 'core' } @{$self->_registry()->get_all_DBAdaptors()};
  foreach my $dba (@dbadaptors) {
    $hash{$dba->get_MetaContainer()->get_schema_version()} = 1;
  }
  $self->disconnect_DBAdaptors(@dbadaptors);
  return [keys %hash];
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

__PACKAGE__->meta->make_immutable;

1;

