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
use Test::Differences;
use Catalyst::Test ();
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;
use Bio::EnsEMBL::Registry;

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');
my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('multi');
Catalyst::Test->import('EnsEMBL::REST');

my $base = '/archive/id';
my $gene_id = 'ENSG00000054598';
my $translation_id = "ENSP00000370275";
my $version = 5;

my $response = {id => $gene_id, latest => "$gene_id.$version", version => "$version", release => "75", peptide => undef, is_current => "1", type => "Gene", possible_replacement => [], assembly => "GRCh37"};

is_json_GET("$base/$gene_id", $response, "Return archive for known ID");

is_json_GET("$base/$gene_id.$version", $response, "Return archive for known ID with version");

my $old_version = $version - 1;
$response = {id => $gene_id, latest => "$gene_id.$version", version => "$old_version", release => "67", peptide => undef, is_current => "", type => "Gene", possible_replacement => [  { score => '0.953586', stable_id => 'ENSG00000054598' }], assembly => "GRCh37"};

is_json_GET("$base/$gene_id.".$old_version, $response, "Return archive for known ID with older version");

$version = 1;
$response = {id => $translation_id, latest => "$translation_id.$version", version => "$version", release => "39", peptide =>
"MTTEGGPPPAPLRRACSPVPGALQAALMSPPPAAAAAAAAAPETTSSSSSSSSASCASSSSSSNSASAPSAACKSAGGGGAGAGSGGAKKASSGLRRPEKPPYSYIALIVMAIQSSPSKRLTLSEIYQFLQARFPFFRGAYQGWKNSVRHNLSLNECFIKLPKGLGRPGKGHYWTIDPASEFMFEEGSFRRRPRGFRRKCQALKPMYHRVVSGLGFGASLLPQGFDFQAPPSAPLGCHSQGGYGGLDMMPAGYDAGAGAPSHAHPHHHHHHHVPHMSPNPGSTYMASCPVPAGPGGVGAAGGGGGGDYGPDSSSSPVPSSPAMASAIECHSPYTSPAAHWSSPGASPYLKQPPALTPSSNPAASAGLHSSMSSYSLEQSYLHQNAREDLSVGLPRYQHHSTPVCDRKDFVLNFNGISSFHPSASGSYYHHHHQSVCQDIKPCVM", is_current => "", type => "Translation", possible_replacement => [ { score => '0.941244', stable_id => 'ENSP00000259806' }], assembly => "NCBI36"};

is_json_GET("$base/$translation_id", $response, "Return archive for peptide");


done_testing();
