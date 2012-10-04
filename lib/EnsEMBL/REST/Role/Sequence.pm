package EnsEMBL::REST::Role::Sequence;

use Moose::Role;
use namespace::autoclean;

use Bio::Seq;
use Bio::SeqIO;
use IO::String;
use XML::Writer;

use constant SEQXML_VERSION => 0.4;
use constant SCHEMA_LOCATION => 'http://www.seqxml.org/0.4/seqxml.xsd';
use constant XMLNS_XSI => 'http://www.w3.org/2001/XMLSchema-instance';
 
sub encode_seq {
  my ($self, $c, $key) = @_;
  my $s = $c->stash();
  my $ref;
  my $format = $s->{format};
  my $is_fasta_content = $self->is_content_type($c, 'text/x-fasta');
  my $is_seqxml_content = $self->is_content_type($c, 'text/x-seqxml+xml');
  
  if(!$format) {
    if($is_fasta_content) {
      $format = 'fasta';
    }
    elsif($is_seqxml_content) {
      $format = 'seqxml';
    }
  }
  
  if($format eq 'fasta') {
    $ref = $self->_fasta($c, $key);
  }
  elsif($format eq 'seqxml') {
    $ref = $self->_seqxml($c, $key);
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

sub _seqxml {
  my ($self, $c, $key) = @_;
  my ($stringfh, $w) = $self->_seqxml_writer();
  my $s = $c->stash();
  my $entity = $s->{$key};
  
  my $xsi_uri = XMLNS_XSI;
  my $seqxml_uri = SCHEMA_LOCATION;
  my $version = SEQXML_VERSION;
  
  $w->xmlDecl("UTF-8");
  $w->forceNSDecl($xsi_uri);
  $w->startTag("seqXML", [$xsi_uri, 'noNamespaceSchemaLocation'] => "${seqxml_uri}", 'seqXMLversion', $version);
  $w->startTag('entry', 'id' => $entity->{id});
  my $tag_name = { dna => 'DNAseq', protein => 'AAseq' }->{$entity->{molecule}};
  $w->dataElement($tag_name, $entity->{seq});
  $w->endTag('entry');
  $w->endTag('seqXML');
  
  return $stringfh->string_ref();
}

sub _seqxml_writer {
  my ($self) = @_;
  my $stringfh = IO::String->new();
  my $xsi_uri = XMLNS_XSI;  
  my %args = (
    OUTPUT => $stringfh, 
    DATA_MODE => 1, 
    DATA_INDENT => 2,
    NAMESPACES => 1,
    PREFIX_MAP => {
      $xsi_uri => 'xsi',
    }
  );
  my $w = XML::Writer->new(%args);
  return ($stringfh, $w);
}

with 'EnsEMBL::REST::Role::JSON';
with 'EnsEMBL::REST::Role::Content';

1;
