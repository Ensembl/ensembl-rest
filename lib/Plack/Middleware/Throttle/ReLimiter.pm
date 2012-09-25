package Plack::Middleware::Throttle::ReLimiter;

use Moose;
extends 'Plack::Middleware::Throttle::Limiter';

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

1;
