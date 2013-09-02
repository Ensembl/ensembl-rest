package Plack::Middleware::Throttle::ReLimiter;

use Moose;
extends 'Plack::Middleware::Throttle::Limiter';

# Provides a way of controlling the retry after env variable by
# adding a constant amount of time. This is useful if you are using
# the per-second limiter as a way of controlling per second bursts
has 'retry_after_addition' => ( isa => 'Num', is => 'ro', lazy => 1, default => 0 );

use Plack::Util qw//;
use Scalar::Util qw//;

sub _create_backend {
  my ( $self, $backend ) = @_;
  if (! defined $backend ) {
    Plack::Util::load_class("Plack::Middleware::Throttle::Backend::Hash");
    return Plack::Middleware::Throttle::Backend::Hash->new;
  }

  return $backend if defined $backend && Scalar::Util::blessed $backend;
  die "backend must be a cache object";
}

sub client_identifier {
  my ($self, $env) = @_;
  if($env->{HTTP_X_FORWARDED_HOST}) {
    return $self->key_prefix."_".$env->{HTTP_X_FORWARDED_HOST};
  }
  return $self->SUPER::client_identifier($env);
}

override 'over_rate_limit' => sub {
  my ($self) = @_;
  my $res = super();
  my $headers = $res->[1];
  my $reset_time = $self->reset_time();
  $reset_time += $self->retry_after_addition();
  Plack::Util::header_set( $headers, 'Retry-After', $reset_time );
  return $res;
};

1;
