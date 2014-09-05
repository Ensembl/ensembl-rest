# Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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

BEGIN {
  use FindBin qw/$Bin/;
  use lib "$Bin/lib";
  use RestHelper;
  $ENV{CATALYST_CONFIG} = "$Bin/../ensembl_rest_testing.conf";
  $ENV{ENS_REST_LOG4PERL} = "$Bin/../log4perl_testing.conf";
}

use Test::More;
use Catalyst::Test ();
use Bio::EnsEMBL::Test::MultiTestDB;

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new();
Catalyst::Test->import('EnsEMBL::REST');

my $basic_id = 'ENSG00000176515';
my $symbol = "AL033381.1";
my $condensed_response = {object_type => 'Gene', db_type => 'core', species => 'homo_sapiens', id => $basic_id};

is_json_GET("/lookup/id/$basic_id?format=condensed", $condensed_response, 'Get of a known ID will return a value');
is_json_GET("/lookup/$basic_id?format=condensed", $condensed_response, 'Get of a known ID to the old URL will return a value');

my $full_response = {
  %{$condensed_response},
  start => 1080164, end => 1105181, strand => 1, seq_region_name => '6', assembly_name => 'GRCh37',
  biotype => 'protein_coding', display_name => 'AL033381.1', logic_name => 'ensembl', source => 'ensembl',
  description => 'Uncharacterized protein; cDNA FLJ34594 fis, clone KIDNE2009109  [Source:UniProtKB/TrEMBL;Acc:Q8NAX6]'
};
is_json_GET("/lookup/$basic_id", $full_response, 'Get of a known ID to the old URL will return a value');

my $expanded_response = {
  %{$condensed_response},
  Transcript => [
                 {object_type => 'Transcript', db_type => 'core', species => 'homo_sapiens', id => 'ENST00000314040',
 Translation => {object_type => 'Translation', db_type => 'core', species => 'homo_sapiens', id => 'ENSP00000320396'},
        Exon =>
                [
                 {object_type => 'Exon', db_type => 'core', species => 'homo_sapiens', id => 'ENSE00001271861'},
                 {object_type => 'Exon', db_type => 'core', species => 'homo_sapiens', id => 'ENSE00001271874'},
                 {object_type => 'Exon', db_type => 'core', species => 'homo_sapiens', id => 'ENSE00001271869'}
                ]
                }]
                };
is_json_GET("/lookup/id/$basic_id?expand=1;format=condensed", $expanded_response, 'Get of a known ID with expanded option will return transcripts as well');

is_json_GET("/lookup/symbol/homo_sapiens/$symbol?expand=1;format=condensed", $expanded_response, 'Get of a known symbol returns the same result as with stable id');

action_bad("/lookup/id/${basic_id}extra", 'ID should not be found. Fail');

done_testing();
