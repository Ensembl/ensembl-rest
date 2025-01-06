=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
Copyright [2016-2025] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

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
