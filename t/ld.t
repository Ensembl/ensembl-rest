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
use Test::Deep;
use Test::Warnings qw(warning);
use Bio::EnsEMBL::Test::MultiTestDB;
use Data::Dumper;
use Bio::EnsEMBL::Test::TestUtils;
use Catalyst::Test();
use JSON;
my $dba = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');
my $chicken = Bio::EnsEMBL::Test::MultiTestDB->new('gallus_gallus');

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('multi');
Catalyst::Test->import('EnsEMBL::REST');

my ($ld_get, $json, $expected_output);

$expected_output =
[
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
  },
  {
    'variation1' => 'rs1333047',
    'population_name' => '1000GENOMES:phase_1_ASW',
    'r2' => '1.000000',
    'variation2' => 'rs4977575',
    'd_prime' => '1.000000'
  },
];

$ld_get = '/ld/homo_sapiens/rs1333047';
action_bad($ld_get, 'A population name is required for this endpoint. Use GET /info/variation/populations/:species?filter=LD to retrieve a list of all populations with LD data.');

$ld_get = '/ld/homo_sapiens/rs1333047/1000GENOMES:phase_1_ASW';
$json = json_GET($ld_get, 'GET LD data for variant and population');
cmp_bag($json, $expected_output, "Example variant and population");

$expected_output = [
  {
    d_prime => '0.999871',
    population_name => '1000GENOMES:phase_1_ASW',
    r2 => '0.050071',
    chr => 9,
    consequence_type => 'downstream_gene_variant',
    clinical_significance => ['pathogenic','other','protective'],
    end => 22125503,
    start => 22125503,
    strand => 1,
    variation => 'rs1333049'
  },
  {
    d_prime => '0.999996',
    population_name => '1000GENOMES:phase_1_ASW',
    r2 => '0.063754',
    chr => 9,
    consequence_type => 'downstream_gene_variant',
    clinical_significance => [],
    end => 22125032,
    start => 22125032,
    strand => 1,
    variation => 'rs72655407'
  },
  {
    d_prime => '1.000000',
    population_name => '1000GENOMES:phase_1_ASW',
    r2 => '1.000000',
    chr => 9,
    consequence_type => 'downstream_gene_variant',
    clinical_significance => [],
    end => 22124744,
    start => 22124744,
    strand => 1,
    variation => 'rs4977575'
  },
];

$ld_get = '/ld/homo_sapiens/rs1333047/1000GENOMES:phase_1_ASW?attribs=1';
$json = json_GET($ld_get, 'GET LD data for variant and population');
cmp_bag($json, $expected_output, "Example variant, population, return location and consequence attribs");

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

$ld_get = '/ld/homo_sapiens/rs1333047/1000GENOMES:phase_1_ASW?d_prime=1.0';
$json = json_GET($ld_get, 'GET LD data for variant, population and d_prime');
cmp_bag($json, $expected_output, "Example variant, population and d_prime");

$ld_get = '/ld/homo_sapiens/rs1333047/1000GENOMES:phase_1_ASW?d_prime=1.0;window_size=500';
$json = json_GET($ld_get, 'GET LD data for variant, population, d_prime and window_size');
cmp_bag($json, $expected_output, "Example variant, population, d_prime and window_size");

$ld_get = '/ld/homo_sapiens/rs1333047/1000GENOMES:phase_1_ASW?d_prime=1.0;window_size=499.123';
$json = json_GET($ld_get, 'GET LD data for variant, population, d_prime and window_size');
cmp_bag($json, $expected_output, "Example variant, population, d_prime and window_size");

$ld_get = '/ld/homo_sapiens/rs1333047/1000GENOMES:phase_1_ASW?d_prime=1.0;window_size=0';
$json = json_GET($ld_get, 'GET LD data for variant, population, d_prime and window_size');
cmp_bag($json, $expected_output, "Example variant, population, d_prime and window_size");

$ld_get = '/ld/homo_sapiens/rs1333047/1000GENOMES:phase_1_ASW?d_prime=1.0;window_size=500kb';
action_bad($ld_get, 'window_size needs to be a value bewteen 0 and 1000');

$ld_get = '/ld/homo_sapiens/rs1333047/1000GENOMES:phase_1_ASW?d_prime=1.0;window_size=2000';
action_bad($ld_get, 'window_size needs to be a value bewteen 0 and 1000');

$ld_get = '/ld/homo_sapiens/rs1333047/population_name=1000GENOMES:phase_1_ASW?d_prime=1.0;window_size=-2000';
action_bad($ld_get, 'window_size needs to be a value bewteen 0 and 1000');

# tests for ld/:species/region endpoint

