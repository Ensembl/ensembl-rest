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

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new();
Catalyst::Test->import('EnsEMBL::REST');

my $VERSION = software_version();

# info/comparas
is_json_GET(
  '/info/comparas', { comparas => [] }, "is empty"
);

# info/data
is_json_GET(
  '/info/data', {releases => [ $VERSION ]}, "only release available is $VERSION"
);

# /info/ping
is_json_GET(
  '/info/ping', { ping => 1 }, "ping responds"
);

# info/species
is_json_GET(
  '/info/species', 
  {species => [ { division => 'Ensembl', name => 'homo_sapiens', groups => ['core'], aliases => [], release => $VERSION} ]},
  "checking only DBA available is the test DBA"
);

done_testing();
