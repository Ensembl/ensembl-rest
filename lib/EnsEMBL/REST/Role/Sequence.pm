=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
Copyright [2016] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::REST::Role::Sequence;

use Moose::Role;
use namespace::autoclean;

use Bio::Seq;
use Bio::SeqIO;
use IO::String;
use XML::Writer;
use Bio::EnsEMBL::Utils::Scalar qw/wrap_array/;

use constant SEQXML_VERSION => 0.4;
use constant SCHEMA_LOCATION => 'http://www.seqxml.org/0.4/seqxml.xsd';
use constant XMLNS_XSI => 'http://www.w3.org/2001/XMLSchema-instance';
 
sub encode_seq {
  my ($self, $c, $key) = @_;
  my $s = $c->stash();
  my $ref;
  my $format = $s->{format} || '';
  my $is_fasta_content = $self->is_content_type($c, 'text/x-fasta');
  my $is_seqxml_content = $self->is_content_type($c, 'text/x-seqxml+xml');
  my $is_plain_content = $self->is_content_type($c, 'text/plain');
  
  if(!$format) {
    if($is_fasta_content) {
      $format = 'fasta';
    }
    elsif($is_seqxml_content) {
      $format = 'seqxml';
    }
    elsif($is_plain_content) {
      $format = 'plain';
    }
  }
  
  my $dispatch = {
    fasta   => '_fasta',
    seqxml  => '_seqxml',
    plain   => '_plain',
  }->{$format};
  
  $c->go('ReturnError', 'custom', ["The format '$format' is not understood"]) unless $dispatch;
  
  my $sequences = $s->{$key} || [];
  $sequences = wrap_array($sequences);
  return $self->$dispatch($c, $sequences);
}

sub _fasta {
  my ($self, $c, $sequences) = @_;
  $sequences ||= [];
  my $stringfh = IO::String->new();
  my $seq_out = Bio::SeqIO->new(
    -fh     => $stringfh,
    -format => 'fasta',
  );
  foreach my $entity (@{$sequences}) {
    my $seq = Bio::Seq->new(-ID => $entity->{id}, -MOLECULE => $entity->{molecule}, -ALPHABET => $entity->{molecule}, -SEQ => $entity->{seq});
    $seq->desc($entity->{desc}) if $entity->{desc};
    $seq_out->write_seq($seq);
  }
  return $stringfh->string_ref();
}

sub _seqxml {
  my ($self, $c, $sequences) = @_;
  $sequences ||= [];
  my ($stringfh, $w) = $self->_seqxml_writer();
  my $s = $c->stash();
  
  my $xsi_uri = XMLNS_XSI;
  my $seqxml_uri = SCHEMA_LOCATION;
  my $version = SEQXML_VERSION;
  
  $w->xmlDecl("UTF-8");
  $w->forceNSDecl($xsi_uri);
  $w->startTag("seqXML", [$xsi_uri, 'noNamespaceSchemaLocation'] => "${seqxml_uri}", 'seqXMLversion', $version);
  
  foreach my $entity (@{$sequences}) {
    $w->startTag('entry', 'id' => $entity->{id});
    my $tag_name = { dna => 'DNAseq', protein => 'AAseq' }->{$entity->{molecule}};
    $w->dataElement($tag_name, $entity->{seq});
    $w->endTag('entry');
  }
  
  $w->endTag('seqXML');
  
  return $stringfh->string_ref();
}

sub _plain {
  my ($self, $c, $sequences) = @_;
  $sequences ||= [];
  my $count = scalar(@{$sequences});
  my $stringfh = IO::String->new();
  foreach my $entity (@{$sequences}) {
    print $stringfh $entity->{seq};
    print $stringfh "\n" if $count > 1;
  }
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
