# Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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
use Catalyst::Test ();
use Bio::EnsEMBL::Test::MultiTestDB;

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new();
Catalyst::Test->import('EnsEMBL::REST');

#Assembly mapping
{
  is_json_GET(
    '/map/homo_sapiens/GRCh37/6/GRCh37',
    {"mappings" => [{
      "original" => {
        "seq_region_name" => "6","strand" => 1,
        "coordinate_system" => "chromosome","end" => 171115067,
        "start" => 1,"assembly" => "GRCh37"
      },
      "mapped" => {
        "seq_region_name" => "6","strand" => 1,
        "coordinate_system" => "chromosome","end" => 171115067,
        "start" => 1,"assembly" => "GRCh37"
      }}]},
    'Asserting internal mapping works as expected'
  );
  
  is_json_GET(
    '/map/homo_sapiens/GRCh37/6/NCBI36',
    { mappings => [] },
    'Empty mapping results in no result'
  );
  
  action_bad(
    '/map/homo_sapiens/GRCh37/wibble/NCBI36',
    'Bad region name results in a non-200 response'
  );
  
  action_bad(
    '/map/homo_sapiens/GRCh37/6/NCBI1',
    'Bad coordinate system version results in a non-200 response'
  );
}

my $basic_mapping = { mappings => [
  {
    "seq_region_name"=>"6","gap"=>0,"coord_system"=>"chromosome",
    "strand"=>1,"rank"=>0,"end"=>1101531,"start"=>1101529, "assembly_name" => "GRCh37"
  },
  {
    "seq_region_name"=>"6","gap"=>0,"coord_system"=>"chromosome",
    "strand"=>1,"rank"=>0,"end"=>1102043,"start"=>1102041, "assembly_name" => "GRCh37"
  }
]};

#cDNA mapping
{
  is_json_GET(
    '/map/cdna/ENST00000314040/292..297',
    $basic_mapping,
    'Mapping transcript cDNA to multi-region position to genome'
  );
}

#CDS mapping
{
  is_json_GET(
    '/map/cds/ENST00000314040/22..27',
    $basic_mapping,
    'Mapping transcript CDS to multi-region position to genome'
  );
}

#protein mapping
{
  is_json_GET(
    '/map/translation/ENSP00000320396/8..9',
    $basic_mapping,
    'Mapping protein to multi-region position to genome'
  );
}

done_testing();
