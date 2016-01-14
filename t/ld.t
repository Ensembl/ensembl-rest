# Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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
use Bio::EnsEMBL::Test::MultiTestDB;
use Data::Dumper;
use Bio::EnsEMBL::Test::TestUtils;
use Catalyst::Test();

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');
my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('multi');
Catalyst::Test->import('EnsEMBL::REST');

my ($ld_get, $json, $expected_output);

$expected_output =
[
  {
    'variation1' => 'rs1333047',
    'population_name' => '1000GENOMES:phase_1_ASW',
    'r2' => '1.000000',
    'variation2' => 'rs4977575',
    'd_prime' => '1.000000'
  },
  {
    'variation1' => 'rs1333047',
    'population_name' => '1000GENOMES:phase_1_ASW',
    'r2' => '0.050071',
    'variation2' => 'rs1333049',
    'd_prime' => '0.999871'
  },
  {
    'variation1' => 'rs1333047',
    'population_name' => '1000GENOMES:phase_1_ASW',
    'r2' => '0.063754',
    'variation2' => 'rs72655407',
    'd_prime' => '0.999996'
  }
];

$ld_get = '/ld/homo_sapiens/rs1333047';
$json = json_GET($ld_get, 'GET LD data for variant');
eq_or_diff($json, $expected_output, "Example variant");

$ld_get = '/ld/homo_sapiens/rs1333047?population_name=1000GENOMES:phase_1_ASW';
$json = json_GET($ld_get, 'GET LD data for variant and population');
eq_or_diff($json, $expected_output, "Example variant and population");

$expected_output =
[
  {
    'variation1' => 'rs1333047',
    'population_name' => '1000GENOMES:phase_1_ASW',
    'r2' => '1.000000',
    'variation2' => 'rs4977575',
    'd_prime' => '1.000000'
  },
];

$ld_get = '/ld/homo_sapiens/rs1333047?population_name=1000GENOMES:phase_1_ASW;d_prime=1.0';
$json = json_GET($ld_get, 'GET LD data for variant, population and d_prime');
eq_or_diff($json, $expected_output, "Example variant, population and d_prime");

done_testing();
