package Plack::Middleware::EnsThrottle::Second;

use Time::HiRes qw//;

use parent 'Plack::Middleware::EnsThrottle';

sub key {
  my ($self, $env) = @_;
  return sprintf('%s_%d', $self->_client_id($env),CORE::time());
}
 
sub reset_time {
  my ($self) = @_;
  my ($seconds, $microseconds) = Time::HiRes::gettimeofday;
  #Current millis from microseconds
  my $millis = $microseconds/1000;
  #The time remaining in seconds before we will allow more requests
  my $diff = (1000 - $millis)/1000; 
  return $diff;
}

sub period {
  return 1;
}

1;