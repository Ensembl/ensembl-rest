package EnsEMBL::REST::View::PhyloXML;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View';
 
sub process {
  my ($self, $c, $stash_key) = @_;
  $c->res->body(${$self->encode_phyloxml($c, $stash_key)});
  $self->set_content_dispsition($c, 'xml', $stash_key);
  $c->res->headers->header('Content-Type' => 'text/xml');
  return 1;
}

with 'EnsEMBL::REST::Role::GeneTree';

__PACKAGE__->meta->make_immutable;

1;
