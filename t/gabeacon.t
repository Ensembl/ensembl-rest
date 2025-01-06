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
my $beaconId = "org.ensembl.rest.grch37";
my $datasetId = "Ensembl ". $schema_version;
my $beacon_version = "v2.0.0";
my $externalURL = "https://grch37.ensembl.org/Homo_sapiens/Variation/Explore?v=";
my $externalURL_2 = "https://grch37.ensembl.org/Homo_sapiens/StructuralVariation/Explore?sv=";
my $dataset_response;

# To check error handling for assembly differnent to DB
my $unavailable_assembly = "GRCh38";

# Test GET /ga4gh/beacon
my $beacon_json = json_GET('/ga4gh/beacon/', 'Get the beacon representation');
is(ref($beacon_json), 'HASH', 'HASH wanted from endpoint');
cmp_ok(keys(%{$beacon_json}), '==', 2, 'Check beacon has correct number of fields');
cmp_ok($beacon_json->{response}->{id}, 'eq', $beaconId, 'Beacon id');
cmp_ok($beacon_json->{meta}->{version}, '==', $schema_version, 'Version');

# Organization is a hash
is(ref($beacon_json->{response}->{organization}), 'HASH', 'Organization should be a hash');
cmp_ok(keys(%{$beacon_json->{response}->{organization}}), '==', 8, 'Check organization has correct number of fields');

# POST checks 
my $json;

### Check invalid parameters ###
# Invalid referenceName
my $post_invalid_refname = '{"referenceName": "CHR7", "start" : 86442403, "referenceBases": "T", "alternateBases": "C",' .
                  '"assemblyId" : "' . $assemblyId . '" }';

my $expected_error_invalid = {
  "errorCode" => 400,
  "errorMessage" => "Invalid referenceName"
};

$json = json_POST( $q_base , $post_invalid_refname, 'POST query invalid referenceName' );
eq_or_diff($json->{error}, $expected_error_invalid, "GA4GH Beacon query invalid referenceName - error");


# Missing alternateBases
# start without end requires alternateBases
my $post_missing_alt = '{"referenceName": "7", "start" : 86442403, "referenceBases": "T",' .
                  '"assemblyId" : "' . $assemblyId . '" }';

my $expected_error_missing_alt = {
  "errorCode" => 400,
  "errorMessage" => "Missing mandatory parameter alternateBases"
};

$json = json_POST( $q_base , $post_missing_alt, 'POST query missing alternateBases' );
eq_or_diff($json->{error}, $expected_error_missing_alt, "GA4GH Beacon query missing alternateBases - error");


# Invalid referenceBases
my $post_invalid_ref = '{"referenceName": "7", "start" : 86442403, "referenceBases": "T2", "alternateBases": "C",' .
                  '"assemblyId" : "' . $assemblyId . '" }';

my $expected_error_invalid_ref = {
  "errorCode" => 400,
  "errorMessage" => "Invalid referenceBases"
};

$json = json_POST( $q_base , $post_invalid_ref, 'POST query invalid referenceBases' );
eq_or_diff($json->{error}, $expected_error_invalid_ref, "GA4GH Beacon query invalid referenceBases - error");


# Invalid alternateBases
my $post_invalid_alt = '{"referenceName": "7", "start" : 86442403, "referenceBases": "T", "alternateBases": "C2",' .
                  '"assemblyId" : "' . $assemblyId . '" }';

my $expected_error_invalid_alt = {
  "errorCode" => 400,
  "errorMessage" => "Invalid alternateBases"
};

$json = json_POST( $q_base , $post_invalid_alt, 'POST query invalid alternateBases' );
eq_or_diff($json->{error}, $expected_error_invalid_alt, "GA4GH Beacon query invalid alternateBases - error");


# Invalid variantType
my $post_invalid_sv = '{"referenceName": "7", "start" : 86442403, "referenceBases": "N", "variantType": "SNP",' .
                  '"end" : 86442603, "assemblyId" : "' . $assemblyId . '" }';

