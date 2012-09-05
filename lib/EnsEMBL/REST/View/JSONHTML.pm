package EnsEMBL::REST::View::JSONHTML;

use Moose;
use namespace::autoclean;

extends 'EnsEMBL::REST::View::TextHTML';

sub get_content {
  my ($self, $c, $key) = @_;
  my $rest = $c->stash()->{$key};
  my $encode = $self->json()->encode($rest);
  return $encode;
}

with 'EnsEMBL::REST::View::JSONRole';

__PACKAGE__->meta->make_immutable;

1;