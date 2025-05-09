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
  $ENV{ENS_REST_LOG4PERL} = "$Bin/../log4perl_testing.conf";
}

use Test::More;
use Test::Differences;
use Catalyst::Test ();
use Bio::EnsEMBL::Test::TestUtils;


Catalyst::Test->import('EnsEMBL::REST');

my $base = '/ga4gh/callsets/search';


my $post_data2 = '{ "pageSize": 2,  "variantSetId":2,"pageToken":"" }';
my $post_data3 = '{ "pageSize": 2,  "variantSetId":1, "name": "HG00097", "pageToken":"" }';


my $expected_data2 = {
callSets => [               
    {                         
      id => '2:NA12878',        
      info => {               
        assembly_version => [ 
          'GRCh37'            
        ],
        variantSetName => [
          'Illumina platinum genomes'
        ]                     
      },                      
      name => 'NA12878',      
      sampleId => 'NA12878',  
      variantSetIds => [      
        '2'                  
      ],
      created => '1419292800000',
      updated => '1419292800000',
    }                         
  ],
  nextPageToken => undef                           
 };  

my $expected_data3 = {
callSets => [
 {
      id => '1:HG00097',
      info => {
        assembly_version => [
          'GRCh37'
        ],
        variantSetName => [ 
          '1000 Genomes phase1'
        ]
      },
      name => 'HG00097',
      sampleId => 'HG00097',
      variantSetIds => [
        '1'
      ],
      created => '1432745640000',
      updated => '1432745640000'
    }
  ],
  nextPageToken => undef
} ;


my $json2 = json_POST($base, $post_data2, 'callsets by variantset');
eq_or_diff($json2, $expected_data2, "Checking the result from the gacallset endpoint - by variantset");
  
my $json3 = json_POST($base, $post_data3, 'callsets by variantset');
eq_or_diff($json3, $expected_data3, "Checking the result from the gacallset endpoint - by variantset and callset");

## GET
 
$base =~ s/\/search//;
my $id = '1:HG00097';
my $json_get = json_GET("$base/$id", 'get callset');

my $expected_get_data =  { id => '1:HG00097',
      info => {
        assembly_version => [
          'GRCh37'
        ],
        variantSetName => [
          '1000 Genomes phase1'
        ]
      },
      name => 'HG00097',
      sampleId => 'HG00097',
      variantSetIds => [
        '1'
      ],
      created => '1432745640000',
      updated => '1432745640000'
    };

eq_or_diff($json_get, $expected_get_data, "Checking the get result from the callset endpoint");
 

done_testing();