my $expected_error_invalid_sv = {
  "errorCode" => 400,
  "errorMessage" => "Invalid variantType"
};

$json = json_POST( $q_base , $post_invalid_sv, 'POST query invalid variantType' );
eq_or_diff($json->{error}, $expected_error_invalid_sv, "GA4GH Beacon query invalid variantType - error");


# Invalid datasetId
my $post_invalid_dataset = '{"referenceName": "7", "start" : 86442403, "referenceBases": "T", "alternateBases": "C",' .
                  '"assemblyId" : "' . $assemblyId . '", "datasetIds" : "clinic_var" }';

my $expected_error_invalid_dataset = {
  "errorCode" => 400,
  "errorMessage" => "Invalid datasetId 'clinic_var'"
};

$json = json_POST( $q_base , $post_invalid_dataset, 'POST query invalid datasetId' );
eq_or_diff($json->{error}, $expected_error_invalid_dataset, "GA4GH Beacon query invalid datasetId - error");

######

# Expected responses
my $expected_response_sum_1 = {
  "numTotalResults" => 20,
  "exists" => JSON::true
};

my $expected_response_sum_2 = {
  "numTotalResults" => 1,
  "exists" => JSON::false
};

my $expected_response_sum_3 = {
  "numTotalResults" => 0,
  "exists" => JSON::false
};

my $expected_response_sum_4 = {
  "numTotalResults" => 1,
  "exists" => JSON::true
};

my $expected_response_sum_5 = {
  "numTotalResults" => 0,
  "exists" => JSON::true
};

my $expected_response_sum_6 = {
    "numTotalResults" => 3,
    "exists" => JSON::true
};

my $expected_response_sum_7 = {
    "numTotalResults" => 45,
    "exists" => JSON::false
};

my $expected_response_sum_8 = {
    "numTotalResults" => 2,
    "exists" => JSON::true
};

my $expected_response_sum_9 = {
    "numTotalResults" => 4,
    "exists" => JSON::true
};

### Range query ###
# Testing SNP/indels falling within the range
my $post_snv_range = '{"referenceName": "X", "start" : 215800, "referenceBases": "C", "end" : 215950,' .
                  '"assemblyId" : "' . $assemblyId . '", "datasetIds" : "dbsnp"}';

$json = json_POST( $q_base , $post_snv_range, 'POST query SNV within range' );
cmp_ok(@{$json->{response}->{resultSets}[0]->{results}}, '==', 4, 'GA4GH Beacon query SNV within range - response resultSets count');


# Testing for a variant that exists at a given location
# includeResultsetResponses = default (HIT)
my $post_data1 = '{"referenceName": "7", "start" : 86442403, "referenceBases": "T", "alternateBases": "C",' .
                  '"assemblyId" : "' . $assemblyId . '" }'; 

my $expected_meta_receive_req_sum = {
  "apiVersion" => $beacon_version,
  "includeResultsetResponses" => "HIT",
  "pagination" => { "limit" => 0, "skip" => 0 },
  "requestedGranularity" => "record",
  "requestedSchemas" => [ { "entityType" => "genomicVariant", "schema" => "" } ]
};

my $expected_meta_1 = {
  "apiVersion" => $beacon_version,
  "beaconId" => $beaconId,
  "createDateTime" => undef,
  "includeResultsetResponses" => "HIT",
  "receivedRequestSummary" => $expected_meta_receive_req_sum,
  "returnedSchemas" => [ { "entityType" => "genomicVariant", "schema" => "" } ],
  "testMode" => JSON::false,
  "updateDateTime" => undef
};

$json = json_POST( $q_base , $post_data1, 'POST query SNV' );
eq_or_diff($json->{responseSummary}, $expected_response_sum_1, "GA4GH Beacon query SNV - responseSummary");
eq_or_diff($json->{meta}, $expected_meta_1, "GA4GH Beacon query SNV - response meta");
cmp_ok(@{$json->{response}->{resultSets}}, '==', 20, 'GA4GH Beacon query SNV - response resultSets count');

