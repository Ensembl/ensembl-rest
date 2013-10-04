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
my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('multi');
Catalyst::Test->import('EnsEMBL::REST');

my $base = '/archive/id/homo_sapiens';
my $gene_id = 'ENSG00000054598';
my $translation_id = "ENSP00000370275";
my $version = 5;

my $response = {ID => $gene_id, latest => "$gene_id.$version", version => "$version", release => "72", peptide => undef, is_current => "1", type => "Gene", possible_replacement => [], assembly => "GRCh37"};

is_json_GET("$base/$gene_id", $response, "Return archive for known ID");

is_json_GET("$base/$gene_id.$version", $response, "Return archive for known ID with version");

my $old_version = $version - 1;
$response = {ID => $gene_id, latest => "$gene_id.$version", version => "$old_version", release => "67", peptide => undef, is_current => "", type => "Gene", possible_replacement => [  { score => '0.953586', stable_id => 'ENSG00000054598' }], assembly => "GRCh37"};

is_json_GET("$base/$gene_id.".($version - 1), $response, "Return archive for known ID with older version");

$version = 1;
$response = {ID => $translation_id, latest => "$translation_id.$version", version => "$version", release => "39", peptide =>
"MTTEGGPPPAPLRRACSPVPGALQAALMSPPPAAAAAAAAAPETTSSSSSSSSASCASSSSSSNSASAPSAACKSAGGGGAGAGSGGAKKASSGLRRPEKPPYSYIALIVMAIQSSPSKRLTLSEIYQFLQARFPFFRGAYQGWKNSVRHNLSLNECFIKLPKGLGRPGKGHYWTIDPASEFMFEEGSFRRRPRGFRRKCQALKPMYHRVVSGLGFGASLLPQGFDFQAPPSAPLGCHSQGGYGGLDMMPAGYDAGAGAPSHAHPHHHHHHHVPHMSPNPGSTYMASCPVPAGPGGVGAAGGGGGGDYGPDSSSSPVPSSPAMASAIECHSPYTSPAAHWSSPGASPYLKQPPALTPSSNPAASAGLHSSMSSYSLEQSYLHQNAREDLSVGLPRYQHHSTPVCDRKDFVLNFNGISSFHPSASGSYYHHHHQSVCQDIKPCVM", is_current => "", type => "Translation", possible_replacement => [ { score => '0.941244', stable_id => 'ENSP00000259806' }], assembly => "NCBI36"};

is_json_GET("$base/$translation_id", $response, "Return archive for peptide");

#  is(
#    @{json_GET("$base/$id", 'Ensembl archives')},
#    3, '3 exons for gene ENSG00000176515');
  
#  is(
#    @{json_GET("$base/$id", 'Ensembl logic name repeats')}, 
#    67, '67 repeats overlapping ENSG00000176515 of logic name repeatmask');
  
#}




done_testing();
