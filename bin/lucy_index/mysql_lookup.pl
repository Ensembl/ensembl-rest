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


use strict;
use warnings;
use Getopt::Long;
use Bio::EnsEMBL::DBSQL::DBConnection;

my $id;
my $type;
my $repeats = 1;
my $file;

my $dbc = Bio::EnsEMBL::DBSQL::DBConnection->new(
  -HOST => '127.0.0.1', -PORT => 33061, -USER => 'ensro', -DBNAME => 'ensembl_stable_ids_70'
);
$dbc->sql_helper()->execute_single_result(-SQL => 'select 1');
my $sql = 'select stable_id, name, db_type, object_type from stable_id_lookup join species using (species_id) where';

GetOptions(
    "id=s" => \$id,
    'file=s' => \$file,
    'repeats=i' => \$repeats,
    'type=s' => \$type,
    "help",     \&usage,
);
usage() if ( (!$id && !$file) && !$type);

my @ids;
if($file) {
  open my $fh, '<', $file or die "Cannot read '$file': $!";
  @ids = map { chomp($_); $_ } <$fh>;
  close $fh;
}
else {
  @ids = ($id);
}

my @params;
if(@ids && $type) {
  $sql .= ' stable_id =? and object_type =?';
}
elsif(@ids) {
  $sql .= ' stable_id =?';
}
elsif($type) {
  $sql .= ' object_type =?';
}

if(@ids) {
  foreach my $curr_id (@ids) {
    push(@params, ($type ? [$curr_id,$type] : [$curr_id]));
  }
}
else {
  push(@params, [$type]);
}

my $sth = $dbc->prepare($sql);
foreach my $param_array (@params) {
  my $count = 1;
  while($count <= $repeats) {
    $sth->execute(@{$param_array});
    while ( my $row = $sth->fetchrow_arrayref() ) {
      printf "%s | %s | %s | %s\n", @{$row};
    }
    $count++;
  }
}
$sth->finish();
