package Plack::Middleware::Throttle::Second;

use Moose;
use Time::HiRes qw//;

extends 'Plack::Middleware::Throttle::ReLimiter';

sub cache_key {
  my ($self, $env) = @_;
  return sprintf('%s_%d', $self->client_identifier($env),CORE::time());
}
 
sub reset_time {
  my ($self) = @_;
  my ($seconds, $microseconds) = Time::HiRes::gettimeofday;
  #Current millis from microseconds
  my $millis = $microseconds/1000;
  #Period allowed in milliseconds
  my $period = ($self->period()*1000);
  #The time remaining in seconds before we will allow more requests
  my $diff = ($period - $millis)/1000; 
  return $diff;
}

sub period {
  return 1;
}

1;