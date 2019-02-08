# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
# Copyright [2016-2019] EMBL-European Bioinformatics Institute
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

my $core_ad = $dba->get_DBAdaptor('core');
my $schema_version = $core_ad->get_MetaContainer()->single_value_by_key('schema_version');

my $base=  '/ga4gh/beacon';
my $q_base = $base . '/query';

# For tests setting assembly to GRCh37 as that is the assembly
# in the test database
my $assemblyId = "GRCh37";
my $beaconId = "Ensembl " . $assemblyId;
my $datasetId = "Ensembl ". $schema_version;
my $externalURL = "http://grch37.ensembl.org/Homo_sapiens/Variation/Explore?v="; 
my $dataset_response;

# To check error handling for assembly differnent to DB
my $unavailable_assembly = "GRCh38";

# Test GET /ga4gh/beacon
my $beacon_json = json_GET('/ga4gh/beacon/', 'Get the beacon representation');
is(ref($beacon_json), 'HASH', 'HASH wanted from endpoint');
cmp_ok(keys(%{$beacon_json}), '==', 13, 'Check beacon has correct number of fields');
cmp_ok($beacon_json->{id}, 'eq', "Ensembl ". $assemblyId, 'Beacon id');
cmp_ok($beacon_json->{version}, '==', $schema_version, 'Version');

# Is there at least one dataset
cmp_ok(scalar(@{$beacon_json->{'datasets'}}), '==', 1, 'Check have one dataset');
my $first_dataset = $beacon_json->{'datasets'}->[0];
cmp_ok(keys(%{$first_dataset}), '==', 12, 'Check dataset has correct number of fields');

# Is the organization is a hash
is(ref($beacon_json->{organization}), 'HASH', 'Organization should be a hash');
cmp_ok(keys(%{$beacon_json->{organization}}), '==', 8, 'Check organization has correct number of fields');

# POST checks 
# Check for missing paramters
my $json;
my $bad_post1 = '{"referenceNamex": "7", "start" : 86442403, "referenceBases": "T", "alternateBases": "C",' .
                 '"assemblyId" : "' . $assemblyId . '" }'; 

action_bad_post($q_base, $bad_post1, qr/Cannot find/, 'Throw bad request at endpoint' );

# TODO Check for extra parameters

# Testing for a variant that exists at a given location
my $post_data1 = '{"referenceName": "7", "start" : 86442403, "referenceBases": "T", "alternateBases": "C",' .
                  '"assemblyId" : "' . $assemblyId . '" }'; 

my $allele_request = {
  "referenceName" => "7",
  "start" => "86442403",
  "referenceBases" => "T",
  "alternateBases" => "C",
  "assemblyId" => $assemblyId,
  "datasetIds" => undef,
  "includeDatasetResponses" => undef };

my $expected_data1 = {
  "beaconId" => $beaconId,
  "exists" => JSON::true,
  "error" => undef,
  "alleleRequest" => $allele_request,
  "datasetAlleleResponses" => undef
};

$json = json_POST( $q_base , $post_data1, 'POST dataset - 1 entry' );
eq_or_diff($json, $expected_data1, "GA4GH Beacon query - variant at location");

# Found variant with includeDataSetResponses true
my $post_data1_ds = '{"referenceName": "7", "start" : 86442403, "referenceBases": "T", "alternateBases": "C",' .
                  '"assemblyId" : "' . $assemblyId . '", "includeDatasetResponses":"true"}'; 

$allele_request = {
  "referenceName" => "7",
  "start" => "86442403",
  "referenceBases" => "T",
  "alternateBases" => "C",
  "assemblyId" => $assemblyId,
  "datasetIds" => undef,
  "includeDatasetResponses" => JSON::true };

$dataset_response = {
   "datasetId" => $datasetId,
   "exists" => JSON::true,
   "error" => undef,
   "frequency" => undef,
   "variantCount" => undef,
   "callCount" => undef,
   "sampleCount" => undef,
   "note" => undef,
   "externalUrl" => $externalURL . "rs2299222",
   "info" => undef
};

my $expected_data1_ds = {
  "beaconId" => $beaconId,
  "exists" => JSON::true,
  "error" => undef,
  "alleleRequest" => $allele_request,
  "datasetAlleleResponses" => [$dataset_response]
};

