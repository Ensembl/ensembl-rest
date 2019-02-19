=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2019] EMBL-European Bioinformatics Institute

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

package EnsEMBL::REST::RegistryHelper;

use strict;
use warnings;
use Catalyst::Utils;
use Bio::EnsEMBL::Registry;

use vars qw($species_info);

sub species_info {
  build_species_info() unless defined $species_info;
  return $species_info;
}

sub build_species_info { 
  my @species;

  #Aliases is backwards i.e. alias -> species
  my %alias_lookup;
  while (my ($alias, $species) = each %{ $Bio::EnsEMBL::Registry::registry_register{_ALIAS} }) {
      push(@{$alias_lookup{$species}}, $alias); # iterate through the alias,species pairs & reverse
  }

  my @all_dbadaptors = grep {$_->dbc->dbname ne 'ncbi_taxonomy'} @{$Bio::EnsEMBL::Registry::registry_register{_DBA}};
  my @core_dbadaptors;
  my (%groups_lookup, %division_lookup, %common_lookup, %taxon_lookup, %display_lookup, %release_lookup, %assembly_lookup, %accession_lookup, %strain_lookup, %strain_collection_lookup);
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
          $division_lookup{$species} = $mc->get_division() || 'EnsemblVertebrates';
          $common_lookup{$species} = $mc->get_common_name();
          $taxon_lookup{$species} = $mc->get_taxonomy_id();
          $display_lookup{$species} = $mc->get_display_name();
          $assembly_lookup{$species} = $csa->get_default_version();
          $accession_lookup{$species} = $mc->single_value_by_key('assembly.accession');
          $strain_lookup{$species} = $mc->single_value_by_key('species.strain');
          $strain_collection_lookup{$species} = $mc->single_value_by_key('species.strain_collection');
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
            -SQL => 'select m1.meta_value, m2.meta_value, m3.meta_value from meta m1, meta m2, meta m3 where m1.species_id = m2.species_id and m1.species_id = m3.species_id and m1.meta_key = ? and m2.meta_key = ? and m3.meta_key = ?',
            -PARAMS => ['species.production_name', 'species.strain', 'species.strain_collection'],
            -CALLBACK => sub {
              my ($row) = @_;
              $strain_lookup{$row->[0]} = $row->[1];
              $strain_collection_lookup{$row->[0]} = $row->[2];
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
      assembly => $assembly_lookup{$species},
      strain => $strain_lookup{$species},
      strain_collection => $strain_collection_lookup{$species},
    };
    push(@species, $info);
  }

  # store
  $species_info = \@species;

  return;
}

sub set_connection_policies {
  my ($config, $log) = @_;
  my $registry = 'Bio::EnsEMBL::Registry';
  
  $log && $log->info('Setting up connection policies');

  if($config->{disconnect_if_idle}) {
    $log && $log->info('Setting all DBAdaptors to disconnect when inactive');
    $registry->set_disconnect_when_inactive();
  }

  if($config->{reconnect_when_lost}) {
    $log && $log->info('Setting all DBAdaptors to reconnect when connections are lost');
    $registry->set_reconnect_when_lost();
  }

  if($config->{no_caching}) {
    $log && $log->info('Stopping caching in all adaptors and clearing out existing caches');
    $registry->no_cache_warnings(1);
    foreach my $dba (@{$registry->get_all_DBAdaptors()}) {
      $dba->no_cache(1);
    }
  }

  if($config->{connection_sharing}) {
    $log && $log->info('Connection sharing turned on');
    _intern_db_connections($config, $log);
  }

  return;
}

sub _intern_db_connections {
  my ($config, $log) = @_;
  my %single_connections;
  my $reconnect_interval = $config->{reconnect_interval} || 0;
  Catalyst::Utils::ensure_class_loaded('Bio::EnsEMBL::DBSQL::ProxyDBConnection');
  if($reconnect_interval) {
    $log && $log->info('Using reconnect_interval of '.$reconnect_interval);
  }
  foreach my $dba (@{Bio::EnsEMBL::Registry->get_all_DBAdaptors()}) {
    my $dbc = $dba->dbc();
    my $dbname = $dbc->dbname();
    next unless $dbname; #skip if it had no DBNAME
    $dbc->disconnect_if_idle();
    my $key = join(q{!=!}, map { ($dbc->$_() || q{?}) } qw(host port username password driver) );
    if(! exists $single_connections{$key}) {
      $log && $log->info(sprintf('New connection being generated for %s DB at %s@%s:%d', $dbc->driver(), $dbc->username(), $dbc->host(), $dbc->port()));
      $single_connections{$key} = $dbc;
    }
    my $new_dbc = Bio::EnsEMBL::DBSQL::ProxyDBConnection->new(-DBC => $single_connections{$key}, -DBNAME => $dbname, -RECONNECT_INTERVAL => $reconnect_interval);
    $dba->dbc($new_dbc);
  }
  return;
}

1;
