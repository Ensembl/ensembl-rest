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


Catalyst::Test->import('EnsEMBL::REST');

my $base = '/ga4gh/datasets/search';

my $post_data1 = '{ "pageSize": 1 }';
my $post_data2 = '{ "pageSize": 1, "pageToken":"e06d8b736a50aaf1460f7640dce12012" }';

my $expected_data2 = {datasets => [ { id => 'e06d8b736a50aaf1460f7640dce12012', 
                                      description => '1000 Genomes phase1 genotypes',
                                      name => '1000 Genomes phase1'
                                    }], nextPageToken => undef}; 

my $expected_data1 = {datasets => [ { id => 'Ensembl',
                                      description => 'Ensembl annotation',
                                      name => 'Ensembl'
                                     }], nextPageToken => 'c7d2c4a0e0dcb28bdb30559f16c7819d'};


my $json1 = json_POST( $base , $post_data1, 'dataset - 1 entry' );
eq_or_diff($json1, $expected_data1, "Checking the result from the ga4gh dataset endpoint");

my $json2 = json_POST($base  , $post_data2, 'dataset with pageToken');
eq_or_diff($json2, $expected_data2, "Checking the result from the ga4gh dataset endpoint with page token");
  


### check get

$base =~ s/\/search//;
my $id = 'e06d8b736a50aaf1460f7640dce12012';
my $expected_data3 = { id => 'e06d8b736a50aaf1460f7640dce12012', 
                       description => '1000 Genomes phase1 genotypes',
                       name => '1000 Genomes phase1'};

my $json3 = json_GET("$base/$id", 'get dataset');
eq_or_diff($json3, $expected_data3, "Checking the get result from the dataset endpoint");


done_testing();

