#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Registry;
my $base_url = 'http://beta.rest.ensembl.org/sequence/id/';
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