# Found variant with requested includeResultsetResponses HIT + dataset ids
my $post_data1_ds = '{"referenceName": "7", "start" : 86442403, "referenceBases": "T", "alternateBases": "C",' .
                  '"assemblyId" : "' . $assemblyId . '", "includeResultsetResponses" : "HIT", "datasetIds" : "hapmap_ceu,clin_assoc"}';

my $expected_meta_receive_req_sum_dt = {
  "apiVersion" => $beacon_version,
  "includeResultsetResponses" => "HIT",
  "pagination" => { "limit" => 0, "skip" => 0 },
  "requestedGranularity" => "record",
  "requestedSchemas" => [ { "entityType" => "genomicVariant", "schema" => "" } ],
  "datasetIds" => ["hapmap_ceu", "clin_assoc"]
};

$json = json_POST( $q_base , $post_data1_ds, 'POST query SNV - dataset response HIT' );
eq_or_diff($json->{responseSummary}, $expected_response_sum_4, "GA4GH Beacon query SNV with datasets - responseSummary");
eq_or_diff($json->{meta}->{receivedRequestSummary}, $expected_meta_receive_req_sum_dt, "GA4GH Beacon query SNV with datasets - response meta");
cmp_ok(@{$json->{response}->{resultSets}}, '==', 1, 'GA4GH Beacon query SNV with datasets - response resultSets count');

# Found variant with includeResultsetResponses HIT and dataset dbSNP
my $post_data_dbsnp_ds = '{"referenceName": "7", "start" : 86442403, "referenceBases": "T", "alternateBases": "C",' .
                  '"assemblyId" : "' . $assemblyId . '", "includeResultsetResponses" : "HIT", "datasetIds" : "dbsnp"}';

my $expected_data_dbsnp_ds = {
  "id" => "dbsnp",
  "exists" => JSON::true,
  "externalUrl" => [ $externalURL . "rs2299222" ],
  "info" => { "counts" => { "callCount" => 1, "sampleCount" => undef } },
  "results" => [ { "variantInternalId" => "rs2299222",
                   "variation" => {
                     "alternateBases" => "C",
                     "location" => {
                       "interval" => {
                         "end" => {
                           "type" => "Number",
                           "value" => 86442404
                         },
                         "start" => {
                           "type" => "Number",
                           "value" => 86442403
                         },
                         "type" => "SequenceInterval"
                       },
                       "sequence_id" => "7",
                       "type" => "SequenceLocation"
                     },
                     "referenceBases" => "T",
                     "variantType" => "SNP"
                   },
                   "identifiers" => [ "dbSNP:rs2299222" ],
                   "MolecularAttributes" => {
                     "molecularEffects" => [ { "id" => "SO:0001627", "label" => "intron_variant" } ]
                   },
                   "variantLevelData" => {
                     "clinicalInterpretations" => [ { "conditionId" => "ACHONDROPLASIA", "effect" => { "id" => "Orphanet:15", "label" => "ACHONDROPLASIA" } } ]
                   }
                 } ],
  "resultsCount" => 1,
  "setType" => "dataset"
};

$json = json_POST( $q_base , $post_data_dbsnp_ds, 'POST query SNV - dataset response HIT dbSNP' );
eq_or_diff($json->{response}->{resultSets}, [$expected_data_dbsnp_ds], "GA4GH Beacon query SNV dataset dbSNP - response");

# Found variant with includeResultsetResponses MISS
my $post_data3_ds = '{"referenceName": "7", "start" : 86442403, "referenceBases": "T", "alternateBases": "C",' .
                  '"assemblyId" : "' . $assemblyId . '", "includeResultsetResponses" : "MISS", "datasetIds" : "hapmap_ceu,clin_assoc"}';

my $dataset_response_miss = {
   "id" => 'clin_assoc',
   "exists" => JSON::false,
   "info" => {
     "counts" => {
       "callCount" => undef,
       "sampleCount" => undef
     }
   },
   "results" => undef,
   "resultsCount" => undef,
   "setType" => "dataset"
};

