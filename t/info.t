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
use Bio::EnsEMBL::ApiVersion qw/software_version/;
use Test::Differences;

my $test = Bio::EnsEMBL::Test::MultiTestDB->new();
my $dba = $test->get_DBAdaptor('core');
Catalyst::Test->import('EnsEMBL::REST');
require EnsEMBL::REST;

my $VERSION = software_version();
my $schema_version = $dba->get_MetaContainer()->single_value_by_key('schema_version');
$schema_version *= 1;

# info/comparas
is_json_GET(
  '/info/comparas', { comparas => [] }, "is empty"
);

# info/data
is_json_GET(
  '/info/data', {releases => [ $schema_version ]}, "only release available is $schema_version"
);

# /info/ping
is_json_GET(
  '/info/ping', { ping => 1 }, "ping responds"
);

# info/species
{
  my $url = '/info/species';
  my $msg = 'Checking only DBA available is the test DBA';
  my $info_species = json_GET($url, $msg);
  if($info_species) {
    my $expected = {species => [ { division => 'Ensembl', name => 'homo_sapiens', groups => ['core', 'variation'], aliases => [], release => $schema_version} ]};
    $info_species->{species}->[0]->{groups} = [sort @{$info_species->{species}->[0]->{groups}}];
    eq_or_diff_data($info_species, $expected, "$url | $msg");
  }
}
# is_json_GET(
#   '/info/species', 
#   {species => [ { division => 'Ensembl', name => 'homo_sapiens', groups => ['core', 'variation'], aliases => [], release => $schema_version} ]},
#   "checking only DBA available is the test DBA"
# );

# /info/software
is_json_GET(
  '/info/software', { release => $VERSION }, "software reports current version $VERSION"
);

# /info/rest
is_json_GET(
  '/info/rest', { release => $EnsEMBL::REST::VERSION }, "rest current version is $EnsEMBL::REST::VERSION"
);

done_testing();
