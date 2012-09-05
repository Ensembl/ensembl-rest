package EnsEMBL::REST::View::SequenceRole;

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
  my $content = $c->request()->params->{'content-type'} || $c->request()->headers()->content_type() || q{};
  
  if($format && $format eq 'fasta') {
    $ref = $self->_fasta($c, $key);
  }
  elsif($content eq 'text/fasta') {
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

with 'EnsEMBL::REST::View::JSONRole';

1;
