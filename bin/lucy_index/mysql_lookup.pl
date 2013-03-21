#!/usr/bin/env perl

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