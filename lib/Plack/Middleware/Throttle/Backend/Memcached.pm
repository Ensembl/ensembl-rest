package Plack::Middleware::Throttle::Backend::Memcached;

use Moose;
use Plack::Util;

has 'driver'    => ( isa => 'Str', is => 'ro', required => 1);
has 'args'      => ( isa => 'HashRef', is => 'ro', required => 1);
has 'expire'    => ( isa => 'Int', is => 'ro', required => 1);
has '_backend'  => ( isa => 'Ref', is => 'ro', builder => '_build_backend', lazy => 1);

sub _build_backend {
  my ($self) = @_;
  my $driver = $self->driver();
  my $args = $self->args();
  Plack::Util::load_class($driver);
  return $driver->new(%{$args});
}

sub incr {
  my ($self, $key, $value) = @_;
  $value ||= 1;
  my $backend = $self->_backend();
  my $expire = $self->expire();
  my $v = $backend->incr($key, $value, $expire);
  if(! $v) {
    #Try to add the value 1 if it didn't exist before
    $v = $backend->add($key, $value, $expire);
    if (! $v) {
      #Means someone else called the add() so we can use increment again
      $v = $backend->incr($key, $value, $expire);
    }
  }
  return $v;
}

sub get {
  my ($self, $key) = @_;
  my $backend = $self->_backend();
  return $backend->get($key);
}

sub set {
  my ($self, $key, $value) = @_;
  my $backend = $self->_backend();
  my $expire = $self->expire();
  return $backend->set($key, $value, $expire);
}

__PACKAGE__->meta->make_immutable;

1;