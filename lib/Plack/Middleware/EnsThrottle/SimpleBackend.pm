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