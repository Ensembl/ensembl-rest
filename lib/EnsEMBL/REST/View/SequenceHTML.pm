package EnsEMBL::REST::View::SequenceHTML;
use Moose;
use namespace::autoclean;

extends 'EnsEMBL::REST::View::TextHTML';

sub get_content {
  my ($self, $c, $stash_key) = @_;
  $stash_key ||= 'rest';
  my $ref = $self->encode_seq($c, $stash_key);
  return ${$ref};
}

with 'EnsEMBL::REST::View::SequenceRole';

__PACKAGE__->meta->make_immutable;

1;
