use strict;
use warnings;
use Test::More;

use Plack::Util qw/headers/;
use Plack::Builder;
use Plack::Test;
use HTTP::Request::Common;
use Time::HiRes qw/sleep/;
use Plack::Middleware::Throttle::Second;
use Plack::Middleware::Throttle::Hour;
use Plack::Middleware::Throttle::Backend::Hash;

sub get {
  my ($cb) = @_;
  my $req = GET "http://localhost/";
  my $res = $cb->($req);
  return $res;
}

sub success {
  my ($cb) = @_;
  my $res = get($cb);
  is($res->code, 200, 'http response is 200');
  return;
}

{
  my $handler = builder {
    enable "Throttle::Hour",
      max => 4,
      backend => Plack::Middleware::Throttle::Backend::Hash->new();
    enable "Throttle::Second",
      max     => 2,
      backend => Plack::Middleware::Throttle::Backend::Hash->new();
    sub { 
      [ '200', [ 'Content-Type' => 'text/html' ], ['hello world'] ] 
    };
  };

  test_psgi
    app => $handler,
    client => sub {
      my $cb  = shift;

      note 'Not limited';
      success($cb) for 1..2;
      
      {
        note 'Now expecting failure';
        my $res = get($cb);
        my $retry_after = $res->header('Retry-After');
        cmp_ok($retry_after, '<', 1, 'Checking Retry-After is smaller than a second');
        sleep($retry_after);
      }

      note 'Retrying after the alotted time has passed';
      success($cb);

      {
        note 'Now we will hit into the hour rate limiter';
        my $res = get($cb);
        my $retry_after = $res->header('Retry-After');
        # Should always be a second as we only work in those time-units
        cmp_ok($retry_after, '>=', 1, 'Checking Retry-After is larger than 1 second');
        # Can't be more than an hour ever
        cmp_ok($retry_after, '<=', (60*60), 'Checking Retry-After is smaller than 60 minutes');
      }
    };
}

# Testing bursts with an additional fudge factor making clients wait for
# time not equal to the rate-limiter's true limit (but imposed by a higher level)
{
  my $handler = builder {
    enable "Throttle::Second",
      max     => 2,
      retry_after_addition => 2,
      backend => Plack::Middleware::Throttle::Backend::Hash->new();
    sub { 
      [ '200', [ 'Content-Type' => 'text/html' ], ['hello world'] ] 
    };
  };

  test_psgi
    app => $handler,
    client => sub {
      my $cb  = shift;

      note 'Not limited';
      success($cb) for 1..2;
      
      {
        note 'Now expecting failure';
        my $res = get($cb);
        my $retry_after = $res->header('Retry-After');
        cmp_ok($retry_after, '<', 3, 'Checking Retry-After is smaller than 3 seconds');
        cmp_ok($retry_after, '>', 1, 'Checking Retry-After is larger than a second');
      }
    };
}

done_testing();