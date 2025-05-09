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

# required module imports
use strict;
use warnings;
use feature 'say';
use HTTP::Tiny;
use JSON qw/decode_json/;

my $server = '127.0.0.1';
my $port = 3000;
# my $server = '174.129.135.49';
# my $port = 3001;

my $http = HTTP::Tiny->new();
my $iterations = 1;
$iterations = $ARGV[0]-1 if @ARGV;
foreach my $iter (0..$iterations) {
  my $resp = $http->get("http://${server}:${port}/sequence/id/ENSG00000139618", {
    headers => { 'Content-type' => 'application/json' }
  });
  my $json = decode_json($resp->{content});
  say "definition: ".$json->{stable_id};
  say "nalen:      ".length($json->{seq});
}
