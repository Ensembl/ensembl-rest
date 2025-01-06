# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
# Copyright [2016-2025] EMBL-European Bioinformatics Institute
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
use Bio::EnsEMBL::Funcgen::BindingMatrix::Constants qw ( :all );

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');
Catalyst::Test->import('EnsEMBL::REST');

my $output;
my $json;

my $binding_matrix =
'/species/homo_sapiens/binding_matrix/ENSPFM0001/?content-type=application/json';
$output = {
    "source"    => "SELEX",
    "stable_id" => "ENSPFM0001",
    "associated_transcription_factor_complexes" =>
      [ "IRF8", "IRF9", "IRF5", "IRF4" ],
    "elements" => {
        "1"  => { "A" => 10448, "T" => 13901, "C" => 18876, "G" => 2105 },
        "2"  => { "A" => 364,   "T" => 5937,  "C" => 45331, "G" => 87 },
        "3"  => { "A" => 350,   "T" => 31,    "C" => 66,    "G" => 45331 },
        "4"  => { "A" => 45331, "T" => 112,   "C" => 124,   "G" => 91 },
        "5"  => { "A" => 45331, "T" => 444,   "C" => 8,     "G" => 25 },
        "6"  => { "A" => 45331, "T" => 8,     "C" => 6,     "G" => 4 },
        "7"  => { "A" => 187,   "T" => 497,   "C" => 45331, "G" => 593 },
        "8"  => { "A" => 27,    "T" => 3801,  "C" => 45331, "G" => 4 },
        "9"  => { "A" => 57,    "T" => 3,     "C" => 6,     "G" => 45331 },
        "10" => { "A" => 45331, "T" => 5,     "C" => 46,    "G" => 7 },
        "11" => { "A" => 45331, "T" => 1002,  "C" => 11,    "G" => 23 },
        "12" => { "A" => 45331, "T" => 13,    "C" => 15,    "G" => 4 },
        "13" => { "A" => 829,   "T" => 80,    "C" => 45331, "G" => 4251 },
        "14" => { "A" => 1377,  "T" => 27742, "C" => 17589, "G" => 253 },
        "15" => { "A" => 25202, "T" => 9846,  "C" => 4640,  "G" => 5644 },
    },
    "threshold"       => 4.4,
    "name"            => "IRF4_AD_TCAAGG20NCG_NCGAAACCGAAACYN_m1_c3_Cell2013",
    "max_position_sum" => 51719,
    "length"          => 15,
    "unit"            => "Frequencies",
    "elements_string" => "10448\t364\t350\t45331\t45331\t45331\t187\t27\t57\t45331\t45331\t45331\t829\t1377\t25202\t\n"
                         . "18876\t45331\t66\t124\t8\t6\t45331\t45331\t6\t46\t11\t15\t45331\t17589\t4640\t\n"
                         . "2105\t87\t45331\t91\t25\t4\t593\t4\t45331\t7\t23\t4\t4251\t253\t5644\t\n"
                         . "13901\t5937\t31\t112\t444\t8\t497\t3801\t3\t5\t1002\t13\t80\t27742\t9846\t\n"

};

$json = json_GET( $binding_matrix,
    'GET specific Binding Matrix with Frequencies units' );
eq_or_diff( $json, $output,
    'GET specific Binding Matrix with Frequencies units' );

my $binding_matrix_probabilities = $binding_matrix . ';unit=probabilities';
$json= json_GET( $binding_matrix_probabilities,
               'GET specific Binding Matrix with Probabilities units' );
is($json->{unit}, PROBABILITIES,
   'GET specific Binding Matrix with Probabilities units');

my $binding_matrix_bits = $binding_matrix . ';unit=bits';
$json= json_GET( $binding_matrix_bits,
                 'GET specific Binding Matrix with Bits units' );
is($json->{unit}, BITS, 'GET specific Binding Matrix with Bits units');

my $binding_matrix_weights = $binding_matrix . ';unit=weights';
$json= json_GET( $binding_matrix_weights,
                 'GET specific Binding Matrix with Weights units' );
is($json->{unit}, WEIGHTS, 'GET specific Binding Matrix with Weights units');

done_testing();
