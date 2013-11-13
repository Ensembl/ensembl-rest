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

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new();
Catalyst::Test->import('EnsEMBL::REST');

my $expected = qq(); 
#is_json_GET("/lookup/id/$basic_id?expand=1;format=condensed", $expanded_response, 'Get of a known ID with expanded option will return transcripts as well');
#is_json_GET("/taxonomy/classification/homo sapiens", $expected, 'Check taxonomy endpoint with valid data');


$expected = qq({"scientific_name":"Homo sapiens","name":"Homo sapiens","id":"9606","tags":{"ensembl alias name":["Human"],"scientific name":["Homo sapiens"],"genbank common name":["human"],"common name":["man"],"name":["Homo sapiens"],"authority":["Homo sapiens Linnaeus, 1758"]},"leaf":0});
is_json_GET("/taxonomy/id/9606?content-type=application/json;simple=1", $expected, 'Check id endpoint with valid data');
action_bad("/taxonomyid/11111111111111", 'ID should not be found. Fail');

done_testing();