$json = json_POST( $q_base , $post_data3_ds, 'POST query SNV - dataset response MISS' );
eq_or_diff($json->{response}->{resultSets}, [$dataset_response_miss], "GA4GH Beacon query SNV dataset MISS - response");
eq_or_diff($json->{responseSummary}, $expected_response_sum_4, "GA4GH Beacon query SNV dataset MISS - responseSummary");

# Not found variant with dataset and includeResultsetResponses ALL
my $post_data4_ds = '{"referenceName": "7", "start" : 86442403, "referenceBases": "T", "alternateBases": "C",' .
                  '"assemblyId" : "' . $assemblyId . '", "includeResultsetResponses" : "ALL", "datasetIds" : "clin_assoc"}';

my $expected_data4_ds = {
  "id" => "clin_assoc",
  "exists" => JSON::false,
  "info" => {
    "counts" => {
      "callCount" => undef,
      "sampleCount" => undef
    }
  },
  "results" => undef,
  "resultsCount" => undef,
  "setType" => "dataset"
};

$json = json_POST( $q_base , $post_data4_ds, 'POST query SNV - dataset response ALL' );
eq_or_diff($json->{response}->{resultSets}, [$expected_data4_ds], "GA4GH Beacon query SNV dataset ALL - response");
eq_or_diff($json->{responseSummary}, $expected_response_sum_2, "GA4GH Beacon query SNV dataset ALL - responseSummary");

# Found variant with includeResultsetResponses NONE
my $post_data5_ds = '{"referenceName": "7", "start" : 86442403, "referenceBases": "T", "alternateBases": "C",' .
                  '"assemblyId" : "' . $assemblyId . '", "includeResultsetResponses":"NONE"}'; 

$json = json_POST( $q_base , $post_data5_ds, 'POST query SNV - dataset response NONE' );
eq_or_diff($json->{response}->{resultSets}, undef, "GA4GH Beacon query SNV dataset NONE - response");
eq_or_diff($json->{responseSummary}, $expected_response_sum_5, "GA4GH Beacon query SNV dataset NONE - responseSummary");


# Found variant with includeDataSetResponse empty
my $post_data6_ds = '{"referenceName": "7", "start" : 86442403, "referenceBases": "T", "alternateBases": "C",' .
                  '"assemblyId" : "' . $assemblyId . '", "includeResultsetResponses":""}'; 

my $expected_error_message = {
  "errorCode" => 400,
  "errorMessage" => "Invalid includeResultsetResponses"
};

$json = json_POST( $q_base , $post_data6_ds, 'POST query SNV empty includeResultsetResponses' );
eq_or_diff($json->{error}, $expected_error_message, "GA4GH Beacon query SNV empty includeResultsetResponses - error");


# Testing for a variant that exists at a given location not found
my $post_data7_ds = '{"referenceName": "7", "start" : 86442403, "referenceBases": "C", "alternateBases": "T",' . 
                 '"assemblyId" : "' . $assemblyId . '" }';

$json = json_POST( $q_base , $post_data7_ds, 'POST query SNV - not found' );
eq_or_diff($json->{responseSummary}, $expected_response_sum_3, "GA4GH Beacon query SNV not found - responseSummary");
# TODO: test response -> resultSets

# Test with includeResultsetResponses without dataset ids
my $post_data2_ds = '{"referenceName": "7", "start" : 86442403, "referenceBases": "C", "alternateBases": "T",' .
                  '"assemblyId" : "' . $assemblyId . '", "includeResultsetResponses" : "ALL"}'; 

$json = json_POST( $q_base , $post_data2_ds, 'POST query SNV ALL datasets' );
cmp_ok(@{$json->{response}->{resultSets}}, '==', 45, 'GA4GH Beacon query SNV ALL datasets - response resultSets count');

