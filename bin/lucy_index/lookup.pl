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
use Lucy::Search::IndexSearcher;
use Lucy::Search::QueryParser;
use Time::HiRes;
use Time::Duration;

my $index;
my $id;
my $type;
my $repeats = 1;
my $query_string;
my $file;

GetOptions(
    "index=s" => \$index,
    "id=s" => \$id,
    'file=s' => \$file,
    'query=s' => \$query_string,
    'repeats=i' => \$repeats,
    'type=s' => \$type,
    "help",     \&usage,
);
usage() if ( !$index );

my @intervals;
my $t0 = [Time::HiRes::gettimeofday];
my @ids;
if($file) {
  open my $fh, '<', $file or die "Cannot read '$file': $!";
  @ids = map { chomp($_); $_ } <$fh>;
  close $fh;
}
else {
  @ids = ($id);
}
push(@intervals, 'Loading IDs '.Time::HiRes::tv_interval($t0));

$t0 = [Time::HiRes::gettimeofday];

my $searcher = Lucy::Search::IndexSearcher->new( 
    index => $index, 
);
push(@intervals, 'Loading index '. Time::HiRes::tv_interval($t0));

$t0 = [Time::HiRes::gettimeofday];

my @queries;

if($query_string) {
  my $qparser  = Lucy::Search::QueryParser->new( 
      schema => $searcher->get_schema,
  );
  $qparser->set_heed_colons(1);
  @queries = ($qparser->parse($query_string));
}
else {
  my $type_query;
  $type_query = Lucy::Search::TermQuery->new(field => 'object_type', term => $type) if $type; 
  
  if(@ids) {
    foreach my $curr_id (@ids) {
      my $query;
      my $id_query = Lucy::Search::TermQuery->new(field => 'stable_id', term => $curr_id);
      if($id_query && $type_query) {
        $query = Lucy::Search::ANDQuery->new(
          children => [ $id_query, $type_query ]
        );
      }
      elsif($id_query) {
        $query = $id_query;
      }
      elsif($type_query) {
        $query = $type_query;
      }
      push(@queries, $query);
    }
  }
  else {
    @queries = ($type_query);
  }
}
push(@intervals, 'Query building '. Time::HiRes::tv_interval($t0));

$t0 = [Time::HiRes::gettimeofday];

foreach my $query (@queries) {
  my $count = 1;
  while($count <= $repeats) {
    my $hits = $searcher->hits(
      query => $query,
    );
    while ( my $hit_doc = $hits->next ) {
      printf "%s | %s | %s | %s\n", map { $hit_doc->{$_} } qw/stable_id species group object_type/;
    }
    $count++;
  }
}
push(@intervals, 'Searching '. Time::HiRes::tv_interval($t0));

print $_."\n" for @intervals;
