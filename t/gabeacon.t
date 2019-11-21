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
use Data::Dumper;

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
my $beaconId = "ensembl.grch37";
my $datasetId = "Ensembl ". $schema_version;
my $externalURL = "http://grch37.ensembl.org/Homo_sapiens/Variation/Explore?v="; 
my $dataset_response;

# To check error handling for assembly differnent to DB
my $unavailable_assembly = "GRCh38";

# Test GET /ga4gh/beacon
my $beacon_json = json_GET('/ga4gh/beacon/', 'Get the beacon representation');
is(ref($beacon_json), 'HASH', 'HASH wanted from endpoint');
cmp_ok(keys(%{$beacon_json}), '==', 13, 'Check beacon has correct number of fields');
cmp_ok($beacon_json->{id}, 'eq', $beaconId, 'Beacon id');
cmp_ok($beacon_json->{version}, '==', $schema_version, 'Version');

# Is there at least one dataset
cmp_ok(scalar(@{$beacon_json->{'datasets'}}), '==', 42, 'Check number of datasets');
my $first_dataset = $beacon_json->{'datasets'}->[0];
cmp_ok(keys(%{$first_dataset}), '==', 12, 'Check dataset has correct number of fields');

# Is the organization is a hash
is(ref($beacon_json->{organization}), 'HASH', 'Organization should be a hash');
cmp_ok(keys(%{$beacon_json->{organization}}), '==', 8, 'Check organization has correct number of fields');

# POST checks 
my $json;

# TODO Check for extra parameters

# Testing for a variant that exists at a given location
my $post_data1 = '{"referenceName": "7", "start" : 86442403, "referenceBases": "T", "alternateBases": "C",' .
                  '"assemblyId" : "' . $assemblyId . '" }'; 

my $allele_request = {
  "referenceName" => "7",
  "start" => "86442403",
  "variantType" => undef,
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
  "datasetAlleleResponses" => undef,
};

$json = json_POST( $q_base , $post_data1, 'POST dataset - 1 entry' );
eq_or_diff($json, $expected_data1, "GA4GH Beacon query - variant at location");

# Found variant with includeDataSetResponses HIT
my $post_data1_ds = '{"referenceName": "7", "start" : 86442403, "referenceBases": "T", "alternateBases": "C",' .
                  '"assemblyId" : "' . $assemblyId . '", "includeDatasetResponses" : "HIT", "datasetIds" : "hapmap_ceu,clin_assoc"}'; 

$allele_request = {
  "referenceName" => "7",
  "start" => "86442403",
  "variantType" => undef,
  "referenceBases" => "T",
  "alternateBases" => "C",
  "assemblyId" => $assemblyId,
  "datasetIds" => 'hapmap_ceu,clin_assoc',
  "includeDatasetResponses" => 'HIT' };

