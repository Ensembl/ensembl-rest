# Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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

my $post_data1 = '{ "pageSize": 2,  "datasetIds":[],"pageToken":"" }';
my $post_data2 = '{ "pageSize": 2,  "variantSetIds":[65],"pageToken":"" }';
my $post_data3 = '{ "pageSize": 2,  "variantSetIds":[23], "name": "HG00097", "pageToken":"" }';

my $expected_data1 = {                             
  callSets => [                
    {                          
      id => 'HG00096',         
      info => {                
        assembly_version => [  
          'GRCh37'             
        ]                      
      },                       
      name => 'HG00096',       
      sampleId => 'HG00096',   
      variantSetIds => [       
        '23'                   
      ],
      created => '1432745640000',
      updated => '1432745640000'                        
    },                         
    {                          
      id => 'HG00097',         
      info => {                
        assembly_version => [  
          'GRCh37'             
        ]                      
      },                       
      name => 'HG00097',       
      sampleId => 'HG00097',   
      variantSetIds => [       
        '23'                   
      ],
      created => '1432745640000',
      updated => '1432745640000' 
    }                          
  ],                           
  pageToken => 3              
} ;

my $expected_data2 = {
callSets => [               
    {                         
      id => 'NA12878',        
      info => {               
        assembly_version => [ 
          'GRCh37'            
        ]                     
      },                      
      name => 'NA12878',      
      sampleId => 'NA12878',  
      variantSetIds => [      
        '65'                  
      ],
      created => '1419292800000',
      updated => '1419292800000',
    }                         
  ]                           
 };  

my $expected_data3 = {
callSets => [
 {
      id => 'HG00097',
      info => {
        assembly_version => [
          'GRCh37'
        ]
      },
      name => 'HG00097',
      sampleId => 'HG00097',
      variantSetIds => [
        '23'
      ],
      created => '1432745640000',
      updated => '1432745640000'
    }
  ],
} ;


my $json1 = json_POST( $base, $post_data1, 'callsets' );
eq_or_diff($json1, $expected_data1, "Checking the result from the gacallset endpoint");

my $json2 = json_POST($base, $post_data2, 'callsets by variantset');
eq_or_diff($json2, $expected_data2, "Checking the result from the gacallset endpoint - by variantset");
  
my $json3 = json_POST($base, $post_data3, 'callsets by variantset');
eq_or_diff($json3, $expected_data3, "Checking the result from the gacallset endpoint - by variantset and callset");



done_testing();
