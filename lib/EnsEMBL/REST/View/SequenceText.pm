package EnsEMBL::REST::View::SequenceText;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View';
 
sub process {
  my ($self, $c, $stash_key) = @_;
  $stash_key ||= 'rest';
  my $seq = $c->stash->{$stash_key}->{seq};
  $c->res->body($seq);
  $c->res->headers->header('Content-Type' => 'text/plain');
  return 1;
}

1;