$dataset_response = {
   "datasetId" => 'hapmap_ceu',
   "exists" => JSON::true,
   "error" => undef,
   "frequency" => undef,
   "variantCount" => 1,
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

$json = json_POST( $q_base , $post_data1_ds, 'POST query 1 - dataset response HIT' );
eq_or_diff($json, $expected_data1_ds, "GA4GH Beacon ds 1 - variant exists - dataset response");

# Found variant with includeDataSetResponses MISS
my $post_data3_ds = '{"referenceName": "7", "start" : 86442403, "referenceBases": "T", "alternateBases": "C",' .
                  '"assemblyId" : "' . $assemblyId . '", "includeDatasetResponses" : "MISS", "datasetIds" : "hapmap_ceu,clin_assoc"}';

my $allele_request_miss = {
  "referenceName" => "7",
  "start" => "86442403",
  "variantType" => undef,
  "referenceBases" => "T",
  "alternateBases" => "C",
  "assemblyId" => $assemblyId,
  "datasetIds" => 'hapmap_ceu,clin_assoc',
  "includeDatasetResponses" => 'MISS' };

my $dataset_response_miss = {
   "datasetId" => 'clin_assoc',
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

my $expected_data3_ds = {
  "beaconId" => $beaconId,
  "exists" => JSON::true,
  "error" => undef,
  "alleleRequest" => $allele_request_miss,
  "datasetAlleleResponses" => [$dataset_response_miss]
};

$json = json_POST( $q_base , $post_data3_ds, 'POST query 3 - dataset response MISS' );
eq_or_diff($json, $expected_data3_ds, "GA4GH Beacon ds 3 - variant exists - dataset response MISS");

# Not found variant with dataset and includeDataSetResponses ALL
my $post_data4_ds = '{"referenceName": "7", "start" : 86442403, "referenceBases": "T", "alternateBases": "C",' .
                  '"assemblyId" : "' . $assemblyId . '", "includeDatasetResponses" : "ALL", "datasetIds" : "clin_assoc"}';

my $allele_request_all = {
  "referenceName" => "7",
  "start" => "86442403",
  "variantType" => undef,
  "referenceBases" => "T",
  "alternateBases" => "C",
  "assemblyId" => $assemblyId,
  "datasetIds" => 'clin_assoc',
  "includeDatasetResponses" => 'ALL' };

my $dataset_response_all = {
   "datasetId" => 'clin_assoc',
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

my $expected_data4_ds = {
  "beaconId" => $beaconId,
  "exists" => JSON::false,
  "error" => undef,
  "alleleRequest" => $allele_request_all,
  "datasetAlleleResponses" => [$dataset_response_all]
};

$json = json_POST( $q_base , $post_data4_ds, 'POST query 4 - dataset response ALL' );
eq_or_diff($json, $expected_data4_ds, "GA4GH Beacon ds 4 - variant exists - dataset response ALL");

# Found variant with includeDataSetResponses NONE
$post_data1_ds = '{"referenceName": "7", "start" : 86442403, "referenceBases": "T", "alternateBases": "C",' .
                  '"assemblyId" : "' . $assemblyId . '", "includeDatasetResponses":"NONE"}'; 

$allele_request = {
  "referenceName" => "7",
  "start" => "86442403",
  "variantType" => undef,
  "referenceBases" => "T",
  "alternateBases" => "C",
  "assemblyId" => $assemblyId,
  "datasetIds" => undef,
  "includeDatasetResponses" => 'NONE'
};

my $expected_data1_ds_false = {
  "beaconId" => $beaconId,
  "exists" => JSON::true,
  "error" => undef,
  "alleleRequest" => $allele_request,
  "datasetAlleleResponses" => undef
};

$json = json_POST( $q_base , $post_data1_ds, 'POST query 1 - dataset response NONE' );
eq_or_diff($json, $expected_data1_ds_false, "GA4GH Beacon ds 1 - variant exists - no dataset response");

# Found variant with includeDataSetResponse empty
$post_data1_ds = '{"referenceName": "7", "start" : 86442403, "referenceBases": "T", "alternateBases": "C",' .
                  '"assemblyId" : "' . $assemblyId . '", "includeDatasetResponses":""}'; 

$allele_request = {
  "referenceName" => "7",
  "start" => "86442403",
  "variantType" => undef,
  "referenceBases" => "T",
  "alternateBases" => "C",
  "assemblyId" => $assemblyId,
  "datasetIds" => undef,
  "includeDatasetResponses" => ""
};

my $expected_data1_ds_empty = {
  "beaconId" => $beaconId,
  "exists" => undef,
  "error" => { "errorCode" => 400,
               "errorMessage" => "Invalid includeDatasetResponses"
             },
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
  "variantType" => undef,
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
# Variant not found  with includeDataSetResponses ALL
my $post_data2_ds = '{"referenceName": "7", "start" : 86442403, "referenceBases": "C", "alternateBases": "T",' .
                  '"assemblyId" : "' . $assemblyId . '", "includeDatasetResponses" : "ALL", "datasetIds" : "hapmap_jpt"}'; 

$allele_request = {
  "referenceName" => "7",
  "start" => "86442403",
  "variantType" => undef,
  "referenceBases" => "C",
  "alternateBases" => "T",
  "assemblyId" => $assemblyId,
  "datasetIds" => 'hapmap_jpt',
  "includeDatasetResponses" => 'ALL' };

$dataset_response = {
   "datasetId" => 'hapmap_jpt',
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
  "datasetAlleleResponses" => [$dataset_response],
};

$json = json_POST( $q_base , $post_data2_ds, 'POST query 2 - dataset response ALL' );
eq_or_diff($json, $expected_data2_ds, "GA4GH Beacon ds 2 - variant not exists - dataset response");

# Testing for a variant that does not exist at a given location
my $post_data3 = '{"referenceName": "7", "start" : 86442405, "referenceBases": "T", "alternateBases": "C",' . 
                   '"assemblyId" : "' . $assemblyId . '" }'; 

$allele_request = {
  "referenceName" => "7",
  "start" => "86442405",
  "variantType" => undef,
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
  "variantType" => undef,
  "assemblyId" => $unavailable_assembly,
  "datasetIds" => undef,
  "includeDatasetResponses" => undef };

my $expected_data4 = {
  "beaconId" => $beaconId,
  "exists" => undef,
  "error" => { "errorCode" => 400,
               "errorMessage" => "User provided assemblyId ($unavailable_assembly) does not match with dataset assembly ($assemblyId)"
             },
  "alleleRequest" => $allele_request,
  "datasetAlleleResponses" => undef
};

$json = json_POST($q_base, $post_data4, 'POST dataset - 4 entry' );
eq_or_diff($json, $expected_data4, "GA4GH Beacon query - assembly not available");

# Testing for missing parameter 
my $post_data5 = '{"referenceNamex": "7", "start" : 86442403, "referenceBases": "T", "alternateBases": "C",' .
                   '"assemblyId" : "' . $assemblyId . '" }';

$allele_request = {
  "referenceName" => undef,
  "start" => "86442403",
  "referenceBases" => "T",
  "alternateBases" => "C",
  "variantType" => undef,
  "assemblyId" => $assemblyId,
  "datasetIds" => undef,
  "includeDatasetResponses" => undef };

my $expected_data5 = {
  "beaconId" => $beaconId,
  "exists" => undef,
  "error" => { "errorCode" => 400,
               "errorMessage" => "Missing mandatory parameter referenceName"
             },
  "alleleRequest" => $allele_request,
  "datasetAlleleResponses" => undef
};


$json = json_POST($q_base, $post_data5, 'POST dataset - 5 entry' );
eq_or_diff($json, $expected_data5, "GA4GH Beacon query - missing parameter");

# Testing invalid parameter
my $post_data6 = '{"referenceName": "7", "start" : 86442403, "variantType" : "SNV", "referenceBases": "T", "alternateBases": "C",' .
                   '"assemblyId" : "' . $assemblyId . '" }';

$allele_request = {
  "referenceName" => "7",
  "start" => "86442403",
  "variantType" => "SNV",
  "referenceBases" => "T",
  "alternateBases" => "C",
  "assemblyId" => $assemblyId,
  "datasetIds" => undef,
  "includeDatasetResponses" => undef };

my $expected_data6 = {
  "beaconId" => $beaconId,
  "exists" => undef,
  "error" => { "errorCode" => 400,
               "errorMessage" => "Invalid parameter variantType"
             },
  "alleleRequest" => $allele_request,
  "datasetAlleleResponses" => undef
};

$json = json_POST( $q_base , $post_data6, 'POST dataset - 6 invalid parameter' );
eq_or_diff($json, $expected_data6, "GA4GH Beacon query - invalid parameter");

# Testing CNV 
my $post_data7 = '{"referenceName": "8", "start" : 7803890, "end" : 7825339, "variantType" : "CNV", "referenceBases": "N", ' .
                   '"assemblyId" : "' . $assemblyId . '" }';

$allele_request = {
  "referenceName" => "8",
  "start" => "7803890",
  "end" => "7825339",
  "variantType" => "CNV",
  "referenceBases" => "N",
  "alternateBases" => undef,
  "assemblyId" => $assemblyId,
  "datasetIds" => undef,
  "includeDatasetResponses" => undef };

my $expected_data7 = {
  "beaconId" => $beaconId,
  "exists" => JSON::true,
  "error" => undef,
  "alleleRequest" => $allele_request,
  "datasetAlleleResponses" => undef
};

$json = json_POST( $q_base , $post_data7, 'POST dataset - 7 structural variant' );
eq_or_diff($json, $expected_data7, "GA4GH Beacon query - structural variant");

$allele_request = {
  "referenceName" => "8",
  "start" => undef,
  "startMin" => "7803800",
  "startMax" => "7803900",
  "endMin" => "7825300",
  "endMax" => "7825400",
  "variantType" => "CNV",
  "referenceBases" => "N",
  "alternateBases" => undef,
  "assemblyId" => $assemblyId,
  "datasetIds" => undef,
  "includeDatasetResponses" => undef };

my $expected_data8 = {
  "beaconId" => $beaconId,
  "exists" => JSON::true,
  "error" => undef,
  "alleleRequest" => $allele_request,
  "datasetAlleleResponses" => undef
};

my $allele_request_2 = {
  "referenceName" => "11",
  "start" => "6303492",
  "variantType" => undef,
  "referenceBases" => "T",
  "alternateBases" => "GT",
  "assemblyId" => $assemblyId,
  "datasetIds" => undef,
  "includeDatasetResponses" => undef
};

my $expected_data9 = {
  "beaconId" => $beaconId,
  "exists" => JSON::true,
  "error" => undef,
  "alleleRequest" => $allele_request_2,
  "datasetAlleleResponses" => undef
};

# GET checks
# GET and POST return the same data
# TODO - re-structure tests
# TODO Check for extra parameters
my $get_content = 'content-type=application/json';
my $get_base_uri = $q_base . '?' . $get_content;
my $uri;

# Check for missing parameters
$uri = $get_base_uri . ";referenceNamex=7;start=86442403;referenceBases=T;alternateBases=C;assemblyId=$assemblyId";
$json = json_GET($uri, 'GET dataset 5 - missing parameter');
eq_or_diff($json, $expected_data5, "GA4GH Beacon query - missing parameter");

# Example GET ga4gh/beacon/query?content-type=application/json;referenceBases=A;alternateBases=G;assemblyId=GRCh37;referenceName=15;start=20538669
# Testing for a variant that exists at a given location
my $uri_1 = $get_base_uri . ";referenceName=7;start=86442403;referenceBases=T;alternateBases=C;assemblyId=$assemblyId";
$json = json_GET($uri_1, 'GET dataset - 1 entry');
eq_or_diff($json, $expected_data1, "GA4GH Beacon query - variant at location");

# Testing with an includeDataSetResponses
my $uri_ds_1 = $get_base_uri . ";referenceName=7;start=86442403;referenceBases=T;alternateBases=C;assemblyId=$assemblyId;includeDatasetResponses=HIT;datasetIds=hapmap_ceu,clin_assoc";
$json = json_GET($uri_ds_1, 'GET dataset - 1 entry with dataset response');
eq_or_diff($json, $expected_data1_ds, "GA4GH Beacon query - variant exists - dataset response HIT");

# Testing for a variant that exists at a given location by alleles swapped
my $uri_2 = $get_base_uri . ";referenceName=7;start=86442403;referenceBases=C;alternateBases=T;assemblyId=$assemblyId";
$json = json_GET($uri_2, 'GET dataset - 2 entry');
eq_or_diff($json, $expected_data2, "GA4GH Beacon query - variant at location");

# Testing with an includeDataSetResponses
my $uri_ds_2 = $get_base_uri . ";referenceName=7;start=86442403;referenceBases=C;alternateBases=T;assemblyId=$assemblyId;includeDatasetResponses=ALL;datasetIds=hapmap_jpt";
$json = json_GET($uri_ds_2, 'GET dataset - 2 entry');
eq_or_diff($json, $expected_data2_ds, "GA4GH Beacon query - no variant - dataset response ALL");

# Testing with an includeDataSetResponses
my $uri_ds_3 = $get_base_uri . ";referenceName=7;start=86442403;referenceBases=T;alternateBases=C;assemblyId=$assemblyId;includeDatasetResponses=MISS;datasetIds=hapmap_ceu,clin_assoc";
$json = json_GET($uri_ds_3, 'GET dataset - 3 entry');
eq_or_diff($json, $expected_data3_ds, "GA4GH Beacon query - variant exists - dataset response MISS");

# Testing for a variant that does not exist at a given location
my $uri_3 = $get_base_uri . ";referenceName=7;start=86442405;referenceBases=T;alternateBases=C;assemblyId=$assemblyId";
$json = json_GET($uri_3, 'GET dataset - 3 entry');
eq_or_diff($json, $expected_data3, "GA4GH Beacon query - variant at location");

# Testing using an assembly that does not match DB assembly
my $uri_4 = $get_base_uri . ";referenceName=7;start=86442405;referenceBases=T;alternateBases=C;assemblyId=$unavailable_assembly";
$json = json_GET($uri_4, 'GET dataset - unavailable assembly');
eq_or_diff($json, $expected_data4, "GA4GH Beacon query - unavailable assembly");

# Testing invalid parameter
my $uri_5 = $get_base_uri . ";referenceName=7;start=86442403;variantType=SNV;referenceBases=T;alternateBases=C;assemblyId=$assemblyId";
$json = json_GET($uri_5, 'GET dataset 6 - invalid parameter');
eq_or_diff($json, $expected_data6, "GA4GH Beacon query - invalid parameter");

# Testing structural variant with precise coordinates
my $uri_6 = $get_base_uri . ";referenceName=8;start=7803890;end=7825339;variantType=CNV;referenceBases=N;assemblyId=$assemblyId";
$json = json_GET($uri_6, 'GET dataset 7 - structural variant');
eq_or_diff($json, $expected_data7, "GA4GH Beacon query - structural variant");

# Testing structural variant with a range of coordinates
my $uri_7 = $get_base_uri . ";referenceName=8;startMin=7803800;startMax=7803900;endMin=7825300;endMax=7825400;variantType=CNV;referenceBases=N;assemblyId=$assemblyId";
$json = json_GET($uri_7, 'GET dataset 7 - structural variant range query');
eq_or_diff($json, $expected_data8, "GA4GH Beacon query - structural variant range query");

# Testing an insertion
my $uri_8 = $get_base_uri . ";referenceName=11;start=6303492;referenceBases=T;alternateBases=GT;assemblyId=$assemblyId";
$json = json_GET($uri_8, 'GET dataset 8 - insertion query');
eq_or_diff($json, $expected_data9, "GA4GH Beacon query - insertion query");

done_testing();
