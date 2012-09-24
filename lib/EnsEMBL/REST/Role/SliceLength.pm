package EnsEMBL::REST::Role::SliceLength;

use Moose::Role;
require EnsEMBL::REST;

has 'max_length' => ( isa => 'Int', is => 'ro', default => sub {
  my ($self) = @_;
  my $cfg = EnsEMBL::REST->config()->{$self->length_config_key()};
  my $default = $self->default_length();
  return $default unless $cfg;
  my $max = $cfg->{max_slice_length} || $default;
  return $max * 1;
});

sub assert_slice_length {
  my ($self, $c, $slice) = @_;
  my $max_length = $self->max_length();
  my $slice_length = $slice->length();
  if($slice_length > $max_length) {
    my $msg = "$slice_length is greater than the maximum allowed length of $max_length. Request smaller regions of sequence";
    $c->go('ReturnError', 'custom', [$msg]);
  }
  return;
}

requires 'default_length';
requires 'length_config_key';

1;