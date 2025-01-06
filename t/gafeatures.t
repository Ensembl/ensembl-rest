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

my $set_version = get_set_version($dba);

my $base = '/ga4gh/features';

my $post_data1 = '{"pageSize": 1, "featureSetId": "Ensembl", "start":1080164, "end": 1190164, "referenceName":"6", "featureTypes":["transcript"]}';

my $post_data2 = '{"pageSize": 1, "featureSetId": "Ensembl", "start":1080164, "end": 1190164, "referenceName":"6", "featureTypes":["transcript"], "pageToken": 1186752}';

my $post_data3 = '{"pageSize": 1, "featureSetId": "Ensembl", "start":1080164, "end": 1090164, "referenceName":"6", "featureTypes":["gene"] }';


my $expected_data1 = {                                               
  features => [                                 
    {                                           
      attributes => {                           
        vals => { 
        biotype => ['protein_coding'],            
        created => ['1209467861'],                
        source  => ['ensembl'],
        external_name => ['AL033381.1-201'],
        updated => ['1209467861'],        
        version => ['1']
       }
      },                                        
      childIds => [ 
        'ENSE00001271861.1', 
        'ENSE00001271874.1', 
        'ENSE00001271869.1', 
        'ENSP00000320396.1' 
      ],
      parentId => 'ENSG00000176515.1',
      featureSetId => $set_version,  
      featureType => {                          
        id => 'SO:0000673',                     
        term => 'transcript',                   
        sourceName => 'SO',
        sourceVersion => undef,                          
      },                                        
      id => 'ENST00000314040.1',
      start => 1080163,
      end   => 1105181,
      strand => 'NEG_STRAND', 
      referenceName => '6', 
    }
  ],
  nextPageToken => 1186752
};                                         

my $expected_data2 = {
  features => [
    {                                           
      attributes => {                           
       vals => {
        biotype => ['snoRNA'],                    
        created => ['1268996515'],
        source => ['ensembl'],
        external_name => ['snoU13.72-201'],              
        updated => ['1268996515'],                
        structure => ['1:103	.18(3.2(4.2(5.5)5.7(8.2(.(6.3)3.)3.).2)8.3)4.2)3'],
        version => ['1']
       }                          
      },
      childIds => [ 
          'ENSE00001808595.1'
      ],                           
      featureSetId => $set_version,  
      featureType => {                          
        id => 'SO:0000673',                     
        term => 'transcript',                   
        sourceName => 'SO',
        sourceVersion => undef,                          
      },                                        
      id => 'ENST00000459140.1',                  
      start => 1186752,  
      end  => 1186855,
      referenceName => '6',
      strand => 'NEG_STRAND',
      parentId => 'ENSG00000238438.1'
    }                                           
  ],                                            
  nextPageToken => undef   
}; 



my $expected_data3 = {                                      
features => [                        
  {                                  
    attributes => {
     vals => {               
      'gene gc' => ['44.14'],          
      biotype => ['protein_coding'],   
      created => ['1209467861'],       
      external_name => ['AL033381.1'],              
      source => ['ensembl'],  
      updated => ['1209467861'],       
      version => ['1'] 
     }                
    },                               
    childIds => [                    
      'ENST00000314040.1'            
    ],                               
    end => 1105181,                  
    featureSetId => $set_version,     
    featureType => {                 
      id => 'SO:0000704',            
      sourceName => 'SO',            
      sourceVersion => undef,        
      term => 'gene'                 
    },                               
    id => 'ENSG00000176515.1',       
    parentId => '',               
    referenceName => '6',            
    start => 1080163,                
    strand => 'NEG_STRAND'           
  }                                  
 ],                                   
 nextPageToken => undef                        
};




my $postbase = $base ."/search";

my $json1 = json_POST( $postbase, $post_data1, 'sequence annotations ' );
eq_or_diff($json1, $expected_data1, "Checking the result from the sequence annotations endpoint");

my $json2 = json_POST($postbase, $post_data2, 'sequence annotations by page token');
eq_or_diff($json2, $expected_data2, "Checking the result from the sequence annotations endpoint - by page token");

my $json3 = json_POST($postbase, $post_data3, 'sequence annotations - gene');
eq_or_diff($json3, $expected_data3, "Checking the result from the sequence annotations endpoint - by region");




## check rubbish handled
my $bad_post1 = '{ "pageSize": 2, "SetIds": [1],"features":[{"source":"SO","name":"transcript","id":"SO:0000673"}]}';

action_bad_post($postbase, $bad_post1, qr/Cannot find/, 'Throw bad request at endpoint' );



### check get

my $id = 'ENST00000568244.1';
my $json4 = json_GET("$base/$id", 'get transcript');

my $expected_data4 =  {                                           
      attributes => {                           
       vals => {
        biotype => ['antisense'],                 
        created => ['1321005463'],                
        author  => ['Havana'],
        name    => ['RP4-668J24.2-001'],
        external_name => ['RP4-668J24.2-001'],
        source => ['havana'],      
        updated => ['1321005463'],                
        version => ['1']                          
       }
      },
      childIds => [
       'ENSE00002577443.1'
      ],                          
      featureSetId => $set_version,  
      featureType => {                          
        id => 'SO:0000673',                     
        term => 'transcript',                   
        sourceName => 'SO',
        sourceVersion => undef                          
      },                                        
      id => 'ENST00000568244.1',                  
      start => 1384024,                            
      end   => 1385301,
      strand => 'NEG_STRAND',              
      referenceName => '6',
      parentId => 'ENSG00000261730.1',
};

eq_or_diff($json4, $expected_data4, "Checking the get result from the sequence annotation endpoint");

sub get_set_version{

  my $multi = shift;

  my $core_ad = $multi->get_DBAdaptor('core');

  return "Ensembl."  . $core_ad->get_MetaContainerAdaptor()->schema_version() . ".GRCh37"; 
}


done_testing();


