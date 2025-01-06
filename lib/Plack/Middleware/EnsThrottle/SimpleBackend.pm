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

package Plack::Middleware::EnsThrottle::SimpleBackend;

=head2 new

  Arg [1]     : HashRef
                The argument list to bless into an object instance.
  Description : Creates a new instance of this backend. Once constructed
                we call C<init()>.

=cut

sub new {
  my ($class, $args) = @_;
  $args ||= {};
  my $self = bless($args, ref($class) || $class);
  $self->init();
  return $self;
}

=head2 init

  Description : Gives you a hook to call post construction initalistion code

=cut

sub init {
  my ($self) = @_;
  $self->{hash} = {};
  return;
}

=head2 increment

  Arg [1]     : String
                The key to increment its backing value by one
  Description : Attempts to increment the backing hash's key by 1 for the given key

=cut

sub increment {
  my ($self, $key) = @_;
  if(exists $self->{hash}->{$key}) {
    $self->{hash}->{$key}++; 
  }
  else {
    $self->{hash}->{$key} = 1;
  }
  return $self->{hash}->{$key};
}

=head2 current

  Arg [1]     : String
                The key to retrieve its value by
  Description : Returns the current count of increments of a key

=cut

sub current {
  my ($self, $key) = @_;
  return (exists $self->{hash}->{$key}) ? $self->{hash}->{$key} : 0;
}

=head2 remove

  Arg [1]     : String
                The key to remove
  Description : Removes the given key from the backing hash

=cut

sub remove {
  my ($self, $key) = @_;
  return delete $self->{hash}->{$key};
}

1;
