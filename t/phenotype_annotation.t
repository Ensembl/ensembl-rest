# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
# Copyright [2016] EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http=>//www.apache.org/licenses/LICENSE-2.0
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
  $ENV{ENS_REST_LOG4PERL}= "$Bin/../log4perl_testing.conf";
}

use Test::More;
use Test::Differences;
use Catalyst::Test ();
use Bio::EnsEMBL::Test::TestUtils;
use Bio::EnsEMBL::Test::MultiTestDB;
use Data::Dumper;

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');
my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('multi');
Catalyst::Test->import('EnsEMBL::REST');


my $base = '/phenotype';


my $expected_data1 = [
          {
            'source' => 'DGVa',
            'Variation' => 'rs2299299',
            'location' => '13:86442404-86442404',
            'description' => 'BRUGADA SYNDROME',
            'mapped_to_accession' => 'Orphanet:130',
            'attributes' => {
              'p_value' => '2.00e-7'
            },
          }
        ];


my $expected_data2 = [];

## get by accession
my $accession_query = 'accession/homo_sapiens/Orphanet:130';

my $json1 = json_GET("$base/$accession_query", 'get by ontology accession');
eq_or_diff($json1, $expected_data1, "Checking the get result from phenotype/accession");


## get by term
my $term_query = 'term/homo_sapiens/Brugada%20syndrome';

my $json2 = json_GET("$base/$term_query", 'get by ontology term');
eq_or_diff($json2, $expected_data1, "Checking the get result from phenotype/term");


## get by term & bad source
my $term_source_query = 'term/homo_sapiens/Brugada%20syndrome?source=turnip';

my $json3 = json_GET("$base/$term_source_query", 'get by ontology term & source');
eq_or_diff($json3, $expected_data2, "Checking the get result from phenotype/term & source");


## get by term & good source
my $term_source_query2 = 'term/homo_sapiens/Brugada%20syndrome?source=DGVa';

my $expected_data = [];
my $json4 = json_GET("$base/$term_source_query2", 'get by ontology term & source');
eq_or_diff($json4, $expected_data1, "Checking the get result from phenotype/term & source");


## get by accession inc children
my $accession_child_query = 'accession/homo_sapiens/Orphanet:101934?include_children=1';

my $json5 = json_GET("$base/$accession_child_query", 'get by ontology accession & child terms');
eq_or_diff($json5, $expected_data1, "Checking the get result from phenotype/accession with child terms");


done_testing();