# Testing for an unavailable assembly
my $post_data4 = '{"referenceName": "7", "start" : 86442405, "referenceBases": "T", "alternateBases": "C",' . 
                   '"assemblyId" : "' . $unavailable_assembly . '" }';

my $expected_error_message_2 = {
  "errorCode" => 400,
  "errorMessage" => "User provided assemblyId ($unavailable_assembly) does not match with dataset assembly ($assemblyId)"
};

$json = json_POST($q_base, $post_data4, 'POST query SNV - assembly not available' );
eq_or_diff($json->{error}, $expected_error_message_2, "GA4GH Beacon query SNV - assembly not available error");
eq_or_diff($json->{response}->{resultSets}, undef, "GA4GH Beacon query SNV - assembly not available response");

# Testing for missing parameter 
my $post_data5 = '{"referenceNamex": "7", "start" : 86442403, "referenceBases": "T", "alternateBases": "C",' .
                   '"assemblyId" : "' . $assemblyId . '" }';

my $expected_error_message_3 = {
  "errorCode" => 400,
  "errorMessage" => "Missing mandatory parameter referenceName"
};

$json = json_POST($q_base, $post_data5, 'POST query SNV - missing parameter' );
eq_or_diff($json->{error}, $expected_error_message_3, "GA4GH Beacon query SNV - missing parameter error");

# Testing invalid parameter
my $post_data6 = '{"referenceName": "7", "start" : 86442403, "variantType" : "SNV", "referenceBases": "T", "alternateBases": "C",' .
                   '"assemblyId" : "' . $assemblyId . '" }';

my $expected_error_message_4 = {
  "errorCode" => 400,
  "errorMessage" => "Invalid parameter variantType"
};

$json = json_POST( $q_base , $post_data6, 'POST query SNV - invalid parameter' );
eq_or_diff($json->{error}, $expected_error_message_4, "GA4GH Beacon query SNV - invalid parameter error");

# Testing CNV 
my $post_data7 = '{"referenceName": "8", "start" : 7803890, "end" : 7825339, "variantType" : "CNV", "referenceBases": "N", ' .
                   '"assemblyId" : "' . $assemblyId . '" }';

$json = json_POST( $q_base , $post_data7, 'POST query CNV' );
eq_or_diff($json->{responseSummary}, $expected_response_sum_6, "GA4GH Beacon query CNV - responseSummary");
cmp_ok(@{$json->{response}->{resultSets}}, '==', 3, 'GA4GH Beacon query CNV - response resultSets count');


### GET checks ###
# GET and POST return the same data
my $get_content = 'content-type=application/json';
my $get_base_uri = $q_base . '?' . $get_content;
my $uri;

# Check for missing parameters
$uri = $get_base_uri . ";referenceNamex=7;start=86442403;referenceBases=T;alternateBases=C;assemblyId=$assemblyId";
$json = json_GET($uri, 'GET query SNV - missing parameter');
eq_or_diff($json->{error}, $expected_error_message_3, "GA4GH Beacon query SNV - missing parameter");

# Example GET ga4gh/beacon/query?content-type=application/json;referenceBases=A;alternateBases=G;assemblyId=GRCh37;referenceName=15;start=20538669
# Testing for a variant that exists at a given location
my $uri_1 = $get_base_uri . ";referenceName=7;start=86442403;referenceBases=T;alternateBases=C;assemblyId=$assemblyId";
$json = json_GET($uri_1, 'GET query SNV');
eq_or_diff($json->{responseSummary}, $expected_response_sum_1, "GA4GH Beacon query SNV - responseSummary");
eq_or_diff($json->{meta}, $expected_meta_1, "GA4GH Beacon query SNV - response meta");
cmp_ok(@{$json->{response}->{resultSets}}, '==', 20, 'GA4GH Beacon query SNV - response resultSets count');

