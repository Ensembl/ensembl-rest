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
use Data::Dumper;

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');
my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('multi');
Catalyst::Test->import('EnsEMBL::REST');


my $base = '/ga4gh/variantannotations/search';

my $post_data1 = '{"pageSize": 1, "variantAnnotationSetId": "Ensembl", "featureIds":[ "ENST00000381657.2" ] }';

my $post_data2 = '{"pageSize": 1, "variantAnnotationSetId": "Ensembl", "featureIds":[ "ENST00000381657.2" ],"effects" : [ {"sourceName":"SO","term":"missense_variant","id":"SO:0001583"}]  }';
 
my $post_data3 = '{ "referenceName": "X","start": 215790 ,"end": 215978, "variantAnnotationSetId": "Ensembl" ,"pageSize": 1}';

my $post_data4 = '{ "referenceName": "X","start": 215000 ,"end": 217000 ,"pageSize": 1, "variantAnnotationSetId": "Ensembl",  "pageToken": 215811  }';

my $post_data5 = '{ "referenceName": "X","start": 215000 ,"end": 217000 ,"pageSize": 1, "variantAnnotationSetId": "Ensembl",  "effects" : [ {"sourceName":"SO","term":"missense_variant","id":"SO:0001583"}]  }';



my $expected_data1 = {                                             
  nextPageToken => 'ENST00000381657.2_208197',                      
  variantAnnotations => [          
    {                                                           
      transcriptEffects => [                                        
        { 
         hgvsAnnotation =>{                                                          
          transcript => 'ENST00000381657.1:c.-205+4695_-205+4696insGCT', 
          genomic => '6:g.1084924_1084925insGCT',                    
          protein => undef,
         },
          featureId => 'ENST00000381657.2',                           
          alternateBase => 'GCT',
          id => '2',                            
          effects => [                                          
            {   
              id => 'SO:0001627',                              
              term => 'intron_variant', 
              sourceVersion => undef,                      
              sourceName => 'Sequence Ontology'          
            },                                              
            {                                              
              id => 'SO:0001906',                         
              term => 'feature_truncation',            
              sourceName => 'Sequence Ontology', 
              sourceVersion => undef
            }                                          
         ] 
        }                                           
    ],                                           
    variantId => '85:tmp__',                                                                                                           
    variantAnnotationSetId => 'Ensembl.85.GRCh37', 
    createDateTime => undef,
    info => {},                                           
   }
 ]
}; 
  
            

my $expected_data2 = { nextPageToken => 'ENST00000381657.2_208197',
  variantAnnotations => [                          
    {                                                       
      transcriptEffects => [                   
        {
         hgvsAnnotation =>{                 
          transcript => 'ENST00000381657.2:c.943G>A', 
          genomic => 'X:g.215973G>A',             
          protein => 'ENSP00000371073.2:p.Ala315Thr',  
        },
          featureId => 'ENST00000381657.2', 
          alternateBase => 'A',                     
          id => '7328429',
          analysisResults => [                     
            {                                     
              analysisId => 'SIFT.5.2.2',                             
              result => 'tolerated',
              score => '0.51'      
            }                             
          ],                             
          cDNALocation => {             
            alternateSequence => 'A',
            end => 1457,        
            start => 1456,
            referenceSequence => undef
          },                         
          CDSLocation => {          
            alternateSequence => 'ACG',            
            end => 943,                    
            start => 942,                 
            referenceSequence => 'GCG'          
          },                                   
          effects => [                       
            {                              
              id => 'SO:0001583',           
              term => 'missense_variant',           
              sourceName => 'Sequence Ontology',
              sourceVersion => undef
            }                                    
          ],
          proteinLocation => {                 
            alternateSequence => 'T',         
            end => 315,               
            start => 314,           
            referenceSequence => 'A'      
         }                              
        }                               
      ],                               
      variantId => '85:COSM1119154',                                            
      variantAnnotationSetId => 'Ensembl.85.GRCh37',    
      createDateTime => undef,  
      info => {},
    }
  ]
};


