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

my $base = '/ga4gh/variantsets/search';

my $post_data1 = '{ "pageSize": 2,  "datasetIds":[],"pageToken":"" }';
my $post_data2 = '{ "pageSize": 2,  "datasetIds":[1],"pageToken":"" }';

my $expected_data1 = {                                                
  variantSets => [                                
    {                                             
      datasetId => '1',                           
      id => '20',                                 
      metadata => [                               
        {                                         
          key => 'assembly',                      
          value => 'GRCh37'                       
        },                                        
        {                                         
          key => 'source_name',                   
          value => '1000 Genomes phase1'          
        },                                        
        {                                         
          key => 'source_url',                    
          value => 'http://www.1000genomes.org/'  
        },                                         
        { 
          key => 'set_name',      
          value => '1000GENOMES:phase_1:AFR'
        } 
       ]
    },                                            
    {                                             
      datasetId => '1',                           
      id => '21',                                 
      metadata => [                               
        {                                         
          key => 'assembly',                      
          value => 'GRCh37'                       
        },                                        
        {                                         
          key => 'source_name',                   
          value => '1000 Genomes phase1'          
        },                                        
        {                                         
          key => 'source_url',                    
          value => 'http://www.1000genomes.org/'  
        },
        {
          key => 'set_name',
          value => '1000GENOMES:phase_1:AMR'
        } 
      ]                                           
    },                                            
    {                                             
      pageToken => '22'                           
    }                                             
  ]                                               
};      
my $expected_data2 = { 
  variantSets => [                                
    {                                             
      datasetId => '1',                           
      id => '20',                                 
      metadata => [                               
        {                                         
          key => 'assembly',                      
          value => 'GRCh37'                       
        },                                        
        {                                         
          key => 'source_name',                   
          value => '1000 Genomes phase1'          
        },                                        
        {                                         
          key => 'source_url',                    
          value => 'http://www.1000genomes.org/'  
        },
        {
          key => 'set_name',  
          value => '1000GENOMES:phase_1:AFR'
        }                                         
      ]                                           
    },                                            
    {                                             
      datasetId => '1',                           
      id => '21',                                 
      metadata => [                               
        {                                         
          key => 'assembly',                      
          value => 'GRCh37'                       
        },                                        
        {                                         
          key => 'source_name',                   
          value => '1000 Genomes phase1'          
        },                                        
        {                                         
          key => 'source_url',                    
          value => 'http://www.1000genomes.org/'  
        },
        {  
          key => 'set_name',   
          value => '1000GENOMES:phase_1:AMR' 
        }                                         
      ]                                           
    },                                            
    {                                             
      pageToken => '22'                           
    }                                             
  ]                                               
};                

my $json1 = json_POST( $base, $post_data1, 'variantset - 2 entries' );
eq_or_diff($json1, $expected_data1, "Checking the result from the gavariantset endpoint");

my $json2 = json_POST($base, $post_data2, 'variantset by datasetid');
eq_or_diff($json2, $expected_data2, "Checking the result from the gavariantset endpoint by dataset");
  

done_testing();
