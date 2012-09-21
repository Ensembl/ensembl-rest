package EnsEMBL::REST::Role::Sequence;

use Moose::Role;
use namespace::autoclean;

use Bio::Seq;
use Bio::SeqIO;
use IO::String;
 
sub encode_seq {
  my ($self, $c, $key) = @_;
  my $s = $c->stash();
  my $ref;
  my $format = $s->{format};
  my $is_fasta_content = $self->is_content_type($c, 'text/fasta');
  
  if($format && $format eq 'fasta') {
    $ref = $self->_fasta($c, $key);
  }
  elsif($is_fasta_content) {
    $s->{fomat} = 'fasta';
    $ref = $self->_fasta($c, $key);
  }
  else {
    $ref = $self->_json($c, $key);
  }
  return $ref;
}

sub _json {
  my ($self, $c, $key) = @_;
  my $s = $c->stash();
  my $entity = $s->{$key};
  my $v = $self->json()->encode($entity);
  return \$v;
}

sub _fasta {
  my ($self, $c, $key) = @_;
  my $s = $c->stash();
  my $entity = $s->{$key};
  my $seq = Bio::Seq->new(-ID => $entity->{id}, -MOLECULE => $entity->{molecule}, -ALPHABET => $entity->{molecule}, -SEQ => $entity->{seq});
  $seq->desc($entity->{desc}) if $entity->{desc};
  my $stringfh = IO::String->new();
  my $seq_out = Bio::SeqIO->new(
    -fh     => $stringfh,
    -format => $s->{format},
  );
  $seq_out->write_seq($seq);
  return $stringfh->string_ref();
}

with 'EnsEMBL::REST::Role::JSON';
with 'EnsEMBL::REST::Role::Content';

1;
