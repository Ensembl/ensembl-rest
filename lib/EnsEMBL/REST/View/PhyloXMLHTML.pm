package EnsEMBL::REST::View::PhyloXMLHTML;
use Moose;
use namespace::autoclean;

extends 'EnsEMBL::REST::View::TextHTML';
 
sub get_content {
  my ($self, $c, $stash_key) = @_;
  return $self->encode_phyloxml($c, $stash_key);
}

with 'EnsEMBL::REST::View::GeneTreeRole';

__PACKAGE__->meta->make_immutable;

1;
