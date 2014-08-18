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
use Bio::EnsEMBL::Test::TestUtils;

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new();
Catalyst::Test->import('EnsEMBL::REST');

my @ids = map {qq/$_/} ( 1..100 );
my $big_message = '{ "ids" : ['.join(',',@ids).'] }';
debug($big_message);
action_bad_post('/vep/homo_sapiens/id',$big_message,qr/POST message too large/,'Throw massive message to test over-large submissions');


done_testing();
