package Plack::Middleware::EnsThrottle::Hour;

use DateTime;
use parent 'Plack::Middleware::EnsThrottle';

sub key {
  my ( $self, $env ) = @_;
  return $self->_client_id($env) . "_" . DateTime->now->strftime("%Y-%m-%d-%H");
}

sub reset_time {
  my $dt = DateTime->now;
  return (3600 - (( 60 * $dt->minute ) + $dt->second));
}

sub period {
	return 3600;
}

1;