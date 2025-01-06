=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2025] EMBL-European Bioinformatics Institute

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
use feature 'switch';
use CHI;
use DBI qw(:sql_types);
use Try::Tiny;
use Bio::EnsEMBL::Utils::Exception qw/throw/;
use EnsEMBL::REST::RegistryHelper;

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

has 'compara_cache' => ( is => 'ro', isa => 'HashRef[Str]', lazy => 1, default => sub { {} });

has '_registry' => ( is => 'ro', lazy => 1, builder => '_load_registry');

sub _load_registry {
  my ($self) = @_;
  my $log = $self->log();
  $log->info('Loading the registry model object');
  my $class = 'Bio::EnsEMBL::Registry';
  Catalyst::Utils::ensure_class_loaded($class);
  $class->no_version_check(1);
  
  if ($self->skip_initation()) {
    $log->info('Skipping registry initiation');
    return $class; 
  }

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

  if(!$load) {
    confess "Cannot instantiate a registry; we have looked for configuration regarding a registry file, host information and ensembl genomes lookup. None were given. Please consult your configuration file and try again"
  }
  
  EnsEMBL::REST::RegistryHelper::set_connection_policies({
    disconnect_if_idle  => $self->disconnect_if_idle,
    reconnect_when_lost => $self->reconnect_when_lost,
    no_caching          => $self->no_caching,
    connection_sharing  => $self->connection_sharing,
    reconnect_interval  => $self->reconnect_interval,
  }, $log);

  return $class;

}

has '_species_info' => ( isa => 'ArrayRef', is => 'ro', lazy => 1, builder => '_build_species_info' );

# Logic here is if we were told a compara name we use that
# If not we query the species for the "best" compara (normally depends on division)
# If no hit and the queried name was different from the default name then try that
# Return if we got a hit otherwise throw an error
sub get_best_compara_DBAdaptor {
  my ($self, $species, $request_compara_name, $default_compara) = @_;
  $default_compara = 'multi' if ! defined $default_compara;

  my $compara_name = $request_compara_name || ($species ? $self->get_compara_name_for_species($species) : undef);
  my $dba;
  if ( $compara_name ) {
    if (lc($compara_name) eq 'vertebrates') {
      $compara_name = 'multi';
    }
    $dba = $self->get_DBAdaptor($compara_name, 'compara', 'no alias check');
    if ( !$dba ) {
      throw "Cannot find a suitable compara database for the species $species. Try specifying a compara parameter";
    }
  }

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
  my ($self, $division, $strain_collection, $hide_strain_info) = @_;
  my $info = $self->_species_info();
  #have to force numerification again. It got lost ... somewhere
  #flag to show or hide strain info
  if( $hide_strain_info > 0 ){
    my @hidden_keys = qw(strain strain_collection);
    my $new_info_list = [];
    foreach my $inf ( @{$info} ) {
      my $new_info_hash = {};
      foreach my $key (keys %$inf){
        $new_info_hash->{$key} = $inf->{$key} unless grep {$_ eq $key} @hidden_keys;
      }
      push @$new_info_list, $new_info_hash;
    }
    $info = $new_info_list;
  }
  
  my @subset = @{$info};
  #filter by division (e.g.: EnsemblVertebrates, the default setting for info/species)
  if ($division) {
    @subset = grep { lc $_->{division} eq lc $division } @subset;
  }
  # This assumes one might specify strain collection AND division, but that may not be an issue
  if ($strain_collection) {
    @subset = grep { lc $_->{strain_collection} eq lc $strain_collection } @subset;
  }
  
  return [
    grep { $_ > 0 }
    map { $_->{release} += 0; $_ }
    @subset
  ];
}

sub _build_species_info {
  return EnsEMBL::REST::RegistryHelper::species_info();
}

sub get_comparas {
  my ($self) = @_;
  my @comparas;
  my $reg = $self->_registry();
  my $dbadaptors = $self->get_all_DBAdaptors('compara');
  foreach my $dba (@{$dbadaptors}) {
    my $name = $dba->species();
    my $mc = $self->get_adaptor($name, 'compara', 'metacontainer');
    if (lc($name) eq 'multi') {
      $name = 'vertebrates';
    }
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
    my $compara_group = 'vertebrates';
    my $division = $mc->single_value_by_key('species.division');
    if($division) {
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
    if(defined $species->{release}) {
      $hash{$species->{release}} = 1;
    }
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
    $log->info('Done');
  }
  return;
};

sub get_genomeinfo_adaptor {
  my ($self) = @_;
  return $self->get_adaptor('multi', 'metadata', 'GenomeInfo');
}

__PACKAGE__->meta->make_immutable;

1;

