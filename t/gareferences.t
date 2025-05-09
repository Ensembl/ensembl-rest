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
use Bio::EnsEMBL::Test::MultiTestDB;
use Data::Dumper;

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');
my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('multi');

Catalyst::Test->import('EnsEMBL::REST');

my $base = '/ga4gh/references/search';

## search by md5
my $post_data1  = '{ "referenceSetId": "GRCh37.p13", "md5checksum":"a718acaa6135fdca8357d5bfe94211dd", "accession":"",  "pageSize":"", "pageToken":""  }';   

## search by accession
my $post_data2  = '{ "referenceSetId": "GRCh37.p13", "md5checksum":"", "accession":"NC_000022.10",  "pageSize":"", "pageToken":""  }';

## no filter
my $post_data3  = '{ "referenceSetId": "GRCh37.p13","md5checksum":"", "accession":"", "pageSize":"2", "pageToken":""  }';

## no filter + page token
my $post_data4  = '{ "referenceSetId": "GRCh37.p13","md5checksum":"", "accession":"", "pageSize":"2", "pageToken":"2"  }';

## seek non-existant reference set
my $post_data5  = '{ "referenceSetId": "GRCh1000","md5checksum":"", "accession":"", "pageSize":"", "pageToken":""  }';


## first 2  return the same seq
my $expected_data_single =  { 
  nextPageToken => undef,
  references => [
 {
      isPrimary => "true",
      name => "22",
      md5checksum => "a718acaa6135fdca8357d5bfe94211dd",
      sourceAccessions => [
        "NC_000022.10"
      ],
      ncbiTaxonId => 9606,
      length => 51304566,
      sourceDivergence => undef,
      isDerived => "true",
      sourceURI => "https://ftp.ensembl.org/pub/release-75/fasta/homo_sapiens/dna/Homo_sapiens.GRCh37.75.dna.chromosome.22.fa.gz",
      id => "a718acaa6135fdca8357d5bfe94211dd",
    },
  ],
};

my $expected_data2 =  {
  nextPageToken => 2,                                    
  references => [                                        
    {                                                    
      id => '98c59049a2df285c76ffb1c6db8f8b96',          
      isDerived => 'true',                               
      isPrimary => 'true',                               
      length => 135006516,                               
      md5checksum => '98c59049a2df285c76ffb1c6db8f8b96', 
      name => '11',                                      
      ncbiTaxonId => 9606,                               
      sourceAccessions => [                              
        'NC_000011.9'                                    
      ],                                                 
      sourceDivergence => undef,                            
      sourceURI => 'https://ftp.ensembl.org/pub/release-75/fasta/homo_sapiens/dna/Homo_sapiens.GRCh37.75.dna.chromosome.11.fa.gz'
    },                                                    
    {                                                     
      id => '2979a6085bfe28e3ad6f552f361ed74d',           
      isDerived => 'true',                                
      isPrimary => 'true',                                
      length => 48129895,                                 
      md5checksum => '2979a6085bfe28e3ad6f552f361ed74d',  
      name => '21',                                       
      ncbiTaxonId => 9606,                                
      sourceAccessions => [                               
        'NC_000021.8'                                     
      ],                                                  
      sourceDivergence => undef,                             
      sourceURI => 'https://ftp.ensembl.org/pub/release-75/fasta/homo_sapiens/dna/Homo_sapiens.GRCh37.75.dna.chromosome.21.fa.gz'
    } 
  ]
};

my $expected_data3 =  {
  nextPageToken => 4,
  references => [                                                                                                      
    {                                                                                                                  
      id => '618366e953d6aaad97dbe4777c29375e',                                                                        
      isDerived => 'true',                                                                                             
      isPrimary => 'true',                                                                                             
      length => 159138663,                                                                                             
      md5checksum => '618366e953d6aaad97dbe4777c29375e',                                                               
      name => '7',                                                                                                     
      ncbiTaxonId => 9606,                                                                                             
      sourceAccessions => [                                                                                            
        'NC_000007.13'                                                                                                 
      ],                                                                                                               
      sourceDivergence => undef,                                          
      sourceURI => 'https://ftp.ensembl.org/pub/release-75/fasta/homo_sapiens/dna/Homo_sapiens.GRCh37.75.dna.chromosome.7.fa.gz'
    },                                                                                                                 
    {                                                                                                                  
      id => '1fa3474750af0948bdf97d5a0ee52e51',                                                                        
      isDerived => 'true',                                                                                             
      isPrimary => 'true',                                                                                             
      length => 59373566,                                                                                              
      md5checksum => '1fa3474750af0948bdf97d5a0ee52e51',                                                               
      name => 'Y',                                                                                                     
      ncbiTaxonId => 9606,                                                                                             
      sourceAccessions => [                                                                                            
        'NC_000024.9'                                                                                                  
      ],                                                                                                               
      sourceDivergence => undef,                                                                                          
      sourceURI => 'https://ftp.ensembl.org/pub/release-75/fasta/homo_sapiens/dna/Homo_sapiens.GRCh37.75.dna.chromosome.Y.fa.gz'
    }                                                                                                                  
  ] 
};

my $expected_data5 =  {
  nextPageToken => undef,
  references => []
};

my $json1 = json_POST($base, $post_data1, 'references by md5checksum');
eq_or_diff($json1, $expected_data_single, "Checking the result from the GA4GH references endpoint by md5checksum");

my $json2 = json_POST($base, $post_data2, 'references by accession');
eq_or_diff($json2, $expected_data_single, "Checking the result from the GA4GH references endpoint by accession");

my $json3 = json_POST($base, $post_data3, 'references; no filter');
eq_or_diff($json3, $expected_data2, "Checking the result from the GA4GH references endpoint with no filter");

my $json4 = json_POST($base, $post_data4, 'references; no filter + pageToken ');
eq_or_diff($json4, $expected_data3, "Checking the result from the GA4GH references endpoint with no filter ");

my $json5 = json_POST($base, $post_data5, 'references; non-existent set ');
eq_or_diff($json5, $expected_data5, "Checking the result from the GA4GH references endpoint with non existent set ");

## GET

$base =~ s/\/search//;

my $id = 'a718acaa6135fdca8357d5bfe94211dd';
my $json_get = json_GET("$base/$id", 'get references');

my $expected_get_data =  { 
      isPrimary => "true",
      name => "22",
      md5checksum => "a718acaa6135fdca8357d5bfe94211dd",
      sourceAccessions => [
        "NC_000022.10"
      ],
      ncbiTaxonId => 9606,
      length => 51304566,
      sourceDivergence => undef,
      isDerived => "true",
      sourceURI => "https://ftp.ensembl.org/pub/release-75/fasta/homo_sapiens/dna/Homo_sapiens.GRCh37.75.dna.chromosome.22.fa.gz",
      id => "a718acaa6135fdca8357d5bfe94211dd",
} ; 

eq_or_diff($json_get, $expected_get_data, "Checking the get result from the references endpoint");


## GET sequence string

my $seq_id = '1d3a93a248d92a729ee764823acbbc6b';
my $query = "$base/$seq_id/bases?start=1080164&end=1080194";
my $json_seq_get = json_GET( $query, 'get references');

my $expected_get_seq_data =  { sequence => 'CTCAAATAAGAGCCACAAACGTGGAAGATA',
                               offset   => 1080164,
                               nextPageToken  => undef
                              };

eq_or_diff($json_seq_get, $expected_get_seq_data, "Checking the get bases result from the references endpoint");


done_testing();
