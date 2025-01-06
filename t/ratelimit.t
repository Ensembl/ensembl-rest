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

use Test::More;
use Test::Exception;
use Test::Time::HiRes;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Time::HiRes;
use DateTime;
use POSIX qw/ceil/;

use Plack::Middleware::EnsThrottle::SimpleBackend;
use Plack::Middleware::EnsThrottle::Second;
use Plack::Middleware::EnsThrottle::Minute;
use Plack::Middleware::EnsThrottle::Hour;

my $remote_ip_header = 'REMOTE_ADDR';

my $default_remote_user_sub = sub {
  my ($app) = @_;
  sub {
    my ($env) = @_;
    $env->{$remote_ip_header} = '127.0.0.1';
    $app->($env);
  };
};

# Verify that anonymisation works on key for memcached:
my $anonymised_IP = Plack::Middleware::EnsThrottle::Second->_client_id({ REMOTE_USER => '127.0.0.1', HTTP_USER_AGENT => 'Curl'});
is($anonymised_IP, 'throttle_eb4189c32cd43041d6602cafc025a909', 'Given the same user IP and user agent, we should always get the same hashed result');


# First check if we build the object it'll die without key attributes
throws_ok { Plack::Middleware::EnsThrottle::Second->new()->prepare_app() } 
  qr/Cannot continue.+max_requests/, 'No max_requests given caught';
throws_ok { Plack::Middleware::EnsThrottle::Second->new(max_requests => 1)->prepare_app() } 
  qr/Cannot continue.+path/, 'No path given caught';
throws_ok { Plack::Middleware::EnsThrottle::Second->new(max_requests => 1, path => '/a')->prepare_app() } 
  qr/Cannot continue.+CODE/, 'No path coderef given caught'; 
throws_ok { Plack::Middleware::EnsThrottle::Second->new(max_requests => 1, path => sub {})->prepare_app() } 
  qr/Cannot continue.+backend/, 'No backend given caught'; 

note 'Fist pass rate limit tests using basic values. More complicated examples to follow';
assert_basic_rate_limit('EnsThrottle::Second', 1, 'second');
assert_basic_rate_limit('EnsThrottle::Minute', 60, 'minute');
assert_basic_rate_limit('EnsThrottle::Hour', 3600, 'hour');

note 'Custom messages';
assert_basic_rate_limit('EnsThrottle::Second', 1, 'second', 'You have done too much!');

note 'Trying different remote ip headers';
# These are the product of different load balancers. Since the load balancer is the source
# of the request, it must report the real client ID in a header. These are three of those
# headers
new_second();
$remote_ip_header = 'HTTP_X_CLUSTER_CLIENT_IP';
assert_basic_rate_limit('EnsThrottle::Second', 1, 'second', 'Using HTTP_X_CLUSTER_CLIENT_IP as header');

new_second();
$remote_ip_header = 'REMOTE_USER';
assert_basic_rate_limit('EnsThrottle::Second', 1, 'second', 'Using REMOTE_USER as header');

note 'Resetting remote ip header to default';
$remote_ip_header = 'REMOTE_ADDR';
new_second();

