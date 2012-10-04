package EnsEMBL::REST::View::NHXTree;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View';
 
sub process {
  my ($self, $c, $stash_key) = @_;
  $c->res->body(${$self->encode_nhx($c, $stash_key)});
  $self->set_content_dispsition($c, 'nhx', $stash_key);
  $c->res->headers->header('Content-Type' => 'text/plain');
  return 1;
}

with 'EnsEMBL::REST::Role::GeneTree';

__PACKAGE__->meta->make_immutable;

1;
