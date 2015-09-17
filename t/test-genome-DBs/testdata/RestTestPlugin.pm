package RestTestPlugin;
use Bio::EnsEMBL::Variation::Utils::BaseVepPlugin;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepPlugin);

sub new {
  my $class = shift;
  
  my $self = $class->SUPER::new(@_);
  
  # get test param
  $self->{test} = $self->params->[0] if defined($self->params->[0]);

  return $self;
}

sub get_header_info {
  return {
    RestTestPlugin => "Test"
  };
}

sub run {
  my $self = shift;

  my $value = $self->{test} || "Goodbye";

  return {
    RestTestPlugin => $value
  }
}

1;

