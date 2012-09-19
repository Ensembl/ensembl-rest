package Plack::Middleware::Throttle::Minute;

use Moose;
use DateTime;

extends 'Plack::Middleware::Throttle::ReLimiter';
 
sub cache_key {
  my ($self, $env) = @_;
  return $self->client_identifier($env) . q{_}
    . DateTime->now->strftime("%Y-%m-%d-%H-%M");
}
 
sub reset_time {
  my $dt = DateTime->now;
  return period() - $dt->second;
}

sub period {
  return 60;
}

__PACKAGE__->meta->make_immutable;

1;