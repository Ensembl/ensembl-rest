=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
Copyright [2016-2025] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package Plack::Middleware::EnsThrottle;

=head 1 NAME

Plack::Middleware::EnsThrottle

=head1 SYNOPSIS

# Simple in process rate limiting (using a simple hash backend and limiting everything)
enable 'EnsThrottle::Second',
  max_requests => 10,
  path => sub { 1 },
  backend => Plack::Middleware::EnsThrottle::SimpleBackend->new();

# Distributed using memcached with whitelists, blacklists and 
enable 'EnsThrottle::Second',
  backend => Plack::Middleware::EnsThrottle::MemcachedBackend->new( 
    #memcached code must implement get/remove/add/incr
    #expire is how long memcached should hold onto the value before expiring
    memcached => Cache::Memcached->new(servers => ['server.host']), expire => '2'
  ),
  max_requests => 10, #Max number of requests is 10 per second
  path => sub {
    my ($env) = @_;
    return 0 if $env->{PATH_INFO} =~ /\/admin/; #do not limit anything that starts /admin
    return 1; #limit everything else
  },
  blacklist => '192.168.2.1', #blacklist a single IP
  whitelist => ['192.168.0.0-192.169.255.255'], #whitelist a range
  whitelist_hdr => 'X-My-Secret-Token',
  whitelist_hdr_values => ['loveme'],
  client_id_prefix => 'second', #make the generated key more unique
  message => 'custom rate exceeded message',
  # If specified once limit has been hit add this value to the Retry-After header.
  # Useful should you want to punish exceeders more
  retry_after_addition => 0,
;

=head1 DESCRIPTION

This class is a Ensembl specific implementation of rate limiters in a Plack layer. We have
replaced L<Plack::Middleware::Limiter> as it used Moose and deemed too heavy for a Plack
middleware. This limits the amount of functionality down to exactly what is wanted from
REST.

Three implementations exist:

=over 8

=item B<Plack::Middleware::EnsThrottle::Second>

=item B<Plack::Middleware::EnsThrottle::Minute>

=item B<Plack::Middleware::EnsThrottle::Hour>

=back

In all cases they limit up-to their time unit. For example a user is first seen at 2:45pm using the Hour rate limit (set to 1K). They have 15 minutes to use up all 1K tokens before their limit before is reset. This is done for convencience as we do not need to record the first time we see a user in the system.

=head1 Attributes

=over 8

=item B<max_requests> - Integer (required). Maximum requests

=item B<path> - CodeRef (required). Given the $env hash. Inspect PATH_INFO and see if you need to limit a path

=item B<backend> - Plack::Middleware::EnsThrottle::Backend. The backend to use. Only available are SimpleBackend (the default) and MemcachedBackend 

=item B<client_id_prefix> - Scalar. The prefix to use for keys. Important if you are going to have multiple rate limiters on single memcached instance

=item B<message> - Scalar. Send back a custom message when we hit a limit

=item B<retry_after_addition> - Number. Add this period of time to the Retry-After value to penalise people who exceed the limits

=item B<blacklist> - ArrayRef or Scalar. IPs to blacklist. Uses Net::CIDR::Lite so look there for docs. Takes precedence over whitelist

=item B<whitelist> - ArrayRef or Scalar. IPs to never apply limits to. Uses Net::CIDR::Lite so look there for docs

=back

=cut

use strict;
use warnings;
use parent 'Plack::Middleware';
use Plack::Util::Accessor qw(max_requests backend path blacklist whitelist whitelist_hdr whitelist_hdr_values client_id_prefix message retry_after_addition);
use Plack::Util;
use Carp;
use Net::CIDR::Lite;
use Readonly;
use Plack::Middleware::EnsThrottle::SimpleBackend;
use Plack::Request;
use Digest::MD5 qw/md5_hex/;

Readonly::Scalar my $CLIENT_ID_PREFIX => 'throttle';
Readonly::Scalar my $MESSAGE => 'Too many requests';
Readonly::Scalar my $RETRY_AFTER_ADDITION => 0;

# Implement the following in subclasses (stubbed as yada-yada)
# - period - time over which we calculate the limit (seconds)
# - key - the key to use in our backend storage layer to store current number of requests
# - reset_time - time until we will accept a new request

sub period { ... }
sub key { ... }
sub reset_time { ... }

sub prepare_app {
  my ($self) = @_;
  croak "Cannot continue. No max_requests given" unless $self->max_requests();
  $self->blacklist($self->_populate_cidr($self->blacklist));
  $self->whitelist($self->_populate_cidr($self->whitelist));
  $self->whitelist_hdr_values($self->_populate_array($self->whitelist_hdr_values));
  my $path = $self->path();
  croak "Cannot continue. No path given" unless $path;
  croak "Cannot continue. path must be an CODE ref" if ref($path) ne 'CODE';
  croak "Cannot continue. No backend given. Please instatiate a MemcachedBackend or SimpleBackend" if ! $self->backend();
  return;
}

sub call {
  my ($self, $env) = @_;
  
  my ($add_headers, $retry_after) = (1, 0);
  my $res;
  my $remaining_requests = 0;

  my $request = Plack::Request->new($env);

  if($self->_throttle_path($env)) {

    #If IP was in the blacklist then reject & allow no headers
    if($self->_blacklisted($env)) {
      $res = [403, ['Content-Type', 'text/plain'], ['IP blacklisted']];
      $add_headers = 0;
    }
    #If IP was whitelisted then let through & allow no headers
    elsif($self->_whitelisted($env)) {
      $res = $self->app->($env);
      $add_headers = 0;
    }
    elsif($self->_whitelisted_hdr($request->headers)) {
      $res = $self->app->($env);
      $add_headers = 0;
    }
    else {
      $remaining_requests = $self->remaining_requests($env);
      #If we are throttled then we have to prepare the throttle response
      if($remaining_requests == 0) {
        $res = [429, ['Content-Type', 'text/plain'], [$self->message() || $MESSAGE]];
        $retry_after = 1;
      }
      else {
        $res = $self->app->($env);
        $remaining_requests--; # take it down by one as we've done a request
      }
    }
  }
  else {
    $res = $self->app->($env);
    $add_headers = 0;
  }

  return Plack::Util::response_cb($res, sub {
    my $res = shift;
    if($add_headers) {
      $self->_add_throttle_headers($res, $remaining_requests, $retry_after);
    }
    return;
  });
}

