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
use Catalyst::Test ();
use Bio::EnsEMBL::Test::MultiTestDB;

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new('multi');
Catalyst::Test->import('EnsEMBL::REST');

my $term = "SO:0001506";

is_json_GET("ontology/descendents/$term?zero_distance=0",
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

is_json_GET("ontology/descendents/$term?zero_distance=1",
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

is_json_GET("ontology/descendents/$term?closest_terms=1",
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

is_json_GET("ontology/descendents/$term?ontology=blibble",
   [], 'Ontology option');
   
# No test data for subset flag :(   
   
done_testing;