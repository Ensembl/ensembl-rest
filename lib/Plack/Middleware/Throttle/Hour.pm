package Plack::Middleware::Throttle::Hour;

use Moose;
use DateTime;
extends 'Plack::Middleware::Throttle::ReLimiter';

sub cache_key {
    my ( $self, $env ) = @_;
    $self->client_identifier($env) . "_"
        . DateTime->now->strftime("%Y-%m-%d-%H");
}

sub reset_time {
    my $dt = DateTime->now;
    3600 - (( 60 * $dt->minute ) + $dt->second);
}

1;