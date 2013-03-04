package EnsEMBL::REST::EnsemblModel::Endpoint;

use Moose;

has 'description' => ( isa => 'Str', is => 'ro', required => 1 );
has 'endpoint'    => ( isa => 'Str', is => 'ro', required => 1 );
has 'method'      => ( isa => 'Str', is => 'ro', required => 1 );
has 'group'       => ( isa => 'Str', is => 'ro', required => 1 );
has 'output'      => ( isa => 'EnsRESTValueList', is => 'ro', required => 1, coerce => 1);
has 'params'      => ( isa => 'HashRef', is => 'ro', required => 0 );
has 'examples'    => ( isa => 'HashRef', is => 'ro', required => 0 );

sub has_required_params {
  my ($self) = @_;
  my $p = $self->params();
  return 0 unless $p;
  foreach my $key (keys %{$p}) {
    my $value = $p->{$key};
    return 1 if $value->{required};
  }
  return 0;
}

sub has_optional_params {
  my ($self) = @_;
  my $p = $self->params();
  return 0 unless $p;
  foreach my $key (keys %{$p}) {
    my $value = $p->{$key};
    return 1 if ! $value->{required};
  }
  return 0;
}

1;