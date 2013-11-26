# Copyright [1999-2013] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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

my $default_remote_user_sub = sub {
  my ($app) = @_;
  sub {
    my ($env) = @_;
    $env->{REMOTE_USER} = '127.0.0.1';
    $env->{REMOTE_ADDR} = '127.0.0.1';
    $app->($env);
  };
};

note 'Fist pass rate limit tests using basic values. More complicated examples to follow';
assert_basic_rate_limit('EnsThrottle::Second', 1, 'second');
assert_basic_rate_limit('EnsThrottle::Minute', 60, 'minute');
assert_basic_rate_limit('EnsThrottle::Hour', 3600, 'hour');

note 'Custom messages';
assert_basic_rate_limit('EnsThrottle::Second', 1, 'second', 'You have done too much!');

{
  my ($remote_user, $remote_addr) = ('127.0.0.1', '127.0.0.1');

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
      client_id_prefix => 'second';

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
      
      sleep_until_next_second();

      my $res = $cb->(GET '/');
      is($res->code(), 200, 'Checking for a 200');
      cmp_ok($res->header('X-RateLimit-Limit'), '==', 1, 'Limit header must be set to 1');
      cmp_ok($res->header('X-RateLimit-Remaining'), '==', 0, 'Remaining header is 0');
      $res = $cb->(GET '/');
      is($res->code(), 429, 'Checking for a 429 (more than 1 request per second I hope)');
      cmp_ok($res->header('Retry-After'), '<', 1.0, 'Retry-After header must be less than a second');
      cmp_ok($res->header('Retry-After'), '>', 0, 'Retry-After header must be greater than zero seconds');
      cmp_ok($res->header('X-RateLimit-Limit'), '==', 1, 'Limit header must be set to 1');
      cmp_ok($res->header('X-RateLimit-Reset'), '<', 1.0, 'Reset header must be less than a second');
      cmp_ok($res->header('X-RateLimit-Period'), '==', 1, 'Rate limit period is a second');
      cmp_ok($res->header('X-RateLimit-Remaining'), '==', 0, 'Remaining header is 0');

      my $retry_after = $res->header('Retry-After');
      Time::HiRes::sleep($retry_after);
      note "Slept for $retry_after second(s). We should be able to do more requests";
      $res = $cb->(GET '/');
      is($res->code(), 200, 'Checking for a 200');
      cmp_ok($res->header('X-RateLimit-Remaining'), '==', 0, 'Remaining header is 0');

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
      client_id_prefix => 'second';
    sub { [ 200, [ 'Content-Type' => 'text/html' ], [ 'hello world' ]]; };
  };

  test_psgi
    app => $app,
    client => sub {
      my ($cb) = @_;

      sleep_until_next_minute();

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
      Time::HiRes::sleep($retry_after);
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
      cmp_ok($value, '==', $max_requests, 'Checking that the backing hash maxs out at '.$max_requests);
    };
}

# Subroutine which sleeps the current process until the next second if we are 
# within 0.3s of it. This gives us a clear run for code to run
sub sleep_until_next_second {
  my $time = Time::HiRes::time();
  my $ceil = ceil($time);
  my $diff = $ceil-$time;
  if($diff < 0.3) {
    note "Sleeping for ${diff} fractions of a second to avoid time related test failures";
    Time::HiRes::sleep($diff);
  }
  else {
    note "Carrying on. We are $diff fraction of a second away from the second. Should be ok";
  }
  return;
}

# Subroutine which sleeps the current process until the next minute if we are 
# within 3 seconds of it. We also test the second using sleep_until_next_second()
sub sleep_until_next_minute {
  my $dt = DateTime->now;
  my $seconds = $dt->second;
  my $diff = 60 - $seconds;
  if($diff < 3) {
    note "Sleeping for $diff seconds to avoid time related test failure";
  }
  else {
    note "Carrying on. We are $diff seconds away from the minute. Should be ok";
  }
  sleep_until_next_second();
  return;
}

sub assert_basic_rate_limit {
  my ($rate_limit_middleware, $period_seconds, $period_name, $custom_message) = @_;
  note 'Testing '.$period_name.' rate limit using '.$rate_limit_middleware;
  my $app = builder {
    # Fake the IP of the requesting user
    enable $default_remote_user_sub;
    enable $rate_limit_middleware, max_requests => 1, path => sub { 1 },  message => $custom_message;
    sub {
      my ($env) = @_;
      return [ 200, [ 'Content-Type' => 'text/html' ], [ 'hello world' ]];
    };
  };

  test_psgi
    app => $app,
    client => sub {
      my ($cb) = @_;

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