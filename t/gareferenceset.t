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
use Data::Dumper;

Catalyst::Test->import('EnsEMBL::REST');

my $base = '/ga4gh/referencesets/search';

## search by md5
my $post_data1  = '{ "md5checksum":"3812377a7767211e8f30e096f1615583", "accession":"", "assemblyId":"", "pageSize":"", "pageToken":""  }';   

## search by accession
my $post_data2  = '{ "md5checksum":"", "accession":"GCA_000001405.14", "assemblyId":"", "pageSize":"", "pageToken":""  }';

## search by assembly id
my $post_data3  = '{ "md5checksum":"", "accession":"", "assemblyId":"GRCh37.p13", "pageSize":"", "pageToken":""  }';

## no filter
my $post_data4  = '{ "md5checksum":"", "accession":"", "assemblyId":"", "pageSize":"", "pageToken":""  }';

## should all return the same assembly
my $expected_data =  { 
  referenceSets => [
     {
      sourceURI => undef,
      name => 'GRCh37',
      sourceAccessions => [
        'GCA_000001405.14'
      ],
      description => 'Homo sapiens GRCh37.p13',
      md5checksum => '3812377a7767211e8f30e096f1615583',
      ncbiTaxonId => '9606',
      isDerived => 'true',
      id => 'GRCh37.p13',
      assemblyId => 'GRCh37.p13'
    }
  ],
  nextPageToken => undef
};

my $json1 = json_POST($base, $post_data1, 'referenceset by md5checksum');
eq_or_diff($json1, $expected_data, "Checking the result from the GA4GH referenceset endpoint by md5checksum");

my $json2 = json_POST($base, $post_data2, 'referenceset by accession');
eq_or_diff($json2, $expected_data, "Checking the result from the GA4GH referenceset endpoint by accession");

my $json3 = json_POST($base, $post_data3, 'referenceset by assemblyId');
eq_or_diff($json3, $expected_data, "Checking the result from the GA4GH referenceset endpoint by assemblyId");

my $json4 = json_POST($base, $post_data4, 'referenceset; no filter ');
eq_or_diff($json4, $expected_data, "Checking the result from the GA4GH referenceset endpoint with no filter ");


## GET

$base =~ s/\/search//;
my $id = 'GRCh37.p13';
my $json_get = json_GET("$base/$id", 'get referenceset');

my $expected_get_data =  { 
      sourceURI => undef,
      name => 'GRCh37',
      sourceAccessions => [
        'GCA_000001405.14'
      ],
      description => 'Homo sapiens GRCh37.p13',
      md5checksum => '3812377a7767211e8f30e096f1615583',
      ncbiTaxonId => '9606',
      isDerived => 'true',
      id => 'GRCh37.p13',
      assemblyId => 'GRCh37.p13'
} ; 

eq_or_diff($json_get, $expected_get_data, "Checking the get result from the referenceset endpoint");


done_testing();