=head2 remaining_requests

  Arg [1]     : Plack env
                Environment of the current request
  Description : Will return the current amount of requests allowed by this 
                limiter. Each time you request this value we will increment
                the backing store by 1 using the key returned from the 
                c<key()> method.

=cut

sub remaining_requests {
  my ($self, $env) = @_;
  my $backend = $self->backend();
  my $max_requests = $self->max_requests();
  my $key = $self->key($env);
  my $requests_completed = $backend->current($key);
  my $remaining_requests = $max_requests - $requests_completed;
  #Increment the backing value because we've just claimed a token
  if($remaining_requests > 0) {
    $backend->increment($key);
  }
  return $remaining_requests;
}

=head2 _throttle_path

  Arg [1]     : Plack env
                Environment of the current request
  Description : Inspects PATH_INFO from the given environment and will
                attempt to see if the path was one under throttle. Applies
                the callback registered with the construction arg <path>.

=cut

sub _throttle_path {
  my ($self, $env) = @_;
  my $path = $env->{PATH_INFO};
  my $callback = $self->path();
  return $callback->($path);
}

=head2 _add_throttle_headers

  Arg [1]     : Plack response
  Arg [2]     : Integer
                Number of remaining requests to report back to the user
  Arg [3]     : Boolean
                Indicates if we had exceeded our rate limit and need to add
                the Retry-After header
  Description : This adds the X-RateLimit-??? headers to a request. We will
                add Limit (total amount available), Reset (time before we reset), 
                Period (limit period in seconds) and Remaining (requests remaining).

                We only ever set headers to this will replace any existing header 
                populated by a plack response further down the stack.

=cut

sub _add_throttle_headers {
  my ($self, $res, $remaining_requests, $retry_after) = @_;
  my $headers = $res->[1];
  my $reset_time = $self->reset_time();
  Plack::Util::header_set( $headers, 'X-RateLimit-Limit', $self->max_requests() );
  Plack::Util::header_set( $headers, 'X-RateLimit-Reset', $reset_time );
  Plack::Util::header_set( $headers, 'X-RateLimit-Period', $self->period() );
  Plack::Util::header_set( $headers, 'X-RateLimit-Remaining', $remaining_requests );
  if($retry_after) {
    my $retry_after_addition = $self->retry_after_addition() || $RETRY_AFTER_ADDITION;
    # Do a ceiling on the reset time to give second resolution, going so high resolution
    # in exact reset times causes potential breakage depending on the platform's timer resolution
    $reset_time = ($reset_time == int $reset_time) ? $reset_time : int($reset_time + 1);
    Plack::Util::header_set( $headers, 'Retry-After', $reset_time+$retry_after_addition );
  }
  return $res;
}

sub _blacklisted {
  my ($self, $env) = @_;
  my $list = $self->blacklist();
  return 0 unless $list;
  return $list->find($self->_client_id_helper($env));
}

sub _whitelisted {
  my ($self, $env) = @_;
  my $list = $self->whitelist();
  return 0 unless $list;
  return $list->find($self->_client_id_helper($env));
}

sub _whitelisted_hdr {
    my ($self, $headers) = @_;

    my $header = $self->whitelist_hdr();
    my $values = $self->whitelist_hdr_values();
    return 0 unless $header && @{$values};
    # Since this is a special header just for us we're
    # going to assume there's only one value, to speed
    # the checking code below
    my $hdr_value = $headers->header($header);
    return 0 unless $hdr_value;
    return grep { $_ eq $hdr_value } @{$values};
}

# Try to get the IP of the real client, and not any intervening load balancer or proxy
sub _client_id_helper {
  my ( $self, $env ) = @_;

  return $env->{REMOTE_USER} ||
    $env->{HTTP_X_CLUSTER_CLIENT_IP} ||
    $env->{REMOTE_ADDR};
}

# This is only called in subclasses - Second, Minute, Hour.
# Add the user agent to salt the IP in unpredictable fashion, then anonymise via md5sum.
# This is to improve our GDPR compliance in regard to storing user IP addresses in the memcached.
sub _client_id {
  my ($self, $env) = @_;
  my $id = $self->_client_id_helper($env);
  
  my $prefix = $self->client_id_prefix() || $CLIENT_ID_PREFIX;
  my $user_agent = '';
  $user_agent = $env->{HTTP_USER_AGENT} if exists $env->{HTTP_USER_AGENT};
  return $prefix.'_'.md5_hex($user_agent.$id);
}

sub _populate_cidr {
  my ($self, $input) = @_;
  my $cidr = Net::CIDR::Lite->new();
  if($input) {
    $input = (ref($input) eq 'ARRAY') ? $input : [$input];
    $cidr->add_any($_) for @{$input};
  }
  return $cidr;
}

# Ensure value is an array if a scalar is passed
sub _populate_array {
    my ($self, $input) = @_;

    if($input) {
      $input = (ref($input) eq 'ARRAY') ? $input : [$input];
    }
    return $input;
}

1;