{
  my ($remote_user, $remote_addr) = ('127.0.0.1', '127.0.0.1');
  my $backend = Plack::Middleware::EnsThrottle::SimpleBackend->new(); # explicit definition, so we can reset it later

  # Doing my tests with the Second throttle. Don't change the way this builder is setup
  # otherwise the app fails to load and none of the tests will work.
  my $app = builder {
    # Fake the IP of the requesting user
    enable sub {
      my ($app) = @_;
      sub {
        my ($env) = @_;
        $env->{REMOTE_USER} = $remote_user;
        $env->{REMOTE_ADDR} = $remote_addr;
        $app->($env);
      };
    };

    enable 'EnsThrottle::Second', 
      path => sub {
        my ($path) = @_;
        if($path eq '/ignore') {
          return 0;
        }
        return 1;
      },
      max_requests => 1,
      whitelist => '192.168.2.1',
      blacklist => ['192.167.0.0-192.167.255.255'],
      whitelist_hdr => 'Token',
      whitelist_hdr_values => ['loveme', 'imacool'],
      client_id_prefix => 'second', backend => $backend;

    sub {
      my ($env) = @_;
      return [ 200, [ 'Content-Type' => 'text/html' ], [ 'hello world' ]];
    };
  };

  # Checking simple rate limits of > 1 per second means no no
  note 'Testing simple rate limit == 1 per second';
  test_psgi 
    app => $app,
    client =>  sub {
      my ($cb) = @_;
      
      new_second();

      my $res = $cb->(GET '/');
      Time::HiRes::sleep(0.01); # Need to hang about a little to avoid being too fast for the smallest delay
      is($res->code(), 200, 'Checking for a 200 on first request');

      cmp_ok($res->header('X-RateLimit-Limit'), '==', 1, 'Limit header must be set to 1');
      cmp_ok($res->header('X-RateLimit-Remaining'), '==', 0, 'Remaining header is 0');
      $res = $cb->(GET '/');

      is($res->code(), 429, 'Checking for a 429 (on second request with no pause');
      cmp_ok($res->header('Retry-After'), '<=', 1.0, 'Retry-After header must be less than or equal to a second');
      cmp_ok($res->header('Retry-After'), '>', 0, 'Retry-After header must be greater than zero seconds');
      cmp_ok($res->header('X-RateLimit-Limit'), '==', 1, 'Limit header must be set to 1');
      cmp_ok($res->header('X-RateLimit-Reset'), '<=', 1.0, 'Reset header must be less than or equal to a second');
      cmp_ok($res->header('X-RateLimit-Period'), '==', 1, 'Rate limit period is a second');
      cmp_ok($res->header('X-RateLimit-Remaining'), '==', 0, 'Remaining header is 0');
      my $retry_after = $res->header('Retry-After');
      note "Retry delay until current limiter lapses in whole seconds: $retry_after";
      new_second();
      note "Slept for $retry_after second(s). We should be able to do more requests";
      $res = $cb->(GET '/');

      is($res->code(), 200, 'Checking for a 200');
      cmp_ok($res->header('X-RateLimit-Remaining'), '==', 0, 'Remaining header is 0');

      new_second();

      note 'Checking if rate limit is disabled using magic password headers';
      $res = $cb->(GET '/', 'Token' => 'imacool');
      is($res->code(), 200, 'Checking for a 200');
      note 'Sending request again with the rate limit disabling header';
      $res = $cb->(GET '/', 'Token' => 'imacool');
      is($res->code(), 200, 'Checking for a 200, rate limit disabled for this user');

      new_second();

      $res = $cb->(GET '/');
      is($res->code(), 200, 'Checking for a 200');
      $res = $cb->(GET '/', 'Token' => 'imnocool');
      is($res->code(), 429, 'Checking for a 429, when an invalid token is used');

      new_second();

      $res = $cb->(GET '/');
      is($res->code(), 200, 'Checking for a 200');
      $res = $cb->(GET '/', 'Ttoken' => 'imacool');
      is($res->code(), 429, 'Checking for a 429, when an invalid header is used for a token');

      note 'Checking an ignored non-rate limited path';
      $res = $cb->(GET '/ignore');
      is($res->code(), 200, 'Checking for a 200 on the non-throttled path');
      ok(! defined $res->header('X-RateLimit-Limit'), 'Checking on a non-throttled path we avoid adding the headers');

      # User must change as 127.0.0.1 is limited from the earlier retry after + sleep test 
      note 'Rate limit on localhost but switch user and ensure we are not rate limited on our other IP';
      ($remote_addr, $remote_user) = ('127.0.0.2','127.0.0.2');
      $res = $cb->(GET '/');
      is($res->code(), 200, 'Checking for a 200 (not exceeded limit)');
      cmp_ok($res->header('X-RateLimit-Remaining'), '==', 0, 'Remaining header is 0');
      $res = $cb->(GET '/');
      is($res->code(), 429, 'Checking for a 429 (now rate limited)');

      note 'Switched IP';
      ($remote_addr, $remote_user) = ('127.0.0.3','127.0.0.3');
      $res = $cb->(GET '/');
      is($res->code(), 200, 'Checking for a 200 (not limited on another IP)');
    };

  # Checking whitelisting
  note 'Testing whitelisting logic';
  ($remote_addr, $remote_user) = ('192.168.2.1','192.168.2.1');
  test_psgi
    app => $app,
    client => sub {
      my ($cb) = @_;
      my $res = $cb->(GET '/');
      is($res->code(), 200, 'Checking for a 200');
      ok(! defined $res->header('X-RateLimit-Limit'), 'Checking a whitelisted IP gets no headers');
      $res = $cb->(GET '/');
      is($res->code(), 200, 'Checking for a 200 even though we could have broken rate limits');
      ok(! defined $res->header('X-RateLimit-Limit'), 'Checking a whitelisted IP gets no headers and we are never rate limited');
    };

  #Checking blacklisting
  note 'Testing blacklisting logic';
  ($remote_addr, $remote_user) = ('192.167.1.1','192.167.1.1');
  test_psgi
    app => $app,
    client => sub {
      my ($cb) = @_;
      my $res = $cb->(GET '/');
      is($res->code(), 403, 'Checking for a 403');
      is($res->content(), 'IP blacklisted', 'Checking for the right body content');
    };
}

