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
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;
use Data::Dumper;

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');
my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('multi');
Catalyst::Test->import('EnsEMBL::REST');

my $base = '/ga4gh/variants/search';

my $post_data1 = '{ "referenceName": 22,"start": 16050150 ,"end": 16060170 ,"pageSize": 1, "callSetIds": ["2:NA12878"], "variantSetId":2 }';

my $post_data4 = '{ "referenceName": 22,"start": 16050150 ,"end": 16060170 ,"pageSize": 1, "callSetIds": ["2:NA12878"], "variantSetId":2, "pageToken":"16050251" }';

my $post_data_empty = '{ "referenceName": 22,"start": 1 ,"end": 10 ,"pageSize": 1, "callSetIds": ["2:NA12878"], "variantSetId":2 }';

my $expected_data1 = {  nextPageToken => 16050251,
  variants => [                 
    {                          
     alternateBases => [     
            'T'                  
          ],                    
          calls => [           
            {                         
             callSetId => '2:NA12878', 
             callSetName => 'NA12878',
             genotype => [    
               0,          
               1          
             ], 
             genotypeLikelihood => [], 
             info => {},   
             phaseset => '' 
           }              
         ],              
         end => 16050159,      
         id => '2:22_16050159', 
         info => { AC => ['1'],
                   AF => ['0.50'], 
                   AN => ['2']}, 
         names => ['22_16050159'],  
         referenceBases => 'C', 
         referenceName => '22',
         start => 16050158,
         variantSetId => '2',
         created => '1419292800000',
         updated => '1419292800000', 
       }                    
     ]                     
   };    


my $expected_data4 = {  nextPageToken => 16051967,
  variants => [
    {
     alternateBases => [
            'T'
          ],
          calls => [
            {
             callSetId => '2:NA12878',
             callSetName => 'NA12878',
             genotype => [
               0,
               1
             ],
             genotypeLikelihood => [], 
             info => {},
             phaseset => ''
           }
         ],
         end => 16050252,
         id => '2:22_16050252',
         info => { AC => ['1'],                  
                   AF => ['0.50'],
                   AN => ['2']},
         names => ['22_16050252'],
         referenceBases => 'A',
         referenceName => '22',
         start => 16050251,
         variantSetId => '2',
         created => '1419292800000',
         updated => '1419292800000',
       }
     ]
   };
 
my $expected_data_empty = { variants => [], nextPageToken => undef}; 

my $json1 = json_POST( $base, $post_data1, 'variants by callset & varset' );
eq_or_diff($json1, $expected_data1, "Checking the result from the GA4GH variants endpoint - variantSet & callSet");


my $json4 = json_POST($base, $post_data4, 'variants by callset & token');
eq_or_diff($json4, $expected_data4, "Checking the result from the GA4GH variants endpoint - with token");

my $json5 = json_POST($base, $post_data_empty, 'variants by empty region');
eq_or_diff($json5, $expected_data_empty, "Checking the result from the GA4GH variants endpoint - empty region"); 


my $bad_post = q/{ "referenceName": 22,"start": 16050150 ,"end": 16050150 ,"pageSize": 1, "callSetIds": ["2:NA12878"], "variantSetId":2, "pageToken":"16050158" }/;
action_bad_post($base, $bad_post, qr/must not equal/, 'Throw nasty data at endpoint' );




## GET


my $expected_get_data = {alternateBases => [           
        'A'                         
      ],
      end => 23821095,
      id => '1:rs142276873', 
      name => 'rs142276873', 
      referenceBases => 'G', 
      referenceName => '18', 
      start => 23821094, 
      updated => '', 
      created => ''
    } ;                             


$base =~ s/\/search//;
my $id = '1:rs142276873';
my $json_get = json_GET("$base/$id", 'get variant');

eq_or_diff($json_get, $expected_get_data, "Checking the get result from the variants endpoint");
done_testing();


