use strict;
use warnings;
use Test::More;

use Catalyst::Test 'EnsEMBL::REST';
use EnsEMBL::REST::Controller::Adaptors;

ok( request('/adaptors')->is_success, 'Request should succeed' );
done_testing();
