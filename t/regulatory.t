# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
# Copyright [2016-2017] EMBL-European Bioinformatics Institute
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
use Test::Differences;
use Catalyst::Test ();
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');
Catalyst::Test->import('EnsEMBL::REST');

my $output;
my $json;

my $epigenomes_all = '/regulatory/species/homo_sapiens/epigenome?content-type=application/json';
$output = [
{
  scientific_name => "K562",
  name            => "K562",
  gender          => "female",
  efo_id          => "EFO:0002067",
  },
];
$json = json_GET($epigenomes_all,'GET list of all epigenomes');
eq_or_diff($json, $output, 'GET list of all epigenomes');


my $regulatory_feature = '/regulatory/species/homo_sapiens/id/ENSR00001208657/?content-type=application/json';
  $output = [{
  source          => "Regulatory_Build",
  ID              => "ENSR00001208657",
  feature_type    => "Promoter Flanking Region",
  description     => "Predicted promoter flanking region",
  end             => 1025449,
  seq_region_name => "6",
  strand          => "0",
  bound_start     => 1024250,
  bound_end       => 1025449,
  start           => 1024250

  }];
$json = json_GET($regulatory_feature,'GET specific Regulatory Feature');
eq_or_diff($json, $output, 'GET specific Regulatory Feature');


my $microarray_vendor = '/regulatory/species/homo_sapiens/microarray/HC-G110/vendor/affy/?content-type=application/json';
$output = {
  format => 'EXPRESSION',
  name   => 'HC-G110',
  class  => 'AFFY_UTR',
  type   => 'OLIGO'
};
$json = json_GET($microarray_vendor,'GET Information about a specific microarray');
eq_or_diff($json, $output, 'GET Information about a specific microarray');


my $microarray_probe = '/regulatory/species/homo_sapiens/microarray/HC-G110/probe/137:179;?content-type=application/json';
$output =  {
  microarray_name => 'HC-G110',
  probe_length    => 25,
  probe_name      => '137:179;',
  sequence        => 'TCTCCTTTGCTGAGGCCTCCAGCTT'
  } ;
$json = json_GET($microarray_probe,'GET Information about a specific probe');
eq_or_diff($json, $output, 'GET Information about a specific probe');


done_testing();
