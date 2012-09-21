package EnsEMBL::REST::View::NHTree;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View';
 
sub process {
  my ($self, $c, $stash_key) = @_;
  $c->res->body(${$self->encode_nh($c, $stash_key)});
  $self->set_content_dispsition($c, 'nh', $stash_key);
  return 1;
}

with 'EnsEMBL::REST::Role::GeneTree';

__PACKAGE__->meta->make_immutable;

1;
