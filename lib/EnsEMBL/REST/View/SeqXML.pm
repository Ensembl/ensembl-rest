package EnsEMBL::REST::View::SeqXML;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View';
 
sub process {
  my ($self, $c, $stash_key) = @_;
  $stash_key ||= 'rest';
  $c->res->body(${$self->encode_seq($c, $stash_key)});
  $c->res->headers->header('Content-Type' => 'text/x-seqxml+xml');
  return 1;
}

with 'EnsEMBL::REST::Role::Sequence';

1;
