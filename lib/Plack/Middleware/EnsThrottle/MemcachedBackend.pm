package Plack::Middleware::EnsThrottle::MemcachedBackend;

# Expects to be given a memcached instance like Cache::Memcached or Cache::Memcached::Fast
use Plack::Util::Accessor qw/ memcached expire/;
use parent qw/Plack::Middleware::EnsThrottle::SimpleBackend/;

sub init {
  my ($self) = @_;
  die "No memcached instance given" unless $self->memcached();
  die "No expire time given" unless $self->expire();
  return;
}

sub increment {
  my ($self, $key) = @_;
  my $value = 1;
  my $memcached = $self->memcached();
  my $v = $memcached->incr($key, $value);
  if(! $v) {
    #Try to add the value 1 if it didn't exist before. Also make sure we expire it
    my $expire = $self->expire();
    $v = $memcached->add($key, $value, $expire);
    if (! $v) {
      #Means someone else called the add() so we can use increment again. 
      #no expire needed
      $v = $memcached->incr($key, $value);
    }
  }
  return $v;
}

sub current {
  my ($self, $key) = @_;
  return $self->memcached->get($key) || 0;
}

sub remove {
  my ($self, $key) = @_;
  return $self->memcached->remove($key);
}

1;