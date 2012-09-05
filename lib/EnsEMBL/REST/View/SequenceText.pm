package EnsEMBL::REST::View::SequenceText;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View';
 
sub process {
  my ($self, $c, $stash_key) = @_;
  $stash_key ||= 'rest';
  $c->res->body(${$self->encode_seq($c, $stash_key)});
  return 1;
}

with 'EnsEMBL::REST::View::SequenceRole';

1;
