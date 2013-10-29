package Plack::Middleware::EnsThrottle::Minute;

use DateTime;

use parent 'Plack::Middleware::EnsThrottle';
 
sub key {
  my ($self, $env) = @_;
  return $self->_client_id($env) . q{_} . DateTime->now->strftime("%Y-%m-%d-%H-%M");
}
 
sub reset_time {
  my $dt = DateTime->now;
  return period() - $dt->second;
}

sub period {
  return 60;
}

1;