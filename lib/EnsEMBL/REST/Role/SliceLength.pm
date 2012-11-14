package EnsEMBL::REST::Role::SliceLength;

use Moose::Role;

sub assert_slice_length {
  my ($self, $c, $slice) = @_;
  my $max_length = $self->max_slice_length() * 1;
  my $slice_length = $slice->length();
  if($slice_length > $max_length) {
    my $msg = "$slice_length is greater than the maximum allowed length of $max_length. Request smaller regions of sequence";
    $c->go('ReturnError', 'custom', [$msg]);
  }
  return;
}

requires 'max_slice_length';

1;