{
  note 'Testing multiple rate limit middlewares';
  my $minute_backend = Plack::Middleware::EnsThrottle::SimpleBackend->new();
  my $max_requests = 5;
  my $app = builder {
    enable $default_remote_user_sub;
    enable 'EnsThrottle::Minute', 
      path => sub { 1 },
      max_requests => $max_requests,
      client_id_prefix => 'minute',
      retry_after_addition => 60,
      backend => $minute_backend,
      ;
    enable 'EnsThrottle::Second', 
      path => sub { 1 },
      max_requests => 3,
      client_id_prefix => 'second', backend => Plack::Middleware::EnsThrottle::SimpleBackend->new();
    sub { [ 200, [ 'Content-Type' => 'text/html' ], [ 'hello world' ]]; };
  };

  test_psgi
    app => $app,
    client => sub {
      my ($cb) = @_;

      Test::Time::HiRes::set_time(undef, Time::HiRes::time() + 60); # Jump into next minute, doesn't matter where.

      note 'Testing limiting on second first (set to 3 req per second)';
      foreach my $iter (1..3) {
        my $res = $cb->(GET '/');
        cmp_ok($res->code(), '==', 200, 'Checking we are not limited on iteration '.$iter);
      }

      #This is request 4
      note 'Per-second limit hit on the 4th request';
      my $res = $cb->(GET '/');
      cmp_ok($res->code(), '==', 429, 'Checking we are limited on the per second rate limiter');
      cmp_ok($res->header('X-RateLimit-Reset'), '<=', 60, 'Checking our reset period is less than or equal to a minute');
      cmp_ok($res->header('X-RateLimit-Period'), '==', 60, 'Rate limit period is a minute');
      my $retry_after = $res->header('Retry-After');
      cmp_ok($retry_after, '<=', 1, 'Checking Retry-After is less than or equal to a second (we hit the per second limit)');

      new_second();

      note "Slept for $retry_after second(s). Able to do more 2 more requests before hitting the minute rate limit";

      #Final request
      $res = $cb->(GET '/');
      cmp_ok($res->code(), '==', 200, 'Checking we are not limited on iteration 5');
      
      $res = $cb->(GET '/');
      cmp_ok($res->code(), '==', 429, 'Checking we are limited on the per minute rate limiter');
      cmp_ok($res->header('X-RateLimit-Reset'), '<=', 60, 'Checking our reset period is less than or equal to a minute');
      cmp_ok($res->header('X-RateLimit-Period'), '==', 60, 'Rate limit period is a minute');
      cmp_ok($res->header('Retry-After'), '>=', 60, 'Retry-After header must be greater than 60 seconds (we have added 60 seconds to the value)');

      #Trigger a final request
      $cb->(GET '/');

      #Now inspect the numbers in the storage engine. We should not have negative numbers
      my ($value) = values %{$minute_backend->{hash}};
      cmp_ok($value, '==', $max_requests, 'Checking that the backing hash maxes out at '.$max_requests);
    };
}


# Force the clock onto the next second. Note core::time and TimeHiRes::time are not necessarily the same when doing this.
sub new_second {
  my ($seconds) = Time::HiRes::time();
  $seconds++;
  Test::Time::HiRes::set_time(undef, $seconds);
}

sub now {
  my ($second, $micro) = Time::HiRes::gettimeofday();
  note sprintf "%d.%d\n", $second, $micro;
}


sub assert_basic_rate_limit {
  my ($rate_limit_middleware, $period_seconds, $period_name, $custom_message) = @_;
  note 'Testing '.$period_name.' rate limit using '.$rate_limit_middleware;
  my $app = builder {
    # Fake the IP of the requesting user
    enable $default_remote_user_sub;
    enable $rate_limit_middleware, max_requests => 1, path => sub { 1 },  message => $custom_message, backend => Plack::Middleware::EnsThrottle::SimpleBackend->new();
    sub {
      my ($env) = @_;
      return [ 200, [ 'Content-Type' => 'text/html' ], [ 'hello world' ]];
    };
  };

  test_psgi
    app => $app,
    client => sub {
      my ($cb) = @_;
      new_second();
      my $res = $cb->(GET '/');
      cmp_ok($res->code(), '==', 200, 'Checking we are not limited');
      $res = $cb->(GET '/');
      cmp_ok($res->code(), '==', 429, 'Checking we are limited');
      cmp_ok($res->header('X-RateLimit-Reset'), '<=', $period_seconds, 'Reset header must be less than or equal to a '.$period_name);
      cmp_ok($res->header('X-RateLimit-Period'), '==', $period_seconds, 'Rate limit period is a '.$period_name);
      if($custom_message) {
        is($res->content(), $custom_message, 'Checking output is set to the custom message');
      }
    };

  return;
}

done_testing();
