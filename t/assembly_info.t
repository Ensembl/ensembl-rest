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
use Catalyst::Test ();
use Bio::EnsEMBL::Test::MultiTestDB;

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new();
Catalyst::Test->import('EnsEMBL::REST');

is_json_GET(
  '/info/assembly/homo_sapiens',
  {
    'assembly_name' => 'GRCh37.p8',
    'assembly_date' => '2009-02',
    top_level_region => [
     {coord_system => 'chromosome', name => '6', length => 171115067},
     {coord_system => 'chromosome', name => 'X', length => 155270560}],
    karyotype => [qw/6 X/],
    'genebuild_start_date' => "2010-07-Ensembl",
    'genebuild_initial_release_date' => "2011-04",
    'genebuild_last_geneset_update' => "2012-10",
    'genebuild_method' => "full_genebuild",
    coord_system_versions => [qw/GRCh37 NCBI36 NCBI35 NCBI34/ ],
    default_coord_system_version => 'GRCh37',
    assembly_accession => 'GCA_000001405.9',
    'golden_path' => '3096649726'
  },
  'Checking output of info'
);

is_json_GET(
  '/info/assembly/homo_sapiens/6',
  {assembly_exception_type => 'REF', coordinate_system => 'chromosome', is_chromosome => 1, is_circular => 0, length => 171115067, assembly_name => 'GRCh37' },
  'Checking info of region 6 matches expected'
);

is_json_GET(
  '/info/assembly/homo_sapiens/6?synonyms=1',
  {assembly_exception_type => 'REF', coordinate_system => 'chromosome', is_chromosome => 1, is_circular => 0, length => 171115067, assembly_name => 'GRCh37', synonyms => [{'name' => 'NC_000006.12', 'dbname' => 'RefSeq_genomic'}, {'name' => 'chr6', 'dbname' => 'UCSC'}] },
  'Checking info of region 6 synonyms matches expected'
);

is_json_GET(
  '/info/assembly/homo_sapiens/6?bands=1',
  {assembly_exception_type => 'REF', coordinate_system => 'chromosome', is_chromosome => 1, is_circular => 0, length => 171115067, assembly_name => 'GRCh37', karyotype_band => [{'assembly_name' => 'GRCh37', 'id' => 'q11.21', 'seq_region_name' => '6', 'start' => '1026863', 'end' => '1027454', 'strand' => '0', 'stain' => 'gneg'}] },
  'Checking info of region 6 bands matches expected'
);

action_bad('/info/assembly/homo_sapiens/wibble', 'Checking a bogus region results in no information');

done_testing();