$expected_output =
[  
  {  
    'variation1' => 'rs79944118',
    'population_name' => '1000GENOMES:phase_1_ASW',
    'r2' => '0.087731',
    'variation2' => 'rs1333049',
    'd_prime' => '0.999965'
  },
  {  
    'variation1' => 'rs1333048',
    'population_name' => '1000GENOMES:phase_1_ASW',
    'r2' => '0.684916',
    'variation2' => 'rs1333049',
    'd_prime' => '0.999999'
  },
  {  
    'variation1' => 'rs79944118',
    'population_name' => '1000GENOMES:phase_1_ASW',
    'r2' => '0.060082',
    'variation2' => 'rs1333048',
    'd_prime' => '0.999914'
  }
];

my $ld_region_get = '/ld/homo_sapiens/region/9:22125265..22125505/1000GENOMES:phase_1_ASW';
$json = json_GET($ld_region_get, 'GET LD data for region and population');
cmp_bag($json, $expected_output, "Example region, population");

$expected_output =
[  
  {  
    'variation1' => 'rs1333048',
    'population_name' => '1000GENOMES:phase_1_ASW',
    'r2' => '0.684916',
    'variation2' => 'rs1333049',
    'd_prime' => '0.999999'
  },
];

$ld_region_get = '/ld/homo_sapiens/region/9:22125265..22125505/1000GENOMES:phase_1_ASW?r2=0.5';
$json = json_GET($ld_region_get, 'GET LD data for region and population, r2');
cmp_bag($json, $expected_output, "Example region, population, r2");

$ld_region_get = '/ld/homo_sapiens/region/9:22125265..23125505/1000GENOMES:phase_1_ASW?r2=0.5';
action_bad($ld_region_get, 'Specified region is too large');


$ld_region_get = '/ld/homo_sapiens/region/6:28510120..28610120/1000GENOMES:phase_1_ASW?r2=0.5';
action_bad($ld_region_get, 'Specified region overlaps MHC region');
# partially overlaps beginning of MHC region
$ld_region_get = '/ld/homo_sapiens/region/6:28410120..28610120/1000GENOMES:phase_1_ASW?r2=0.5';
action_bad($ld_region_get, 'Specified region overlaps MHC region');
# partially overlaps end of MHC region
$ld_region_get = '/ld/homo_sapiens/region/6:33438354..33458354/1000GENOMES:phase_1_ASW?r2=0.5';
action_bad($ld_region_get, 'Specified region overlaps MHC region');

$expected_output = 
[
  {
    'variation1' => 'rs2394878',
    'population_name' => '1000GENOMES:phase_1_ASW',
    'r2' => '0.055426',
    'variation2' => 'rs9263513',
    'd_prime' => '0.999822'
  },
  {
    'variation1' => 'rs562436031',
    'population_name' => '1000GENOMES:phase_1_ASW',
    'r2' => '0.059741',
    'variation2' => 'rs9263513',
    'd_prime' => '0.999944'
  },
  {
    'variation1' => 'rs2394878',
    'population_name' => '1000GENOMES:phase_1_ASW',
    'r2' => '0.621954',
    'variation2' => 'rs562436031',
    'd_prime' => '0.949649'
  }
];

$ld_region_get = '/ld/homo_sapiens/region/6:31066584..31066717/1000GENOMES:phase_1_ASW';
$json = json_GET($ld_region_get, 'GET LD data in MHC region');
cmp_bag($json, $expected_output, "LD data in MHC region");

$ld_region_get = '/ld/gallus_gallus/region/2:106040050-106040100/1000GENOMES:phase_1_ASW?r2=0.5';
action_bad($ld_region_get, "The species doesn't have a variation database");


# tests for ld/:species/pairwise

$expected_output = 
[
  {
    'variation1' => 'rs1333047',
    'population_name' => '1000GENOMES:phase_1_ASW',
    'r2' => '1.000000',
    'variation2' => 'rs4977575',
    'd_prime' => '1.000000'
  }
];
my $ld_pairwise_get = '/ld/homo_sapiens/pairwise/rs1333047/rs4977575?population_name=1000GENOMES:phase_1_ASW';
$json = json_GET($ld_pairwise_get, 'GET pairwise LD data for a population');
cmp_bag($json, $expected_output, "Example pairwise LD id1, id2, population");

$ld_pairwise_get = '/ld/homo_sapiens/pairwise/rs1333047?population_name=1000GENOMES:phase_1_ASW';
action_bad($ld_pairwise_get, 'Two variant names are required for this endpoint.');

$ld_pairwise_get = '/ld/homo_sapiens/pairwise/rs1333047/rs4977575';
warning { $json = json_GET($ld_pairwise_get, 'GET pairwise LD data for all LD populations') };
cmp_bag($json, $expected_output, "Example pairwise LD id1, id2");

$ld_pairwise_get = '/ld/homo_sapiens/pairwise/rs1333047/rs1234567?population_name=1000GENOMES:phase_1_ASW';
action_bad($ld_pairwise_get, 'Could not fetch variation object for id');

done_testing();
