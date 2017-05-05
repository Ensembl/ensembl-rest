# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
# Copyright [2016-2017] EMBL-European Bioinformatics Institute
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

my $base=  '/ga4gh/beacon';
my $q_base = $base . '/query';
my $beaconId = "EMBL-EBI Ensembl";

# For tests setting assembly to GRCh37 as that is the assembly
# in the test database
my $assemblyId = "GRCh37";

# To check error handling for assembly differnent to DB
my $unavailable_assembly = "GRCh38";

# POST checks 
# Check for missing paramters
my $bad_post1 = '{"referenceNamex": "7", "start" : 86442403, "referenceBases": "T", "alternateBases": "C",' .
                 '"assemblyId" : "' . $assemblyId . '" }'; 

action_bad_post($q_base, $bad_post1, qr/Cannot find/, 'Throw bad request at endpoint' );

# TODO Check for extra parameters

# Testing for a variant that exists at a given location
my $post_data1 = '{"referenceName": "7", "start" : 86442403, "referenceBases": "T", "alternateBases": "C",' .
                  '"assemblyId" : "' . $assemblyId . '" }'; 

my $expected_data1 = {
  "beaconId" => $beaconId,
  "datasetAlleleResponses" => undef,
  "alleleRequest" => undef,
  "error" => undef,
  "exists" => JSON::true
};

my $json = json_POST( $q_base , $post_data1, 'POST dataset - 1 entry' );
eq_or_diff($json, $expected_data1, "GA4GH Beacon query - variant at location");

# Testing for a variant that exists at a given location by alleles swapped
my $post_data2 = '{"referenceName": "7", "start" : 86442404, "referenceBases": "C", "alternateBases": "T",' . 
                 '"assemblyId" : "' . $assemblyId . '" }';
 
my $expected_data2 = {
  "beaconId" => $beaconId,
  "datasetAlleleResponses" => undef,
  "alleleRequest" => undef,
  "error" => undef,
  "exists" => JSON::false
};

$json = json_POST( $q_base , $post_data2, 'POST dataset - 2 entry' );
eq_or_diff($json, $expected_data2, "GA4GH Beacon query - variant at location - alleles different");

# Testing for a variant that does not exist at a given location
my $post_data3 = '{"referenceName": "7", "start" : 86442405, "referenceBases": "T", "alternateBases": "C",' . 
                   '"assemblyId" : "' . $assemblyId . '" }'; 

my $expected_data3 = {
  "beaconId" => $beaconId,
  "datasetAlleleResponses" => undef,
  "alleleRequest" => undef,
  "error" => undef,
  "exists" => JSON::false
};

$json = json_POST( $q_base , $post_data3, 'POST dataset - 3 entry' );
eq_or_diff($json, $expected_data3, "GA4GH Beacon query - variant not at location");

# Testing for an unavailable assembly
my $post_data4 = '{"referenceName": "7", "start" : 86442405, "referenceBases": "T", "alternateBases": "C",' . 
                   '"assemblyId" : "' . $unavailable_assembly . '" }';
 
my $expected_data4 = {
  "beaconId" => $beaconId,
  "datasetAlleleResponses" => undef,
  "alleleRequest" => undef,
  "error" => { "errorCode" => 100,
               "message" => "Assembly ($unavailable_assembly) not available"
             },
  "exists" => undef
};

$json = json_POST($q_base, $post_data4, 'POST dataset - 4 entry' );
eq_or_diff($json, $expected_data4, "GA4GH Beacon query - assembly not available");

# GET checks
# GET and POST return the same data
# TODO - re-structure tests
# TODO Check for extra parameters
my $get_content = 'content-type=application/json';
my $get_base_uri = $q_base . '?' . $get_content;
my $uri;

# Check for missing paramters
$uri = $get_base_uri . ";referenceNamex=7;start=86442403;referenceBases=T;alternateBases=C;assemblyId=$assemblyId";
action_bad($uri, 'Bad request at endpoint' );

# Example GET ga4gh/beacon/query?content-type=application/json;referenceBases=A;alternateBases=G;assemblyId=GRCh37;referenceName=15;start=20538669
# Testing for a variant that exists at a given location
my $uri_1 = $get_base_uri . ";referenceName=7;start=86442403;referenceBases=T;alternateBases=C;assemblyId=$assemblyId";
$json = json_GET($uri_1, 'GET dataset - 1 entry');
eq_or_diff($json, $expected_data1, "GA4GH Beacon query - variant at location");

# Testing for a variant that exists at a given location by alleles swapped
my $uri_2 = $get_base_uri . ";referenceName=7;start=86442403;referenceBases=C;alternateBases=T;assemblyId=$assemblyId";
$json = json_GET($uri_2, 'GET dataset - 2 entry');
eq_or_diff($json, $expected_data2, "GA4GH Beacon query - variant at location");

# Testing for a variant that does not exist at a given location
my $uri_3 = $get_base_uri . ";referenceName=7;start=86442405;referenceBases=T;alternateBases=C;assemblyId=$assemblyId";
$json = json_GET($uri_3, 'GET dataset - 3 entry');
eq_or_diff($json, $expected_data3, "GA4GH Beacon query - variant at location");

# Testing using an assembly that does not match DB assembly
my $uri_4 = $get_base_uri . ";referenceName=7;start=86442405;referenceBases=T;alternateBases=C;assemblyId=$unavailable_assembly";
$json = json_GET($uri_4, 'GET dataset - unavailable assembly');
eq_or_diff($json, $expected_data4, "GA4GH Beacon query - unavailable assembly");
done_testing();