$json = json_POST( $q_base , $post_data1_ds, 'POST query 1 - dataset response true' );
eq_or_diff($json, $expected_data1_ds, "GA4GH Beacon ds 1 - variant exists - dataset response");

# Found variant with includeDataSetResponses false
$post_data1_ds = '{"referenceName": "7", "start" : 86442403, "referenceBases": "T", "alternateBases": "C",' .
                  '"assemblyId" : "' . $assemblyId . '", "includeDatasetResponses":"false"}'; 

$allele_request = {
  "referenceName" => "7",
  "start" => "86442403",
  "referenceBases" => "T",
  "alternateBases" => "C",
  "assemblyId" => $assemblyId,
  "datasetIds" => undef,
  "includeDatasetResponses" => JSON::false
};

my $expected_data1_ds_false = {
  "beaconId" => $beaconId,
  "exists" => JSON::true,
  "error" => undef,
  "alleleRequest" => $allele_request,
  "datasetAlleleResponses" => undef
};

$json = json_POST( $q_base , $post_data1_ds, 'POST query 1 - dataset response false' );
eq_or_diff($json, $expected_data1_ds_false, "GA4GH Beacon ds 1 - variant exists - no dataset response'");

# Found variant with includeDataSetResponse empty
$post_data1_ds = '{"referenceName": "7", "start" : 86442403, "referenceBases": "T", "alternateBases": "C",' .
                  '"assemblyId" : "' . $assemblyId . '", "includeDatasetResponses":""}'; 

$allele_request = {
  "referenceName" => "7",
  "start" => "86442403",
  "referenceBases" => "T",
  "alternateBases" => "C",
  "assemblyId" => $assemblyId,
  "datasetIds" => undef,
  "includeDatasetResponses" => undef
};

my $expected_data1_ds_empty = {
  "beaconId" => $beaconId,
  "exists" => JSON::true,
  "error" => undef,
  "alleleRequest" => $allele_request,
  "datasetAlleleResponses" => undef
};

$json = json_POST( $q_base , $post_data1_ds, 'POST query 1 - dataset response empty' );
eq_or_diff($json, $expected_data1_ds_empty, "GA4GH Beacon ds 1 - variant exists - dataset response empty");


# Testing for a variant that exists at a given location by alleles swapped
my $post_data2 = '{"referenceName": "7", "start" : 86442403, "referenceBases": "C", "alternateBases": "T",' . 
                 '"assemblyId" : "' . $assemblyId . '" }';
 
$allele_request = {
  "referenceName" => "7",
  "start" => "86442403",
  "referenceBases" => "C",
  "alternateBases" => "T",
  "assemblyId" => $assemblyId,
  "datasetIds" => undef,
  "includeDatasetResponses" => undef };

my $expected_data2 = {
  "beaconId" => $beaconId,
  "exists" => JSON::false,
  "error" => undef,
  "alleleRequest" => $allele_request,
  "datasetAlleleResponses" => undef
};

$json = json_POST( $q_base , $post_data2, 'POST dataset - 2 entry' );
eq_or_diff($json, $expected_data2, "GA4GH Beacon query - variant at location - alleles different");


# Test with includeDatasetResponses
# Variant not found  with includeDataSetResponses true
my $post_data2_ds = '{"referenceName": "7", "start" : 86442403, "referenceBases": "C", "alternateBases": "T",' .
                  '"assemblyId" : "' . $assemblyId . '", "includeDatasetResponses":"true"}'; 

$allele_request = {
  "referenceName" => "7",
  "start" => "86442403",
  "referenceBases" => "C",
  "alternateBases" => "T",
  "assemblyId" => $assemblyId,
  "datasetIds" => undef,
  "includeDatasetResponses" => JSON::true };

$dataset_response = {
   "datasetId" => $datasetId,
   "exists" => JSON::false,
   "error" => undef,
   "frequency" => undef,
   "variantCount" => undef,
   "callCount" => undef,
   "sampleCount" => undef,
   "note" => undef,
   "externalUrl" => undef,
   "info" => undef
};

my $expected_data2_ds = {
  "beaconId" => $beaconId,
  "exists" => JSON::false,
  "error" => undef,
  "alleleRequest" => $allele_request,
  "datasetAlleleResponses" => [$dataset_response]
};

