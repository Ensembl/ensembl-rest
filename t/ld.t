# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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

use Bio::EnsEMBL::Test::TestUtils;
use Catalyst::Test();

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');
my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('multi');
Catalyst::Test->import('EnsEMBL::REST');

my $ld_get = '/ld/homo_sapiens/rs10757279?content-type=application/json;population_name=1000GENOMES:phase_1_ASW';

my $expected_data =
[
  {
    variation1 => "rs1042779",
    variation2 => "rs2240919",
    r2 => "0.903845",
    d_prime => "0.974422"
  },
  {
    variation1 => "rs1042779",
    variation2 => "rs2286799",
    r2 => "0.088461",
    d_prime => "0.999983"
  },
]; 

my $json = json_GET($ld_get, 'GET LD data for variant and population');

print $json, "\n";

done_testing();