# Testing with an includeResultsetResponses HIT
my $uri_ds_1 = $get_base_uri . ";referenceName=7;start=86442403;referenceBases=T;alternateBases=C;assemblyId=$assemblyId;includeResultsetResponses=HIT;datasetIds=hapmap_ceu,clin_assoc";
$json = json_GET($uri_ds_1, 'GET query SNV - entry with dataset response');
eq_or_diff($json->{responseSummary}, $expected_response_sum_4, "GA4GH Beacon query SNV with datasets - responseSummary");
eq_or_diff($json->{meta}->{receivedRequestSummary}, $expected_meta_receive_req_sum_dt, "GA4GH Beacon query SNV with datasets - response meta");
cmp_ok(@{$json->{response}->{resultSets}}, '==', 1, 'GA4GH Beacon query SNV with datasets - response resultSets count');

# Testing for a variant that exists at a given location not found
my $uri_2 = $get_base_uri . ";referenceName=7;start=86442403;referenceBases=C;alternateBases=T;assemblyId=$assemblyId";
$json = json_GET($uri_2, 'GET query SNV not found');
eq_or_diff($json->{responseSummary}, $expected_response_sum_3, "GA4GH Beacon query SNV not found - responseSummary");
# TODO: test response -> resultSets

# Testing with an includeResultsetResponses ALL and dataset ids
my $uri_ds_2 = $get_base_uri . ";referenceName=7;start=86442403;referenceBases=C;alternateBases=T;assemblyId=$assemblyId;includeResultsetResponses=ALL;datasetIds=hapmap_jpt";
$json = json_GET($uri_ds_2, 'GET query SNV ALL datasets');
cmp_ok(@{$json->{response}->{resultSets}}, '==', 1, 'GA4GH Beacon query SNV ALL dataset clin_assoc - response resultSets count');
eq_or_diff($json->{responseSummary}, $expected_response_sum_2, "GA4GH Beacon query SNV ALL dataset clin_assoc - responseSummary");

# Testing with an includeResultsetResponses ALL
my $uri_ds_3 = $get_base_uri . ";referenceName=7;start=86442403;referenceBases=C;alternateBases=T;assemblyId=$assemblyId;includeResultsetResponses=ALL";
$json = json_GET($uri_ds_3, 'GET query SNV ALL datasets');
cmp_ok(@{$json->{response}->{resultSets}}, '==', 45, 'GA4GH Beacon query SNV ALL datasets - response resultSets count');
eq_or_diff($json->{responseSummary}, $expected_response_sum_7, "GA4GH Beacon query SNV ALL datasets - responseSummary");

# Testing with an includeResultsetResponses MISS and dataset ids
my $uri_ds_4 = $get_base_uri . ";referenceName=7;start=86442403;referenceBases=T;alternateBases=C;assemblyId=$assemblyId;includeResultsetResponses=MISS;datasetIds=hapmap_ceu,clin_assoc";
$json = json_GET($uri_ds_4, 'GET query SNV dataset MISS');
eq_or_diff($json->{response}->{resultSets}, [$dataset_response_miss], "GA4GH Beacon query SNV dataset MISS - response");
eq_or_diff($json->{responseSummary}, $expected_response_sum_4, "GA4GH Beacon query SNV dataset MISS - responseSummary");

# Testing using an assembly that does not match DB assembly
my $uri_5 = $get_base_uri . ";referenceName=7;start=86442405;referenceBases=T;alternateBases=C;assemblyId=$unavailable_assembly";
$json = json_GET($uri_5, 'GET query SNV - unavailable assembly');
eq_or_diff($json->{error}, $expected_error_message_2, "GA4GH Beacon query SNV - assembly not available error");
eq_or_diff($json->{response}->{resultSets}, undef, "GA4GH Beacon query SNV - assembly not available response");

# Testing invalid parameter - SNV
my $uri_6 = $get_base_uri . ";referenceName=7;start=86442403;variantType=SNV;referenceBases=T;alternateBases=C;assemblyId=$assemblyId";
$json = json_GET($uri_6, 'GET query SNV - invalid parameter');
eq_or_diff($json->{error}, $expected_error_message_4, "GA4GH Beacon query SNV - invalid parameter error");

