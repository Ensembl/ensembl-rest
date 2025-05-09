# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
# Copyright [2016-2025] EMBL-European Bioinformatics Institute
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
use Test::Deep;
use Catalyst::Test ();
use Bio::EnsEMBL::Test::TestUtils;
use Bio::EnsEMBL::Test::MultiTestDB;

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
          },
          {
            'Variation' => 'rs142276873',
            'description' => 'BRUGADA SYNDROME',
            'location' => '11:6303493-6303493',
            'mapped_to_accession' => 'Orphanet:130',
            'source' => 'DGVa'
          }
        ];


my $expected_data2 = [];

## get by accession
my $accession_query = 'accession/homo_sapiens/Orphanet:130';

my $json1 = json_GET("$base/$accession_query", 'get by ontology accession');
cmp_bag($json1, $expected_data1, "Checking the get result from phenotype/accession");


## get by term
my $term_query = 'term/homo_sapiens/Brugada%20syndrome';

my $json2 = json_GET("$base/$term_query", 'get by ontology term');
cmp_bag($json2, $expected_data1, "Checking the get result from phenotype/term");


## get by term & bad source
my $term_source_query = 'term/homo_sapiens/Brugada%20syndrome?source=turnip';

my $json3 = json_GET("$base/$term_source_query", 'get by ontology term & source');
cmp_bag($json3, $expected_data2, "Checking the get result from phenotype/term & source");


## get by term & good source
my $term_source_query2 = 'term/homo_sapiens/Brugada%20syndrome?source=DGVa';

my $expected_data = [];
my $json4 = json_GET("$base/$term_source_query2", 'get by ontology term & source');
cmp_bag($json4, $expected_data1, "Checking the get result from phenotype/term & source");


## get by accession inc children
my $accession_child_query = 'accession/homo_sapiens/Orphanet:101934?include_children=1';

my $json5 = json_GET("$base/$accession_child_query", 'get by ontology accession & child terms');
cmp_bag($json5, $expected_data1, "Checking the get result from phenotype/accession with child terms");


## get by accession & optional parameters submitter, pubmed_id, review_status
my $accession_query_mim = 'accession/homo_sapiens/GO:0060023?include_submitter=1;include_pubmed_id=1;include_review_status=1';
my $expected_data6 =  [
   {
      'source' => 'GOA',
      'location' => '6:1312675-1314992',
      'description' => 'soft palate development',
      'mapped_to_accession' => 'GO:0060023',
      'Gene' => 'ENSG00000137273',
      'attributes' => {
        'review_status' => 'no assertion criteria provided',
        'MIM' => '119570',
        'external_reference' => 'PMID:8626802',
        'pubmed_ids' => ['PMID:1313972', 'PMID:1319114', 'PMID:1328889']
      }
    }
    ];
my $json6 = json_GET("$base/$accession_query_mim", 'get by ontology accession - term with MIM id, including review_status, pubmed_id, submitter');
cmp_bag($json6, $expected_data6, "Checking the get result from phenotype/accession - term with MIM id, including review_status, pubmed_id, submitter");


## get by term & optional parameters submitter, pubmed_id, review_status
my $term_query_mim = 'term/homo_sapiens/soft%20palate%20development?include_review_status=1;include_pubmed_id=1;include_submitter=1';
my $expected_data7 =  [
    {
       'source' => 'GOA',
       'location' => '6:1312675-1314992',
       'description' => 'soft palate development',
       'mapped_to_accession' => 'GO:0060023',
       'Gene' => 'ENSG00000137273',
       'attributes' => {
         'review_status' => 'no assertion criteria provided',
         'MIM' => '119570',
         'external_reference' => 'PMID:8626802',
         'pubmed_ids' => ['PMID:1313972', 'PMID:1319114', 'PMID:1328889']
       }
     }
    ];
my $json7 = json_GET("$base/$term_query_mim", 'get by ontology term - by term with MIM id');
cmp_bag($json7, $expected_data7, "Checking the get result from phenotype/term - with MIM id");

done_testing();


