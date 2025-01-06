#!/usr/bin/env perl
# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
# Copyright [2016-2025] EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


#The script populates a stable_id lookup database with all stable ids found in databases on a specified server for
#a specified db release.
#The stable ids are copied for objects listed in hash %group_objects

use strict;
use warnings;
use Getopt::Long;
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::ApiVersion;
use Lucy::Index::Indexer;
use Lucy::Plan::Schema;
use Lucy::Plan::StringType;

my $index;
my $db_version = software_version();
my $host;
my $user;
my $port;
my @species;
my @groups;

GetOptions(
    "index=s"      => \$index,
    "db_version=i" => \$db_version,
    "host|h=s", \$host,
    "user|u=s", \$user,
    "port=i",   \$port,
    'species=s@' => \@species,
    'group=s@', => \@groups,
    "help",     \&usage,
);
usage() if ( !$host || !$user );
die "No -index defined" if ! $index;

my $registry = "Bio::EnsEMBL::Registry";
$registry->load_registry_from_db(
    -host       => $host,
    -port       => $port,
    -user       => $user,
    -db_version => $db_version
);
$registry->set_disconnect_when_inactive();

my @dbas;
if(@species) {
  @dbas = map { @{$registry->get_all_DBAdaptors(-SPECIES => $_)} } @species;
}
else {
  @dbas = @{ $registry->get_all_DBAdaptors() };
}

my %group_objects = (
    core => {
        Exon             => 1,
        Gene             => 1,
        Transcript       => 1,
        Translation      => 1,
        Operon           => 1,
        OperonTranscript => 1,
    }
    # },
    # compara => {
    #     GeneTree => 1,
    #     Family   => 1,
    # },
    # variation => {
    #     Variation => 1,
    # }
);

#hash which stores species we have already processed
my %dba_species;

my $schema = Lucy::Plan::Schema->new; 
my $type   = Lucy::Plan::StringType->new;
$schema->spec_field( name => 'stable_id', type => $type );
$schema->spec_field( name => 'species', type => $type );
$schema->spec_field( name => 'group', type => $type );
$schema->spec_field( name => 'object_type', type => $type );
my $indexer = Lucy::Index::Indexer->new(
    schema => $schema,
    index  => $index,
    create => 1,
);

while ( my $dba = shift @dbas ) {
    my $species = $dba->species();
    next if ( exists( $dba_species{ $species } ) );
    my $group = $dba->group();
    print STDERR "$species | $group\n";
    my @stable_id_objects = keys %{ $group_objects{$group} };
    foreach my $object_name (@stable_id_objects) {
        my $adaptor = $dba->get_adaptor($object_name);
        my %stable_ids;
        if ( $adaptor->can('list_stable_ids') ) {
            %stable_ids = map { $_ => 1 } @{ $adaptor->list_stable_ids() };
        }
        else {
            %stable_ids =
              map { ( $_->stable_id() || '' ) => 1 } @{ $adaptor->fetch_all() };
        }
        delete $stable_ids{''};
        my @stable_ids = keys %stable_ids;
        if (@stable_ids) {
          foreach my $id (@stable_ids) {
            $indexer->add_doc({
              stable_id => $id, species => $species, group => $group, object_type => $object_name,
            });
          }
        }
    }
}

$indexer->commit;
$indexer->optimize();

sub usage {
    my $indent = ' ' x length($0);
    print <<EOF; exit(0);

The script populates a Lucy lookup index with all stable ids found in databases 
on a specified server (or servers) for a specified db release.
Stable ids are copied for objects listed in hash %group_objects

Usage:

  $0 
  $indent -host host_name -user user_name
  $indent [-port port_number]
  $indent [-db_version]
  $indent [-index]
  $indent [-help]  
  

  -h|host              Database host where stable_ids are to be copied from

  -u|user              Database user where stable_ids are to be copied from

  -port                Database port where stable_ids are to be copied from

  -db_version          If not specified, software_version() returned by the ApiVersion module will be used

  -index               Location of the index file to generate.

  -help                This message


EOF

}
