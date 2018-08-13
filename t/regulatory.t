# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
# Copyright [2016-2018] EMBL-European Bioinformatics Institute
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
    description   => 'REMC Epigenome (Class2) for Lung',
    display_label => 'Lung',                                         
    efo_accession => undef,                                          
    gender        => 'female',                                              
    name          => 'Lung' 
  },
];
$json = json_GET($epigenomes_all,'GET list of all epigenomes');
eq_or_diff($json, $output, 'GET list of all epigenomes');


my $regulatory_feature = '/regulatory/species/homo_sapiens/id/ENSR00000105157/?content-type=application/json';
  $output = [{
    id              => 'ENSR00000105157',                   
    bound_end       => 76430144,                     
    bound_start     => 76429380,                   
    description     => 'Open chromatin region',
    end             => 76430144,                           
    feature_type    => 'Open chromatin',              
    seq_region_name => 1,                      
    source          => 'Regulatory_Build',              
    start           => 76429380,                         
    strand          => 0 

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
  microarray => 'HC-G110',
  length    => 25,
  name      => '137:179;',
  sequence        => 'TCTCCTTTGCTGAGGCCTCCAGCTT'
  } ;
$json = json_GET($microarray_probe,'GET Information about a specific probe');
eq_or_diff($json, $output, 'GET Information about a specific probe');


# regulatory/species/:species/microarray/:microarray/probe_set/:probe_set
my $microarray_probe_set = '/regulatory/species/homo_sapiens/microarray/HC-G110/probe_set/1000_at?content-type=application/json';
$output =  {
  microarray => 'HC-G110',
  name => '1000_at',          
  probes => [                         
    '137:179;'                        
    ],                                  
  size => 16                          
  } ;
$json = json_GET($microarray_probe_set,'JSON: GET Information about a specific probe_set');
eq_or_diff($json, $output, 'GET Information about a specific probes_set');

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
    "max_element"     => 45331,
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

done_testing();
