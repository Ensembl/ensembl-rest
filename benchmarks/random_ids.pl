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

use Bio::EnsEMBL::Registry;
my $base_url = 'http://rest.ensembl.org/sequence/id/';
Bio::EnsEMBL::Registry->load_registry_from_db(-HOST => 'useastdb.ensembl.org', -PORT => 5306, -USER => 'anonymous');
my %table_counts;

my $limit = 2e4;

my @dbas = grep { $_->species() !~ /Ancestral/ } @{Bio::EnsEMBL::Registry->get_all_DBAdaptors(-GROUP => 'core')};
my @objects = qw/gene transcript translation/;
my @trans_type = (qw/cds cdna/, undef);

my $cnt = 0;
while($cnt < $limit) {
  my $dba = $dbas[rand($#dbas)];
  die 'no dba' unless $dba;
  my $object = $objects[rand($#objects)];
  my $h = $dba->dbc()->sql_helper();
  my $species = $dba->species();
  my $count;
  my $key = "${species}_!_${object}";
  if(exists $table_counts{$key}) {
    $count = $table_counts{$key};
  }
  else {
    $count = $h->execute_single_result(-SQL => 'select count(*) from '.$object);
    if($count == 0) {
      printf "Got a 0 count for object type %s with species %s. Whoops \n", $object, $dba->species();
      die;
    }
    $table_counts{$key} = $count;
  }
  my $random_index = rand($count);
  my $stable_id = $h->execute_single_result(-SQL => sprintf(q{select stable_id from %s limit %d,1}, $object, $random_index));
  my $url = $base_url.$stable_id.'?content-type=application/json';
  if($object eq 'transcript') {
    my $type = $trans_type[rand($#trans_type)];
    $url .= ';type='.$type if $type;
  }
  print $url, "\n";
  $cnt++;
}