my $expected_data3 = { 
  nextPageToken => 215811,                             
  variantAnnotations => [                              
    {                                                  
      variantAnnotationSetId => 'Ensembl.85.GRCh37',           
      createDateTime => undef,                 
      info => {},
      transcriptEffects => [                           
        {
        featureId => 'ENST00000381657.2',
        id => '7303105', 
        hgvsAnnotation =>{                                             
          transcript => 'ENST00000381657.2:c.765G>A',       
          genomic => undef,                              
          protein => 'ENST00000381657.2:c.765G>A(p.=)',  
        },
          alternateBase => 'A',                        
          cDNALocation => {
            alternateSequence => 'A', 
            referenceSequence => undef,                         
            end => 1279,                        
            start => 1278                       
          },                                           
          CDSLocation => {                             
            alternateSequence => 'ACA',                
            end => 765,                         
            start => 764,                       
            referenceSequence => 'ACG'                 
          },                                           
          effects => [                                 
            {                                          
              id => 'SO:0001819',                      
              term => 'synonymous_variant',            
              sourceName => 'Sequence Ontology',
              sourceVersion => undef   
            }                                          
          ],
          proteinLocation => {                         
            alternateSequence => 'T',                  
            end => 255,                         
            start => 254,                       
            referenceSequence => 'T'                   
          }                                            
        }                                              
      ],                                               
      variantId => '85:rs370879507'                
    }
  ]
};

my $expected_data4 = {
  nextPageToken => 215818,                           
  variantAnnotations => [                            
    {                                                
      variantAnnotationSetId => 'Ensembl.85.GRCh37',               
      createDateTime => undef,
      info => {}, 
      transcriptEffects => [                         
        { 
         featureId => 'ENST00000381657.2',
         id => '7303382',
         hgvsAnnotation =>{                                           
           transcript => 'ENST00000381657.2:c.781G>A',     
           genomic => undef,                            
           protein => 'ENSP00000371073.2:p.Val261Ile',  
         },
          alternateBase => 'A',                      
          analysisResults => [                       
            {                                                        
              analysisId => 'SIFT.5.2.2',
              result => 'tolerated',         
              score => '1'                   
            }                                        
          ],                                         
          cDNALocation => {
            alternateSequence => 'A',                  
            end => 1295,                      
            start => 1294,
            referenceSequence => undef,                    
          },                                         
          CDSLocation => {                           
            alternateSequence => 'ATT',              
            end => 781,                       
            start => 780,                     
            referenceSequence => 'GTT'               
          },                                         
          effects => [                               
            {                                        
              id => 'SO:0001583',                    
              term => 'missense_variant',            
              sourceName => 'Sequence Ontology',
              sourceVersion => undef                                        
            }],
          proteinLocation => {                       
            alternateSequence => 'I',                
            end => 261,                       
            start => 260,                     
            referenceSequence => 'V'                 
          }                                          
        }                                            
      ],                                             
      variantId => '85:rs368117410'      
    }                                                
  ]
};


my $json1 = json_POST( $base, $post_data1, 'variantannotations by transcript' );
eq_or_diff($json1, $expected_data1, "Checking the result from the variantannotation endpoint - by transcript");

my $json2 = json_POST($base, $post_data2, 'variantannotations by transcript & effect');
eq_or_diff($json2, $expected_data2, "Checking the result from the variant annotation endpoint - by transcript & effect");

my $json3 = json_POST($base, $post_data3, 'variantannotations by region & effect');
eq_or_diff($json3, $expected_data3, "Checking the result from the variant annotation endpoint - by region");

my $json4 = json_POST($base, $post_data4, 'variantannotations by region');
eq_or_diff($json4, $expected_data4, "Checking the result from the variant annotation endpoint - by region & token");

## re-using result above
my $json5 = json_POST($base, $post_data5, 'variantannotations by region');
eq_or_diff($json5, $expected_data4, "Checking the result from the variant annotation endpoint - by region & effect");


my $bad_post1 = '{ "pageSize": 2, "variantAnnotationSet": "Ensembl", "featureIds":[ "ENST00000381657" ]}';

action_bad_post($base, $bad_post1, qr/variantAnnotationSetId/, 'Throw bad feature request at endpoint' );

my $bad_post2 = '{ "pageSize": 1, "variantAnnotationSetId": "Ensembl", "featureIds":[ "ENST00000000000" ]}';

action_bad_post($base, $bad_post2, qr/feature ENST00000000000 not found/, 'Throw bad transcript request at endpoint' );




done_testing();


