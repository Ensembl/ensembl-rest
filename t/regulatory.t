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
    ID              => 'ENSR00000105157',                   
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

done_testing();