# Testing structural variant with precise coordinates
my $uri_7 = $get_base_uri . ";referenceName=8;start=7803890;end=7825339;variantType=CNV;referenceBases=N;assemblyId=$assemblyId";
$json = json_GET($uri_7, 'GET query CNV - structural variant');
eq_or_diff($json->{responseSummary}, $expected_response_sum_6, "GA4GH Beacon query CNV - responseSummary");
cmp_ok(@{$json->{response}->{resultSets}}, '==', 3, 'GA4GH Beacon query CNV - response resultSets count');

# Testing structural variant with a range of coordinates
my $uri_8 = $get_base_uri . ";referenceName=8;start=7803800,7803900;end=7825300,7825400;variantType=CNV;referenceBases=N;assemblyId=$assemblyId";
$json = json_GET($uri_8, 'GET query CNV - bracket query');
eq_or_diff($json->{responseSummary}, $expected_response_sum_9, "GA4GH Beacon query CNV - bracket query");

# Testing a small insertion - SNV
my $uri_9 = $get_base_uri . ";referenceName=11;start=6303492;referenceBases=T;alternateBases=GT;assemblyId=$assemblyId";
$json = json_GET($uri_9, 'GET query insertion');
eq_or_diff($json->{responseSummary}, $expected_response_sum_8, "GA4GH Beacon query insertion");

# Testing different CNVs in datasets
# There's two variants in this region but only one in dataset '1kg_eur_com'
# Dataset Response should only report one variant
my $expected_data_cnv = {
  "id" => "1kg_eur_com",
  "exists" => JSON::true,
  "externalUrl" => [ $externalURL_2 . "esv93078" ],
  "info" => { "counts" => { "callCount" => 1, "sampleCount" => undef } },
  "results" => [ { "variantInternalId" => "esv93078",
                   "variation" => {
                     "location" => {
                       "interval" => {
                         "end" => {
                           "type" => "Number",
                           "value" => 7825340
                         },
                         "start" => {
                           "type" => "Number",
                           "value" => 7803890
                         },
                         "type" => "SequenceInterval"
                       },
                       "sequence_id" => "8",
                       "type" => "SequenceLocation"
                     },
                     "variantType" => "copy_number_variation"
                   },
                   "MolecularAttributes" => {
                     "molecularEffects" => [ { "id" => "SO:0001628", "label" => "intergenic_variant" } ]
                   },
                   "variantLevelData" => {
                     "clinicalInterpretations" => [ { "conditionId" => "ACHONDROPLASIA", "effect" => { "id" => "Orphanet:15", "label" => "ACHONDROPLASIA" } } ]
                   }
                 } ],
  "resultsCount" => 1,
  "setType" => "dataset"
};

my $uri_ds_cnv = $get_base_uri . ";referenceName=8;start=7803800,7806000;end=7823400,7825400;variantType=CNV;referenceBases=N;assemblyId=$assemblyId;includeResultsetResponses=HIT;datasetIds=1kg_eur_com";
$json = json_GET($uri_ds_cnv, 'GET query CNV HIT dataset');
eq_or_diff($json->{responseSummary}, $expected_response_sum_4, "GA4GH Beacon query CNV HIT dataset - responseSummary");
eq_or_diff($json->{response}->{resultSets}, [$expected_data_cnv], "GA4GH Beacon query CNV HIT dataset - response");

# Query datasets DGVa and dbVar
# Testing structural variant with a range of coordinates
my $query_sv = $get_base_uri . ";referenceName=8;start=7803800,7803900;end=7825300,7825400;variantType=CNV;referenceBases=N;assemblyId=$assemblyId;datasetIds=dgva,dbvar";
$json = json_GET($query_sv, 'GET query datasets DGVa and dbVar - bracket query');
eq_or_diff($json->{responseSummary}, $expected_response_sum_8, "GA4GH Beacon query datasets DGVa and dbVar - bracket query");

done_testing();
