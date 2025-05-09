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
use Test::Deep;
use Catalyst::Test ();
use Bio::EnsEMBL::Test::MultiTestDB;

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new();
Catalyst::Test->import('EnsEMBL::REST');

#Assembly mapping
{
  cmp_deeply(json_GET(
    '/map/homo_sapiens/GRCh37/6/GRCh37', 'map homo_sapiens'),
    {"mappings" => [{
      "original" => {
        "seq_region_name" => "6","strand" => 1,
        "coord_system" => "chromosome","end" => 171115067,
        "start" => 1,"assembly" => "GRCh37"
      },
      "mapped" => {
        "seq_region_name" => "6","strand" => 1,
        "coord_system" => "chromosome","end" => 171115067,
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
  cmp_deeply(json_GET(
    '/map/cdna/ENST00000314040/292..297', 'map transcript the hard way'),
    $basic_mapping,
    'Mapping transcript cDNA to multi-region position to genome'
  );
}

#CDS mapping
{
  cmp_deeply(json_GET(
    '/map/cds/ENST00000314040/22..27', 'map cds the hard way'),
    $basic_mapping,
    'Mapping transcript CDS to multi-region position to genome'
  );
}

#protein mapping
{
  cmp_deeply(json_GET(
    '/map/translation/ENSP00000320396/8..9','map translation the hard way'),
    $basic_mapping,
    'Mapping protein to multi-region position to genome'
  );
}

my $basic_mapping_cdna_including_original_region = { mappings => [
  {'original' => {'gap' => 0,'strand' => 1,'coord_system' => 'cdna','rank' => 0,'start' => 292,'end' => 294},
   'mapped' => {'assembly_name' => 'GRCh37','end' => 1101531,'seq_region_name' => '6','gap' => 0, 'strand' => 1,'coord_system' => 'chromosome','rank' => 0,'start' => 1101529}
  },
  {'original' => {'gap' => 0,'strand' => 1,'coord_system' => 'cdna','rank' => 0,'start' => 295,'end' => 297},
   'mapped' => {'assembly_name' => 'GRCh37','end' => 1102043,'seq_region_name' => '6','gap' => 0,'strand' => 1,'coord_system' => 'chromosome','rank' => 0,'start' => 1102041}
  }
  ]};
#cDNA mapping with include_original_region option
{
  cmp_deeply(json_GET(
    '/map/cdna/ENST00000314040/292..297?include_original_region=1', 'map cdna'),
    $basic_mapping_cdna_including_original_region,
    'Mapping transcript cDNA to multi-region position to genome with include_original_region option'
  );
}

my $basic_mapping_cds_including_original_region = {mappings => [
  {'original' => {'gap' => 0,'strand' => 1,'coord_system' => 'cds','rank' => 0,'start' => 22,'end' => 24},
   'mapped' => {'assembly_name' => 'GRCh37','end' => 1101531,'seq_region_name' => '6','gap' => 0,'strand' => 1,'coord_system' => 'chromosome','rank' => 0,'start' => 1101529}
  },
  {'original' => {'gap' => 0,'strand' => 1,'coord_system' => 'cds','rank' => 0,'start' => 25,'end' => 27},
   'mapped' => {  'assembly_name' => 'GRCh37','end' => 1102043,'seq_region_name' => '6','gap' => 0,'strand' => 1,'coord_system' => 'chromosome','rank' => 0,'start' => 1102041}
  }
  ]};

#CDS mapping with include_original_region option
{
  cmp_deeply(json_GET(
    '/map/cds/ENST00000314040/22..27?include_original_region=1', 'map cds with original region'),
    $basic_mapping_cds_including_original_region,
    'Mapping transcript CDS to multi-region position to genome with include_original_region option'
  );
}

# The following tests are for objects with different types but the same stable id.     
#cDNA mapping
{
  cmp_deeply(json_GET(
    '/map/cdna/CCDS10020.1/100..300', 'map cdna'),
    { mappings => [
      {
        "assembly_name"=>"GRCh37","end"=>28081775,"seq_region_name"=>"15","gap"=>0,
        "strand"=>-1,"coord_system"=>"chromosome","rank"=>0,"start"=>28081648
      },
      {
        "assembly_name"=>"GRCh37","end"=>28032163,"seq_region_name"=>"15","gap"=>0,
        "strand"=>-1,"coord_system"=>"chromosome","rank"=>0,"start"=>28032091
      }
    ]},
    'Mapping transcript cDNA to multi-region position to genome for CCDS10020.1'
  );
}

#CDS mapping
{
  cmp_deeply(json_GET( 
    '/map/cds/CCDS10020.1/100..300', 'map cds'),
    { "mappings" => [
      {
        "assembly_name"=>"GRCh37","end"=>28081775,"seq_region_name"=>"15","gap"=>0,
        "strand"=>-1,"coord_system"=>"chromosome","rank"=>0,"start"=>28081648
      },
      {
        "assembly_name"=>"GRCh37","end"=>28032163,"seq_region_name"=>"15","gap"=>0,
        "strand"=>-1,"coord_system"=>"chromosome","rank"=>0,"start"=>28032091
      }
    ]},
    'Mapping transcript CDS to multi-region position to genome for CCDS10020.1'
  );
}

#protein mapping
{
  cmp_deeply(json_GET( 
    '/map/translation/CCDS10020.1/100..300', 'map translation'),
    { "mappings" => [
      {
        "assembly_name"=>"GRCh37","end"=>28032093,"seq_region_name"=>"15","gap"=>0,
        "strand"=>-1,"coord_system"=>"chromosome","rank"=>0,"start"=>28032065
      },
      {
        "assembly_name"=>"GRCh37","end"=>28028059,"seq_region_name"=>"15","gap"=>0,
        "strand"=>-1,"coord_system"=>"chromosome","rank"=>0,"start"=>28027871
      },
      {
        "assembly_name"=>"GRCh37","end"=>28024902,"seq_region_name"=>"15","gap"=>0,
        "strand"=>-1,"coord_system"=>"chromosome","rank"=>0,"start"=>28024845
      },
      {
        "assembly_name"=>"GRCh37","end"=>28022573,"seq_region_name"=>"15","gap"=>0,
        "strand"=>-1,"coord_system"=>"chromosome","rank"=>0,"start"=>28022501
      },
      {
        "assembly_name"=>"GRCh37","end"=>28018557,"seq_region_name"=>"15","gap"=>0,
        "strand"=>-1,"coord_system"=>"chromosome","rank"=>0,"start"=>28018397
      },
      {
        "assembly_name"=>"GRCh37","end"=>28016186,"seq_region_name"=>"15","gap"=>0,
        "strand"=>-1,"coord_system"=>"chromosome","rank"=>0,"start"=>28016104
      },
      {
        "assembly_name"=>"GRCh37","end"=>28014929,"seq_region_name"=>"15","gap"=>0,
        "strand"=>-1,"coord_system"=>"chromosome","rank"=>0,"start"=>28014920
      }
    ]},
    'Mapping protein to multi-region position to genome for CCDS10020.1'
  );
}

done_testing();
