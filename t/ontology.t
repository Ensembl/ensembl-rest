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

my $term = "SO:0001506";

cmp_bag(json_GET("ontology/descendants/$term?zero_distance=0", 'ontology/descendants zero_distance off'),
   [
       {
           "ontology" => "SO",
           "namespace" => "sequence",
           "synonyms" => [],
           "name" => "genome",
           "subsets" => [],
           "definition" => q("A genome is the sum of genetic material within a cell or virion." [SO:immuno_workshop]),
           "accession" => "SO:0001026",
       },
       {
           "ontology" => "SO",
           "namespace" => "sequence",
           "synonyms" => [q("sequence collection" [])],
           "name" => "sequence_collection", 
           "subsets" => [],
           "definition" => q("A collection of discontinuous sequences." [SO:ke]),
           "accession" => "SO:0001260",
       }
   ], 'Check functionality of zero-distance flag'
);

cmp_bag(json_GET("ontology/descendants/$term?zero_distance=1", 'ontology/descendants zero_distance on'),
   [
       {
           "accession" => "SO:0001506",
           "definition" => '"A collection of sequences (often chromosomes) of an individual." [SO:ke]',
           "name" => 'variant_genome',
           "namespace" => 'sequence',
           "ontology" => 'SO',
           "subsets" => [],
           "synonyms" => [ q("variant genome" []) ],           
       },
       {
           "ontology" => "SO",
           "namespace" => "sequence",
           "synonyms" => [],
           "name" => "genome",
           "subsets" => [],
           "definition" => q("A genome is the sum of genetic material within a cell or virion." [SO:immuno_workshop]),
           "accession" => "SO:0001026",
       },
       {
           "ontology" => "SO",
           "namespace" => "sequence",
           "synonyms" => [q("sequence collection" [])],
           "name" => "sequence_collection", 
           "subsets" => [],
           "definition" => q("A collection of discontinuous sequences." [SO:ke]),
           "accession" => "SO:0001260",
       }
   ], 'Check functionality of zero-distance flag'
);

is_json_GET("ontology/descendants/$term?closest_terms=1",
   [
       {
           "ontology" => "SO",
           "namespace" => "sequence",
           "synonyms" => [],
           "name" => "genome",
           "subsets" => [],
           "definition" => q("A genome is the sum of genetic material within a cell or virion." [SO:immuno_workshop]),
           "accession" => "SO:0001026",
       },
   ], 'Check functionality of closest terms flag'
);

is_json_GET("ontology/descendants/$term?ontology=blibble",
   [], 'Ontology option');
   
# No test data for subset flag :(   
   
done_testing;
