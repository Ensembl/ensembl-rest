package EnsEMBL::REST::View::NHXTree;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View';
 
sub process {
  my ($self, $c, $stash_key) = @_;
  $c->res->body(${$self->encode_nhx($c, $stash_key)});
  $self->set_content_dispsition($c, $stash_key, 'nhx');
  return 1;
}

with 'EnsEMBL::REST::View::GeneTreeRole';

__PACKAGE__->meta->make_immutable;

1;
