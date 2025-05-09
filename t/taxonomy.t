# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
# Copyright [2016-2025] EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
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
use Test::Deep;
use Catalyst::Test ();
use Bio::EnsEMBL::Test::MultiTestDB;

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new('multi');
Catalyst::Test->import('EnsEMBL::REST');

my $expected = qq(); 
$expected = {scientific_name => "Homo sapiens",
  name => "Homo sapiens",
  id => "9606",
  tags => {"ensembl_alias_name" => ["Human"],"scientific_name" => ["Homo sapiens"],"genbank_common_name" => ["human"],"common_name" => ["man"],"name" => ["Homo sapiens"],"authority" => ["Homo sapiens Linnaeus, 1758"]},
  leaf => 1
};
# Leaf => 1 is only true in test data.

cmp_deeply(json_GET("/taxonomy/id/9606?content-type=application/json;simple=1",'taxonomy/id'), $expected, 'Check id endpoint with valid data');
action_bad("/taxonomyid/-1", 'ID should not be found.');

cmp_deeply(json_GET("/taxonomy/name/human?simple=1",'taxonomy/name'), [$expected], 'Test human lookup with name');
my $result = json_GET("/taxonomy/name/canis%?simple=1",'Select wolf');

cmp_bag([ map { $_->{id} } @$result], ['9612','9615','9611'],'Wolf, Beagle and Canis found via wildcard on Canis');

$result = json_GET("/taxonomy/name/canis familiaris?simple=1",'Select dog');
is($result->[0]->{'id'},'9615','Dog called by name');


$expected = [{ 
  children => [
    {
      id => '33154',                        
      leaf => 0,                            
      name => 'Opisthokonta',               
      scientific_name => 'Opisthokonta',    
      tags => {                             
        authority => ['Opisthokonta Cavalier-Smith 1987'],                                  
        'ensembl_alias_name' => ['Animals and Fungi'],                                  
        'ensembl_timetree_mya' => ['1500'],                                  
        name => ['Opisthokonta'],                                  
        'scientific_name' => ['Opisthokonta'],                                  
        synonym => ['Fungi/Metazoa group','opisthokonts']                                   
      }                                     
    }
  ],
  id => '2759',
  leaf => 0,
  name => 'Eukaryota',
  parent => {
    id => '131567' ,
    leaf => 0 ,
    name => 'cellular organisms' ,
    scientific_name => 'cellular organisms' ,
    tags => {
      name => ['cellular organisms'],
      'scientific_name' => ['cellular organisms'],
      synonym => ['biota'],
    }
  },
  scientific_name => 'Eukaryota',
  tags => {
    'blast_name' => ['eukaryotes'],                        
    'common_name' => ['eukaryotes'],                        
    'genbank_common_name' => ['eucaryotes'],                        
    name => ['Eukaryota'],                        
    'scientific_name' => ['Eukaryota'],                        
    synonym => ['Eucarya','Eucaryotae','Eukarya','Eukaryotae']                         
  },

}];

cmp_bag(json_GET("/taxonomy/classification/2759?content-type=application/json",'taxononmy/classification'), $expected, 'Test classification response for Eukaryotes');
action_bad("/taxonomy/classification?A;content-type=application/json", 'Classification in bad data case');

done_testing();
