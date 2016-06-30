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
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');
my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('multi');
Catalyst::Test->import('EnsEMBL::REST');

my $base = '/ga4gh/variantannotationsets/search';

my $post_data1 = '{ "variantSetId": "84", "pageSize": 1 }';

my $expected_data1 = {                                  
  variantAnnotationSets => [
    {                                                                                
      analysis => {                                                                  
        created => undef,                                                            
        description => undef,                                                        
        id => '84',                                                                  
        info => {                                                                    
          'assembly.accession' => 'GCA_000001405.9',                                 
          'assembly.long_name' => 'Genome Reference Consortium Human Reference 37',  
          'assembly.name' => 'GRCh37.p8',                                            
          'dbSNP_version' => '138',                                                    
          'genebuild.havana_datafreeze_date' => '2012-06-11',                        
          'genebuild.id' => '25',                                                    
          'genebuild.last_geneset_update' => '2012-10'                               
        },                                                                           
        name => 'Ensembl',                                                           
        software => [                                                                
          'VEP'                                                                      
        ],                                                                           
        type => 'variant annotation',                                                
        updated => undef                                                             
      },                                                                             
      id => 'Ensembl:84',                                                            
      name => 'Ensembl:84',                                                          
      variantSetId => '84'                                                           
    }                                                                                
  ],
  nextPageToken => undef                                                                               
}; 


my $json1 = json_POST( $base , $post_data1, 'dataset - 1 entry' );
eq_or_diff($json1, $expected_data1, "Checking the result from the ga4gh dataset endpoint");



### check get

$base =~ s/\/search//;
my $id = 'Ensembl:84';
my $expected_data2 = {  
     analysis => {                                                                 
       created => undef,                                                           
       description => undef,                                                       
       id => '84',                                                                 
       info => {                                                                   
         'assembly.accession' => 'GCA_000001405.9',                                
         'assembly.long_name' => 'Genome Reference Consortium Human Reference 37', 
         'assembly.name' => 'GRCh37.p8',                                           
         dbSNP_version => '138',                                                   
         'genebuild.havana_datafreeze_date' => '2012-06-11',                       
         'genebuild.id' => '25',                                                   
         'genebuild.last_geneset_update' => '2012-10'                              
       },                                                                          
       name => 'Ensembl',                                                          
       software => [                                                               
         'VEP'                                                                     
       ],                                                                          
       type => 'variant annotation',                                               
       updated => undef                                                            
     },                                                                            
     id => 'Ensembl:84',                                                           
     name => 'Ensembl:84',                                                         
     variantSetId => '84'                                                          
};

  
my $json2 = json_GET("$base/$id", 'get variant annotation set');
eq_or_diff($json2, $expected_data2, "Checking the get result from the variantannotationset endpoint");


done_testing();