$json = json_POST( $q_base , $post_data2_ds, 'POST query 2 - dataset response true' );
eq_or_diff($json, $expected_data2_ds, "GA4GH Beacon ds 2 - variant not exists - dataset response");

# Testing for a variant that does not exist at a given location
my $post_data3 = '{"referenceName": "7", "start" : 86442405, "referenceBases": "T", "alternateBases": "C",' . 
                   '"assemblyId" : "' . $assemblyId . '" }'; 

$allele_request = {
  "referenceName" => "7",
  "start" => "86442405",
  "referenceBases" => "T",
  "alternateBases" => "C",
  "assemblyId" => $assemblyId,
  "datasetIds" => undef,
  "includeDatasetResponses" => undef };

my $expected_data3 = {
  "beaconId" => $beaconId,
  "exists" => JSON::false,
  "error" => undef,
  "alleleRequest" => $allele_request,
  "datasetAlleleResponses" => undef
};

$json = json_POST( $q_base , $post_data3, 'POST dataset - 3 entry' );
eq_or_diff($json, $expected_data3, "GA4GH Beacon query - variant not at location");

# Testing for an unavailable assembly
my $post_data4 = '{"referenceName": "7", "start" : 86442405, "referenceBases": "T", "alternateBases": "C",' . 
                   '"assemblyId" : "' . $unavailable_assembly . '" }';
 
#my $expected_data4 = {
#  "beaconId" => $beaconId,
#  "datasetAlleleResponses" => undef,
#  "alleleRequest" => undef,
#  "error" => { "errorCode" => 100,
#               "message" => "Assembly ($unavailable_assembly) not available"
#             },
#  "exists" => undef
#};

$allele_request = {
  "referenceName" => "7",
  "start" => "86442405",
  "referenceBases" => "T",
  "alternateBases" => "C",
  "assemblyId" => $unavailable_assembly,
  "datasetIds" => undef,
  "includeDatasetResponses" => undef };

my $expected_data4 = {
  "beaconId" => $beaconId,
  "exists" => undef,
  "error" => { "errorCode" => 100,
               "message" => "Assembly ($unavailable_assembly) not available"
             },
  "alleleRequest" => $allele_request,
  "datasetAlleleResponses" => undef
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

# Testing with an includeDataSetResponses
my $uri_ds_1 = $get_base_uri . ";referenceName=7;start=86442403;referenceBases=T;alternateBases=C;assemblyId=$assemblyId;includeDatasetResponses=true";
$json = json_GET($uri_ds_1, 'GET dataset - 1 entry with dataset response');
eq_or_diff($json, $expected_data1_ds, "GA4GH Beacon query - variant exists - dataset response");

# Testing for a variant that exists at a given location by alleles swapped
my $uri_2 = $get_base_uri . ";referenceName=7;start=86442403;referenceBases=C;alternateBases=T;assemblyId=$assemblyId";
$json = json_GET($uri_2, 'GET dataset - 2 entry');
eq_or_diff($json, $expected_data2, "GA4GH Beacon query - variant at location");

# Testing with an includeDataSetResponses
my $uri_ds_2 = $get_base_uri . ";referenceName=7;start=86442403;referenceBases=C;alternateBases=T;assemblyId=$assemblyId;includeDatasetResponses=true";
$json = json_GET($uri_ds_2, 'GET dataset - 2 entry');
eq_or_diff($json, $expected_data2_ds, "GA4GH Beacon query - no variant - dataset response");

# Testing for a variant that does not exist at a given location
my $uri_3 = $get_base_uri . ";referenceName=7;start=86442405;referenceBases=T;alternateBases=C;assemblyId=$assemblyId";
$json = json_GET($uri_3, 'GET dataset - 3 entry');
eq_or_diff($json, $expected_data3, "GA4GH Beacon query - variant at location");

# Testing using an assembly that does not match DB assembly
my $uri_4 = $get_base_uri . ";referenceName=7;start=86442405;referenceBases=T;alternateBases=C;assemblyId=$unavailable_assembly";
$json = json_GET($uri_4, 'GET dataset - unavailable assembly');
eq_or_diff($json, $expected_data4, "GA4GH Beacon query - unavailable assembly");
done_testing();

