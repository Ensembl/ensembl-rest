package EnsEMBL::REST::View::JSONTree;

use Moose;
use namespace::autoclean;
use JSON;
use EnsEMBL::REST::Builder::TreeHash;

extends 'Catalyst::View';
 
sub process {
  my ($self, $c, $stash_key) = @_;
  $stash_key ||= 'rest';
  my $gt = $c->stash()->{$stash_key};
  my $builder = EnsEMBL::REST::Builder::TreeHash->new();
  $builder->aligned(1) if $c->request()->param('aligned') || $c->request()->param('phyloxml_aligned');
  my $sequence = $c->request->param('sequence') || $c->request()->param('phyloxml_sequence') || 'protein';
  $builder->cdna(1) if $sequence eq 'cdna';
  $builder->no_sequences(1) if $sequence eq 'none';
  $gt->preload();
  my $hash = $builder->convert($gt);
  my $encode = encode_json($hash);
  $gt->release_tree();
  $c->res->body($encode);
  $c->res->headers->header('Content-Type' => 'application/json');
}

__PACKAGE__->meta->make_immutable;

1;