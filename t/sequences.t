# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
# Copyright [2016-2025] EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use warnings;

BEGIN {
  use FindBin qw/$Bin/;
  use lib "$Bin/lib";
  use RestHelper;
  $ENV{CATALYST_CONFIG} = "$Bin/../ensembl_rest_testing.conf";
  $ENV{ENS_REST_LOG4PERL} = "$Bin/../log4perl_testing.conf";
}

use Test::More;
use Test::Deep;
use Catalyst::Test ();
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::SeqIO;
use IO::String;
use Test::XML::Simple;
use Test::XPath;

my $fh;
{
  local $/ = undef;
  my $seq_data = <DATA>;
  $fh = IO::String->new($seq_data);
}
my $io = Bio::SeqIO->new(-fh => $fh, -format => 'fasta');
my %seqs;
while(my $seq = $io->next_seq()) {
  $seqs{$seq->display_id()} = $seq;
} 

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new();
Catalyst::Test->import('EnsEMBL::REST');

# CDNA ID based lookup
{
  my $id = 'ENST00000314040';
  my $version = 1;
  my $url = '/sequence/id/'.$id.'?type=cdna;mask_feature=1';
  my $seq = $seqs{$id.'_cdna'};
  cmp_deeply(json_GET($url, 'GET sequence/id'),
    {
      seq => $seq->seq(),
      id => $id,
      desc => undef,
      molecule => 'dna',
      query => $id,
      version => $version,
    },
    'CDNA retrieval'
  );
  
  my $plain_text = text_GET($url, 'Plain text');
  is($plain_text, $seq->seq(), 'Plain text version brings back raw sequence unformatted');
}

# CDS ID based lookup
{
  my $id = 'ENST00000314040';
  my $version = 1;
  cmp_deeply(json_GET(
    '/sequence/id/'.$id.'?type=cds', 'CDS via sequence/id'),
    {
      seq => $seqs{$id.'_cds'}->seq(),
      id => $id,
      desc => undef,
      molecule => 'dna',
      query => $id,
      version => $version,
    },
    'CDS retrieval'
  );
}

# Protein ID based lookup
{
  my $id = 'ENSP00000320396';
  my $version = 1;
  my $seq = $seqs{$id.'_protein'};
  my $url = '/sequence/id/'.$id; 
  cmp_deeply(json_GET($url, 'protein via sequence/id'),
    {
      seq => $seq->seq(),
      id => $id,
      desc => undef,
      molecule => 'protein',
      query => $id,
      version => $version,
    },
    'Protein retrieval'
  );
  
  my $seq_xml = seqxml_GET($url, 'Protein sequence SeqXML retrieval');
  xml_is_long($seq_xml, '/seqXML/entry/AAseq', $seq->seq(), 'Protein sequence as expected');
  
  my $xml = xml_GET($url, 'Protein sequence basic XML retrieval');
  my $tx = Test::XPath->new(xml => $xml);
  my $count = 0;
  $tx->ok('/opt/data', sub {
    $count++;
    my $node = $tx->node();
    is($node->getAttribute('seq'), $seq->seq(), 'XML Protein sequence as expected');
    is($node->getAttribute('molecule'), 'protein', 'XML Protein molecule as expected');
    is($node->getAttribute('id'), $id, 'XML Protein ID as expected');
  }, 'Asserting <data> XML entity');
  is($count, 1, 'XML Should only have 1 <data> entity');
}

# Gene genomic DNA
{
  my $id = 'ENSG00000176515';
  my $version = 1;
  my $seq = $seqs{$id.'_genomic'};
  cmp_deeply(json_GET('/sequence/id/'.$id, 'dna via sequence/id'),
    {
      seq => uc($seq->seq),
      id => $id,
      desc => ($seq->desc ? $seq->desc : undef),
      molecule => 'dna',
      query => $id,
      version => $version,
    },
    'Gene genomic DNA retrieval'
  );
}

# Gene to protein
{
  my $id = 'ENSG00000176515';
  my $version = 1;
  my $protein_id = 'ENSP00000320396';
  my $seq = $seqs{$protein_id.'_protein'};
  
  my $base_url = "/sequence/id/${id}?type=protein";
  my $single_json = json_GET($base_url, 'Accept Gene -> Protein without multiple_sequences on if 1 sequence is available');
  is($single_json->{seq}, $seq->seq(), 'Checking sequence is fine and no array is present');
  
  cmp_bag(json_GET(
    $base_url.';multiple_sequences=1', 'Multiple sequence fetch'),
    [{
      seq => $seq->seq,
      id => $protein_id,
      desc => ($seq->desc ? $seq->desc : undef),
      molecule => 'protein',
      query => $id,
      version => $version,
    }],
    'Gene to protein sequence retrieval with multiple sequences on'
  );
  
  my $multiple_transcript_gene_id = 'ENSG00000112699';
  my $base_multi_url = "/sequence/id/${multiple_transcript_gene_id}?type=cdna";
  action_bad_regex($base_multi_url, qr/multiple_sequences/, 'Genes with more than one sequence are rejected without multiple_sequences on');
  my $json = json_GET($base_multi_url.';multiple_sequences=1', 'Getting multiple_sequences JSON');
  is(@{$json}, 10, 'Expect 10 CDNAs linked');
}

# Gene to protein text/plain multiple sequences (with and without param)
{
  my $id = 'ENSG00000112699';
  my $url = "/sequence/id/${id}?type=protein;content-type=text/plain";
  action_bad_regex(
    $url,
    qr/multiple_sequences parameter"}/, 
    'Error when querying for text/plain sequence with a gene and asking for protein'
  );

  # Now for the good version. Check we have 2 sequences returned each on their own line
  my $text = text_GET($url.';multiple_sequences=1', 'Retriving multiple sequences in text/plain');
  my $fh = IO::String->new($text);
  my @rows = <$fh>;
  close $fh;
  is(scalar(@rows), 2, 'Expect 2 lines of text coming from the service') or diag explain \@rows;
}


# DNA Region; good
{
  my $region = '6:1080164-1105181';
  my $seq = $seqs{6};
  
  cmp_deeply(json_GET(
    '/sequence/region/homo_sapiens/'.$region, 'DNA via region'),
    {
      seq => uc($seq->seq),
      id => $seq->desc,
      molecule => 'dna',
      query => $region,
    },
    'Basic genomic DNA retrieval'
  );
  
  my $small_region = '6:1080164-1080464';
  my $seq_hm = $seqs{'6_hm'};
  cmp_deeply(json_GET(
    '/sequence/region/homo_sapiens/'.$small_region.'?mask=hard', 'Hard-masked sequence via region'),
    {
      seq => $seq_hm->seq,
      id => $seq_hm->desc,
      molecule => 'dna',
      query => $small_region,
    },
    'Hard masking genomic DNA retrieval'
  );
  
  my $seq_sm = $seqs{'6_sm'};
  cmp_deeply(json_GET(
    '/sequence/region/homo_sapiens/'.$small_region.'?mask=soft', 'Soft-masked sequence via region'),
    {
      seq => $seq_sm->seq,
      id => $seq_sm->desc,
      molecule => 'dna',
      query => $small_region,
    },
    'Soft masking genomic DNA retrieval'
  );
}

# DNA via Exon id in FASTA
{
  my $id = 'ENSE00001271861';
  my $url = "/sequence/id/${id}";
  my $fasta = fasta_GET($url, 'Getting ENSE00001271861 in FASTA');
  my $expected = <<'FASTA';
>ENSE00001271861.1 chromosome:GRCh37:6:1080164:1080229:1
CCTCAAATAAGAGCCACAAACGTGGAAGATATATCCAAAGGAACCAAATTAAAGGACTGG
AGAAAG
FASTA
  is($fasta, $expected, 'ENSE00001271861 FASTA formatting');

}

# CDS via Exon id in FASTA; bad
{
  my $id = 'ENSE00001271861';
  action_bad_regex(
    '/sequence/id/'.$id.'?type=cds',
    qr/can not be use when retrieving an Exon/,
    'Attempting to get CDS on an Exon, that doesn\'t make sense'
  );
}

# protein via Exon id in FASTA; bad
{
  my $id = 'ENSE00001271861';
  action_bad_regex(
    '/sequence/id/'.$id.'?type=protein',
    qr/can not be use when retrieving an Exon/,
    'Attempting to get protein on an Exon, that doesn\'t make sense'
  );
}

# DNA Region; bad
{
  my $region = '6:1..30001';
  action_bad_regex(
    '/sequence/region/homo_sapiens/'.$region,
    qr/greater than the maximum allowed length/,
    'Exceed max allowed length'
  );
}

# DNA region FASTA
{
  my $region = '6:61..122';
  my $url = "/sequence/region/homo_sapiens/$region";
  my $fasta = fasta_GET($url, 'Getting 62 bp of sequence');
  my $expected = <<'FASTA';
>chromosome:GRCh37:6:61:122:1
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NN
FASTA
  is($fasta, $expected, 'FASTA formatting');
  
  my $expanded_fasta = fasta_GET($url.'?expand_5prime=60;expand_3prime=60', 'Getting 182 bp of sequence');
  my $expanded_expected = <<'FASTA';
>chromosome:GRCh37:6:1:182:1
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NN
FASTA

  is($expanded_fasta, $expanded_expected, 'FASTA formatting with 5 and 3 prime extensions');
}

{
  my $url = "/sequence/id/";
  my $body = q/{ "ids" : [ "ENSP00000370194", "ENSG00000243439" ]}/;
  my $seq_a = q/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXISFDLAEYTADVDGVGTLRLLDAVKTCGLINSVKFYQASTSELYGKVQEIPQKETTPFYPRSPYGAAKLYAYWIVVNFREAYNLFAVNGILFNHESPRRGANFVTRKISRSVAKIYLGQLECFSLGNLDAKRDWGHAKDYVEAMWLMLQNDEPEDFVIATGEVHSVREFVEKSFLHIGKTIVWEGKNENEVGRCKETGKVHVTVDLKYYRPTEVDFLQGDCTKAKQKLNWKPRVAFDELVREMVHADVELMRTNPNA/;
  my $seq_b = q/GCCAGCCAGGGTGGCAGGTGCCTGTAGTCCCAGCTGCTTGGGAGGCTCAAGGATTGCTTGAACCCAGGAGTTCTGCCCTGCAGTGCGCGGTGCCCATCGGGTGACACCCATCAGGTATCTGCACTAAGTTCAGCATGAAGAGCAGCGGGCCACCAGGCTGCCTAAGAAGGAATGAACCAGCCTGCTTTGGAAACAGAGCAGCTGAAACTCCTGTGCCGATCAGTGGTGGGATCACACCTGTGAGTAGCCACGCCTGCCCAGGCAACACAGACCCTGTCTCTTGCAAAATTAAAAA/;
  my $response = [{"desc" => undef,"id" => "ENSP00000370194", version => 4, "seq" => $seq_a,"molecule" => "protein", query => "ENSP00000370194"},{"desc" => "chromosome:GRCh37:6:1507557:1507851:1","id" => "ENSG00000243439", version => 2, "seq" => $seq_b,"molecule" => "dna", query => "ENSG00000243439"}];
  cmp_bag(json_POST($url,$body,'POST sequence/id'),$response,'Basic POST ID sequence fetch');

}
{
  my $url = "/sequence/region/homo_sapiens";
  my $body = q/{ "regions" : [ "6:1507557:1507851:1", "clearly stupid" ]}/;
  my $expected = [{id => "chromosome:GRCh37:6:1507557:1507851:1",seq => "GCCAGCCAGGGTGGCAGGTGCCTGTAGTCCCAGCTGCTTGGGAGGCTCAAGGATTGCTTGAACCCAGGAGTTCTGCCCTGCAGTGCGCGGTGCCCATCGGGTGACACCCATCAGGTATCTGCACTAAGTTCAGCATGAAGAGCAGCGGGCCACCAGGCTGCCTAAGAAGGAATGAACCAGCCTGCTTTGGAAACAGAGCAGCTGAAACTCCTGTGCCGATCAGTGGTGGGATCACACCTGTGAGTAGCCACGCCTGCCCAGGCAACACAGACCCTGTCTCTTGCAAAATTAAAAA",molecule =>"dna", query => "6:1507557:1507851:1"}];
  cmp_bag(json_POST($url,$body,'POST sequence/region'),$expected,'POST one good region request and one bad');

}

# Sub-sequence testing
{
  my $id = 'ENSG00000243439';
  my $url = "/sequence/id/$id?start=10&end=30";
  my $fasta = fasta_GET($url, 'Getting 20 bp sub-sequence');
  my $expected = <<'FASTA';
>ENSG00000243439.2 chromosome:GRCh37:6:1507566:1507586:1
GGTGGCAGGTGCCTGTAGTCC
FASTA
  is($fasta, $expected, 'Genomic 20bp sub-sequence');
}
{
  my $id = 'ENSG00000243439';
  my $url = "/sequence/id/$id?end=30";
  my $fasta = fasta_GET($url, 'Getting genomic sub-sequence without start parameter');
  my $expected = <<'FASTA';
>ENSG00000243439.2 chromosome:GRCh37:6:1507557:1507586:1
GCCAGCCAGGGTGGCAGGTGCCTGTAGTCC
FASTA
  is($fasta, $expected, 'Getting genomic sub-sequence without start parameter');
}
{
  my $id = 'ENST00000314040';
  my $url = "/sequence/id/$id?start=25000";
  my $fasta = fasta_GET($url, 'Getting transcript sub-sequence without end parameter');
  my $expected = <<'FASTA';
>ENST00000314040.1 chromosome:GRCh37:6:1105163:1105181:1
CTGTTGCTTCACACTCCCG
FASTA
  is($fasta, $expected, 'Getting transcript sub-sequence without end parameter');
}
{
  my $id = 'ENST00000259806';
  my $url = "/sequence/id/$id?type=protein&start=200";
  my $fasta = fasta_GET($url, 'Getting protein sub-sequence from transcript without end parameter');
  my $expected = <<'FASTA';
>ENSP00000259806.1
SPPPAAAAAAAAAPETTSSSSSSSSASCASSSSSSNSASAPSAACKSAGGGGAGAGSGGA
KKASSGLRRPEKPPYSYIALIVMAIQSSPSKRLTLSEIYQFLQARFPFFRGAYQGWKNSV
RHNLSLNECFIKLPKGLGRPGKGHYWTIDPASEFMFEEGSFRRRPRGFRRKCQALKPMYH
RVVSGLGFGASLLPQGFDFQAPPSAPLGCHSQGGYGGLDMMPAGYDAGAGAPSHAHPHHH
HHHHVPHMSPNPGSTYMASCPVPAGPGGVGAAGGGGGGDYGPDSSSSPVPSSPAMASAIE
CHSPYTSPAAHWSSPGASPYLKQPPALTPSSNPAASAGLHSSMSSYSLEQSYLHQNARED
LSVGLPRYQHHSTPVCDRKDFVLNFNGISSFHPSASGSYYHHHHQSVCQDIKPCVM
FASTA
  is($fasta, $expected, 'Getting protein sub-sequence from transcript without end parameter');
}
{
  my $id = 'ENSP00000259806';
  my $url = "/sequence/id/$id?type=protein&start=10&end=30";
  my $fasta = fasta_GET($url, 'Getting protein sub-sequence from translation feature with start and end');
  my $expected = <<'FASTA';
>ENSP00000259806.1
APLRRACSPVPGALQAALMSP
FASTA
  is($fasta, $expected, 'Getting protein sub-sequence from translation feature with start and end');
}
{
  my $id = 'ENSP00000259806';
  my $url = "/sequence/id/$id?type=protein&start=30&end=30";
  my $fasta = fasta_GET($url, 'Getting single bp protein sub-sequence from translation feature');
  my $expected = <<'FASTA';
>ENSP00000259806.1
P
FASTA
  is($fasta, $expected, 'Getting single bp sub-sequence from translation feature');
}
{
  my $id = 'ENST00000400701';
  my $url = "/sequence/id/$id?type=protein&end=200";
  my $fasta = fasta_GET($url, 'Getting protein sub-sequence from transcript without start parameter');
  my $expected = <<'FASTA';
>ENSP00000383537.3
XSNLKRDVAHLYRGVGSRYIMGSG
FASTA
  is($fasta, $expected, 'Getting protein sub-sequence from transcript without start parameter');
}
{
  my $id = 'ENST00000400701';
  my $url = "/sequence/id/$id?type=protein&start=10&end=10";
  my $fasta = fasta_GET($url, 'Getting protein sub-sequence from transcript with length 1bp');
  my $expected = <<'FASTA';
>ENSP00000383537.3
K
FASTA
  is($fasta, $expected, 'Getting protein sub-sequence from transcript with length 1bp');
}
{
  my $id = 'ENSG00000112699';
  my $url = "/sequence/id/$id?type=protein&multiple_sequences=1&start=150000";
  my $fasta = fasta_GET($url, 'Getting protein sub-sequence from gene, using multiple');
  my $expected = <<'FASTA';
>ENSP00000436726.1
ISFDLAEYTADVDGVGTLRLLDAVKTCGLINSVKFYQASTSELYGKVQEIPQKETTPFYP
RSPYGAAKLYAYWIVVNFREAYNLFAVNGILFNHESPRRGANFVTRKISRSVAKIYLGQL
ECFSLGNLDAKRDWGHAKDYVEAMWLMLQNDEPEDFVIATGEVHSVREFVEKSFLHIGKT
IVWEGKNENEVGRCKETGKVHVTVDLKYYRPTEVDFLQGDCTKAKQKLNWKPRVAFDELV
REMVHADVELMRTNPNA
>ENSP00000370194.4
ISFDLAEYTADVDGVGTLRLLDAVKTCGLINSVKFYQASTSELYGKVQEIPQKETTPFYP
RSPYGAAKLYAYWIVVNFREAYNLFAVNGILFNHESPRRGANFVTRKISRSVAKIYLGQL
ECFSLGNLDAKRDWGHAKDYVEAMWLMLQNDEPEDFVIATGEVHSVREFVEKSFLHIGKT
IVWEGKNENEVGRCKETGKVHVTVDLKYYRPTEVDFLQGDCTKAKQKLNWKPRVAFDELV
REMVHADVELMRTNPNA
FASTA
  is($fasta, $expected, 'Getting protein sub-sequence from gene, using multiple');
}
{
  my $id = 'ENST00000259806';
  my $url = "/sequence/id/$id?type=protein&end=100";
  action_check_code($url, 400, 'Return code for out of boundaries parameters should be 400');
  action_raw_bad_regex($url, qr/not within the sequence/, 'There\'s no protein sequence contained in the genomic boundaries given');
}
{
  my $id = 'ENSG00000243439';
  my $url = "/sequence/id/$id?start=1000&content-type=application/json";
  action_check_code($url, 400, 'Return code for out of boundaries parameters should be 400');
  action_raw_bad_regex($url, qr/not within the sequence/, 'Start of sub-sequence range can not be beyond the sequence length');
}
{
  my $url = "/sequence/id/?start=120&end=150";
  my $body = q/{ "ids" : [ "ENSP00000370194", "ENSG00000243439" ]}/;
  my $seq_a = q/LAEYTADVDGVGTLRLLDAVKTCGLINSVKF/;
  my $seq_b = q/TGCACTAAGTTCAGCATGAAGAGCAGCGGGC/;
  my $response = [{"desc" => undef,"id" => "ENSP00000370194", version => 4, "seq" => $seq_a,"molecule" => "protein", query => "ENSP00000370194"},{"desc" => "chromosome:GRCh37:6:1507676:1507706:1","id" => "ENSG00000243439", version => 2, "seq" => $seq_b,"molecule" => "dna", query => "ENSG00000243439"}];
  is_json_POST($url,$body,$response,'POST ID sequence fetch with sequence trimming');

}
done_testing();

__DATA__
>ENST00000314040_cdna
cctcaaataagagccacaaacgtggaagatatatccaaaggaaccaaattaaaggact
ggagaaagtctaggtgagatggctttgtcccgttgcaggcgagttccaagcacagaga
accaaatggtttccacagagaacatgtgtagaagggattgtaacccacaactgtctga
acccaagcactaagcttcaaaccagactctgtgctgcttctgctttatacacaggccc
tggctgaaaacccttgactttaccaggcatgcaaggagATGCTAAGTCCACTTTGGCT
GCAGATCTCTAAACGACCACGGCCCGAAGTGTCAGTTTCAAATGCTTGTTTCAGCTCT
GCCCTCCCCACATCAAATCCCACCTCTCTCACGCTAAAGCATCATAATATATTTGTGC
TGAGAGTTGCCTTAGAAATCATTCAGTATTCAGTTCACGGGGGAAGAAACAGAAAGCC
CCTAGAGGTGACCTCATTAGCCTACAGTTGCCCTGAGAACTGGTGGCAGAAGCAGATT
GGTGTCCAGCCTCCTGATGTACATGCCAGTGCTCTTTCCCCCAAGCCATGTGTCTCCT
GGTCACGCCCTTTGTCCTTGCTGTCCTCTACTATTCTCTTCTGGAAGACTCACGATGA
GAGAGCCGACTTCTCCAAGCTGCACTCCTAGctctctgggacccagcagggaccgctg
ccttccagccagcagtttgaagaaggacagctaccatcaaacacagacttacagcctc
cctgatgccctggatgccaggaaatgtctggaccagtcaagataagagcaaggcagag
ccaggaagaaatggggacaggagttcctatttaaatatataaagaatcctttcctagg
tagagaaaagtcatctagcaatgtgactgatcacctctccgtttatctgtttgatcaa
ctggaatttctatacagaaggtttatacaaagaagccacaaacaaccattgtcacaat
gacccctacataattccttgtgtaaatgctctggaaatgcacccagaagtctggagaa
ggtccaatcaaactgggtggcaggaagaagcaagctctgttctcagatcttcaacaga
atcacctggaccctggggttgccaccacgctaagccaaggaggcctctgaatgcacgg
gagtgcagggtctgaagggagttgttaaaaggtgtttcttgatccaggaccatgtaaa
gacccaggagaaataggtatcccaaagagaacagcgtataagattcacaaaccaatga
caaacacgctgggttcgctgctggtctccacagttggttggttctgtagggctcagct
gcctctttctctctacttctggtttcagaaaacacgagagagaagccgagtgctcatg
gagtttcctcaaagactcagcaaaaactaggctttgtgttctgagatcaggaagtaac
agtgagagtccaaaattttcttccctgacaatgtctcctactcaagcagggcctggaa
gtcaccccctagaatcaaagccttgacatatgcaagctcatagtttattgcttcttct
cccatctgcccgttgacagataaatcccagagggaataaaaacacattgccctcagca
gattattcttcactgaagaataccagtcttttaacactccgctacagaaatagctttc
tgccggctgatggcttgttgcgctgcactaagagagcccgcacacctcgaagcttcgt
caagcaaagcctatgatttcacagacccagaaatgttttctttctctaagccaataac
atatgcttgggtttatgccaactctaccagaggcgcacagatacaatgaggcatgaag
ttcagaataatagaaagtagagagttggaaagcacaggagaacccatctagaccaacc
tgttttgttgaaaaaggagctccctgacccagagaggttaagggtttgctgtgagacg
gtgcccctggttaaaggcagcatgagatgctgtcctctgatccccagcttcctagggc
tcttgcctctaggtcacactgccttgaggccaggagctgatattgattgaacagatgt
gaaaacagaagaaaaaaaaattgtggtgactgccctctgacaattttccactttcttt
ggaccaattttctttgccattatctggaaaaaaaaaaaatgtccagaagagcatttta
aattcaggaagtggttctggaactaggagaagacacaccttgatgacagtaatattgt
ctaagtgagaaggaacaagctcttgaatgtttctagaaaaaccaaatatgataggaga
ccataaaattatacttcgtcatatggatttccagtttgagaaaacttagtggctaaac
aaaggtgccgcttgagagatgcagacagaaatcagcctctgctttaagaacaagttgc
tacgctgaagaatgagaagaggaatggggcccagaggctgaaggtctggaccaatctc
ccttcccagataagcgcctggaccctcgttcctcagaagccacgtgtaattaccagct
ctttttggctacagagcacatgcccaggaggcttggagaagcaggaatttaaaacatg
ctagtttcagagccaagattggtgacaacaccatcagttactgtttgggcttcgggaa
gccgtgggctgcagcactgggtctggtgtcctgggctgtgtgggacctcagcaaggtt
gtttcctgaaatgaaagctcctcttctgggggatgacacaccaggaccacctgcagat
gatgtttatgaatcccccagcaggggtggattgatcttacaatgggactgtgtaatat
aaacatttcattattctacaaaagaatacacacaataccacctaagggtctctaagaa
tagggttggagagtgacaatgagaaaatgccactcaaaaagaaatagagccgcattcc
ttctacacaacattaatattaactttacatacaggggaaaaaaatggcattttacctt
aagagttatttgtaaactctctccacaccatgagataaaatcagtgcagagctcagag
ctctgaatttcctcatttgggggctaatagactttaatgggggctcttcttggcatgc
aaatgaacgtgtgtgtctctgagtgcatgtgtctgtgtgtgtacacacgtccctttga
agtttatttacttggtagcactaattgtaaaagggcacacccaggggaatttaatgag
gcgacatgctagaatatagacattagaaagggaattaatattttcctcataatagcaa
gtaggtgaagtcaagtatgaggacagaaggaaagaaaaaggaaggcagggaaagaggg
aaggagaggagaggaacaggttttgatgatcgtagataagaaccaataaacactgttg
cttcacactcccg
>ENST00000314040_cds
ATGCTAAGTCCACTTTGGCTGCAGATCTCTAAACGACCACGGCCCGAAGTGTCAGTTTCA
AATGCTTGTTTCAGCTCTGCCCTCCCCACATCAAATCCCACCTCTCTCACGCTAAAGCAT
CATAATATATTTGTGCTGAGAGTTGCCTTAGAAATCATTCAGTATTCAGTTCACGGGGGA
AGAAACAGAAAGCCCCTAGAGGTGACCTCATTAGCCTACAGTTGCCCTGAGAACTGGTGG
CAGAAGCAGATTGGTGTCCAGCCTCCTGATGTACATGCCAGTGCTCTTTCCCCCAAGCCA
TGTGTCTCCTGGTCACGCCCTTTGTCCTTGCTGTCCTCTACTATTCTCTTCTGGAAGACT
CACGATGAGAGAGCCGACTTCTCCAAGCTGCACTCCTAG
>ENSP00000320396_protein
MLSPLWLQISKRPRPEVSVSNACFSSALPTSNPTSLTLKHHNIFVLRVALEIIQYSVHGG
RNRKPLEVTSLAYSCPENWWQKQIGVQPPDVHASALSPKPCVSWSRPLSLLSSTILFWKT
HDERADFSKLHS
>ENSG00000176515_genomic chromosome:GRCh37:6:1080164:1105181:1
CCTCAAATAAGAGCCACAAACGTGGAAGATATATCCAAAGGAACCAAATTAAAGGACTGG
AGAAAGgtaagaaagggactatgcttcttatgagttttattttcctcagttacattgttt
taacttattttatgttcgagggtacatgtgcaggtttgttacataggtaagcccgtgtca
cgagggtttgtcgtacagattctttcatcccccaggtactaaacccagtactcaacagtt
atcttttttgcccctctccctcctctcaccctccaccctcaacagtgtctgttgtttttt
aaataaaacttgcacttctatccctaagtattttctgacgttgctgcccaggacccctgg
gtagcttttagactggatgagcaaagaccagactgaataactaagtttctcctgcaagcc
aatgggcctggcccgggacgtggaatccactgactttctcttcctatcagcaactttccc
cacaacgctgatggatctggaaccacttctaaacccgctgcctgtttgcgaggagggcag
accactgacggtgggaaggatgcatttccccaagccacggaccacactgccgaggccctg
actgtcctttcccggacccctgcctggcacgcctgggaaaggtttaccctgggggcgggg
gcaggttggcgccaggcagcttgcagaatgtgtgctcggaccccgggcatcgcgaagtgt
gcgggccgtgggccccggctgcaccgccagcccctgcctggccaccccaccgcttacttg
acctccaggaagcgcctgaaagaaagcgagctctgatatgtgcagctccagtgtgtttca
ataagctgttttcaaagagtttgggtgcctcttcagactaagcccgttcgaaacctccat
cttctttctagggttttcttcaacgggggcttagatgataaacggagacccctgttccct
accggttgaaactgtgtctgcggcaacagtaagcacccggccgagacacccacaccccca
tgtcgtgcgctcaggaccagggagcatggcgcatcacggccagcctattgccaagcaggt
tcctgagctgtgtaaggtcatgactctgaatttctgttgcaaacatttcagactgtgaaa
ctctaagagatataaaagactaggggagagggaaccaagcgaaaggggaaaaggtgttaa
tatttacctccattatcatgaagagattatcctgccctctggtacactgggacatggtaa
ttgctcaagggtttaactctttttcttaatgtgaagtaccagtacgaaccagttttgagg
tgtttgcattaaaactgctctgccatttgaaaaatctgatcaagagatcccagctgctca
gctggtggaaagaaccccgagttcatgaaattattagggtaatctaaatgaagcttaata
gcacttagcacttcaaagcacactgagcacattaactaattaatcgcagccttacccctt
caaggtacataaatggctattatcctcactttacagttgggataaatgagacctaggtaa
gcaggagtagttgccctgggtcccgaatgaagtcaatagctccagtaaaggcaaaatcgg
acatttcggagtcgcccgtcttggctgcctatctgctcttcttcccacattttctttcct
tctagagcttggctgaaaagcttcacatttggatttggagagatttcaaatctttttcct
acatatgactgtttatgacatagatactttaaaaccaagggagtccaaactgattaaagt
tataacaaattggaatgctggaaagtgcatgtcatcagccaaggaaagaggttagtctga
ttaaataatcagtttcatctgggtctgtttatgccatctgttgcaaaatgttttccaaat
tgtgtagtgtgcatgcaggatctcacagaataggaatatcaagtgttataacaaaagtaa
tatgttcttacttttcctaaaaaaaaaaaatgtaaatctttcccaatgtccctatgatat
aaaacacgcatggcaacgacatcataacacaatactcagaaaattgtagccgcctttaac
catgacatttccccaaattaataactgcacactaacgactgtgtaataaatctgtaaact
ttttcagcattgctacttcttcagcactagacctgattgtttctaaaacctctgagacat
ataacttctgataaagggaataatttttctggcaaaggaaatattagaacaggaagtgag
tcttgaagttcctggcttcaatccattaaggtgacaggcaagaaatctgaaggcagagaa
atgaagcaacaagaacaaggattctggtcccctcgttctcaagccactgcttacacagat
agaagggaagctgattaccatgtgcacgaggcctgtcatttcacagacggtaatctgagg
cagaaccaggagcaggacccaggcgtcctggttctcaggttgatgctgtttccattccac
tctgccctgctggctttgtaattccttttcctttatttgatttagtgaattgttcatttc
atttcatggtttgcttgagtgccttccccaaaacaccaccgtaagtaaatcattgcaaag
tggataatattttctcatgggaacaatgataaaaatcagggatttatttctaatcaagga
ggcagcatcaaacagatcctatacatgagcaacaccagtcataaggcagggattaagcaa
ccacaaacctcaatgacctcatgtgtaaagtaggcataatagagggatatctctcaagac
actgaaggattaatgcagacaacgtgggcaaagcactgggcgcagatcctggcagttagc
aagggcttgggaagcaccggactctctcactcgctgtgagttatgcattggcactcacat
gttttgttggcttataatcctcgcacggtgttaaaacctaggtgctgtcattatgcccac
tttacaaatgaggaaacagaggcccggggatgcaaagtaccttgttagaggctacataac
caggaagcaaccaaccaagatggcatttcaccccagatgatttgacttcagggtctgtgc
tttgaactcttatttcacacatatagttgacatataataaatactgttaatattatcact
tcacttaaatagatgagttattatctgtatcacatagagtagatgtactatgaccattat
ttcccaaaggcctcattttactataaagtaagcaaaacacatgaaaatagatgccaattg
agcatcaaggtggccccaaactaattttcaggagttttctgtccaataactgagaggcgc
tttatacaatgtatgacccatagtatcataacatactactgtacaagaaaattggagctc
atttcctttttttttttctgaataaatttcttactcaacaggcatcatctaaaaatactg
tgtgtggctggtgctccatactggctgctattgttaagaaggacatttgagcgggcgttt
tgctggtgaaaagcatgtgtgtgtgtttgtttgttagttaattgtgaaatattgaaagtg
tatagaaaaagttagaaaatacagtaatgcactcacatatacttcccactcagcattgtc
aaaccgtaacatttgatacatttcaatgttgtttcactgaaacacagggaaaaagaatag
aggggaaattccttaacctggaaaacacagctacaaaaattccacaattgggcccagcgt
ggtggctcacgcctgtaatcccagcactttgggaggctgaggcgggcggatcacctgagg
tcaggagctcaagaccagcttggccaacatggtgaaaccccatttctactaaaaatacaa
aaaaattagccaggcatggtggcacatgcctgtaatcccagctatttgggaggctgaggc
aggagaaccagttgaacccgggaggcagaggttgcagtgagccgagatcgtgccattgca
ctccagcctgggcaacaaaagtgaaactccgtctcagaaaaaaaaaaggaaaagaaaatt
ccacaattaaccacacccttcgtgtgtcatattctttaaagctgaaaacaagacagacat
gcccaccttgcctcctgtgtgcagggactggacttgggggacctgacaaagatgagaaaa
cgaatagggcaaggatcccaaaggaaactatggaactgtcatcattccatccggggtggt
ggtgggtttcgttgttaacttctgatttaactggatattagctggagaatctagtgcgta
ctaattcttgtattttgtcttgttttgtttttctggggatggaatctcactctgttgccc
aggctggagtgcagtggtgcaatctcggctcaccgcaatctctgcctcccaggttcaagc
aattctcctgcctcagtctcctgagtagctggaactacaggcgcccaccaccacgcccgg
ctaattttttgtgtttttagtagaggtggggtttcaccgtgttagccaggatggtctcga
tctcctgacctcgtgatctacccgcctcagcctcccaaagtgctgggattacgggtgtga
gccaccacacttggccctaattcttgtttgttattgagatttacattcaggctagttctt
ggtcaattttaggcaacgtcccgtgggggcttgactagaatgtgtgtattctactagggg
aatgcagaattgcctatatacagttaatagcgtcaactttgttagttgcatagctagaaa
cagcatagaaatgcgcttgctgtgctctaaaacctttcattgctaatgaatgaaggggat
agattgtataacatcacacttaggagtgtgctgtgtgccagatcatacacaccccagaag
gcccaaattgtcactgactgtccctctcttgagcatgggacatcgccaagaaggaattac
tccatatccaaataagccacatgatcatagaactaatttgttcctttgggtggttgaatt
tcctctatagagatcccaggaggcaacatgaatccctccagggctggactgcacagcctc
cattgataccctccagtgacggggcacttggcctctggtgacacgtcccctgggaatggg
aacttactctgtcatctttcaaaccaccttaagtggctccagaagggccaggacaaaatc
cttgacttttttttttttctggcattatttgccaattcctttaacaaatattaatcaagc
acctgctgttctagccccttggagtaaacagtgagcaaagctttgaggtgccttccctca
cagagtttattataatttagggataactaagttagtagtttttccattttctccttgtaa
gcctgtcaagttttgctttaaatacattgagatgatgttactagggttgaaagaaaatag
aattgcctattttcttattgtttagtgccttaaaaattcttaataatgatgttttaccat
aatgttaagcttgttatgaatatagcttcccagctcttctgaatctgcatagttcacctc
cacgtgctgcagggccattgacgagaattcccgggggagacttttgtccactcccagtcc
agaaaaggcagaaaggcccagtgttaccatagctgtttgatgggaggcgtttcctttatg
ctgctcgctcactgagacagcaatccctaatggccctggtgagaggcaggattcaagcac
ggttctcagcgcccacctcgcttacgctgagcggctgcaagcccaagctctacgtccctg
ggatgccacccacccacccccagcctgcctcagcctatgggctcctttttctattctgat
cccggaagcagcccatacttttttgcaagctcagctccacatttaaaaagatgtttgctt
ccgtctcccatgctttgtcctggacatgcagtgagtgagagtgaagcttgcgtcttctct
gtagacccagccatgttgcttccttccttttctcagcttattttctccatggagctggcc
ccaaggtgccatgagcctgagacttaggagaaagtaaaaggcaccactgaagactaaatc
taggctacgtgctgcagctgagattggaacctgtgcttagatgtgaacttccacatgggt
gcttccttgaagagttgagcactcattcagacctttataaattgccagatccattgagtt
taccagcctctctgagatcacaggctcaggaatcagatgactgggtttcaaatcctacca
cttactagctaacttgtctgtgtcttcaacttcctcatctctaactaaacatagtaattc
ctaacttatacatttgctgcaaggatggggctcaatgggcactgggatagattctacaac
accacatagtgcaaactaaggaatggcatttactggggaaatttagaaactaggagtcag
gccccaaaggcataggggtctccatcttctcataatcctatggaaaactgaaccaatgca
aagacaaagctctttgccatgcagtgggctgcagtcctgacctgagtgtcctatctcctc
gaaggatgaacacgaacaccactttccagtaaggagacagggggaccactcgattgccag
gccgtcggggtctagatgccagcagagctgagaaggcatctgaggaaggccagctgcctg
gcacccagggaacatgggtcctggggagaggggcagctctcctcttggggaatgtttgcg
gctggtcctgtgggaaactgagtttaggtgcacatcctccttcgaggaggcggggaaact
ccagttccagccagctcatttcctagatcatgtagactgagatctcaggatcattttttg
aatagttctgcttgttggcccatggagaattaagcaaaataaagcacataaagtagttag
tatagtatctaacaagtgctcactatatattaactgttattgttttaaaaggatgtttgc
taacattttcctagcgcttagagatatctggatttggagaggtttcagattacttatcca
cagcatttctggaaccagagggctttcctgagaagcgtttgtaaaagcaggaacaactta
acttttcttaccttcagtctctctcttctaagtttagtcaaagctagactcaggatcaac
cctccacatccaaatgtcctaggtcatttgggacctggttaaagggggcttcaaatcacc
ttgtccacacttgctgtggcaggcagagtttagcagcttgaggaagctgaggcctgaagt
attttggtttatcaggtaactctgaaccttgaaaacgccaaacatgcagattgcctgtgt
gcatttcatactcccctgcaaagcagctcctcgcttcacaggaagaggcggaacttaaat
ccaaatacagttacagtgtttatatcctgggctgcactagttaaaaagaacctaagattt
atggctcttttagatcacagaaccaaatcccaatacctcctgtcagatcttctctccttc
cagaagcaagtatttggggattataaaaagtgatgttatggatgatgtctcttaaaatat
cagatcgacttgatggcaggacctgctgttcaaatttctttagagacacctcctcgctgc
cccgcccttgcctctctcccgacgagtgccagcccatgcgcacacacgcacaggtgtgtg
cccaaccatgtgacttccctgctacctccagactaagcgggcatttcctttacatgtgct
gttttctctgctattgtctccttccatcatccttttattttaacatatgtttactaaatg
ccattgttctagaaacattgaggcatataaaagtgaataaaaccagcaaataaattccca
tcctcggccaagcgcggtggctcatgcctgtaatcccagcactttgggaagccgaggcag
gcggaccacctgagatagggagctcacgaccaacctggctaacatggcaaaaccccgttt
ctactaaaaataccaaaaattagccgtgtgtggtggtgggcacctgtaatcccagttact
caggaggctgagacaggagaatctcttgaacccaggaggcggaggttgccgtgagctgag
attgtgccactgcactccagcctgggagacagagggagactccgtctcaaaaaaaaaaaa
aaaaatccccatccctaaggaccctatattccagtggctagtcatcattactgctaccgt
ccattgagtatctgctgtataccaggctcggttctagctgctttacctatacattatttc
taatttgcataacttctctgaaagttgaattatcagcccatctaacagatgaagaagttg
agtctcacaaaaattaataaagccccaaaagtgattcaaagctacattccaaagtctttg
ctcctttcctgccaaggtggaaatctttcacctgaaccaaacaagtgtcttgctgacctg
tgaaacccttaccctccctcctccacccctgtacctcccacatatctgcactgcagttct
gagcttctcaccatggtaacctgtggacacaccagtccctctctgagctactgaaggtac
agaccatattctactcatcgtggtttcatcagtgtttggcacagtacaagatcaaattaa
aataagcagatcctgaattgctaaatgaatgttccttatatagtgcttactcagctttta
gatttattgccatctctacttctgtaccatctgcagggacgccgcccgttgaggtggtag
agattggcttaaggttgtacaaacagagattggaaacttctttccctgacttgttctcat
tttactgtcatatttgccaataagcacttaaaatgccaactcacacagctgggtggaata
tcttaaggaaagtaaatgagacagtgtatacatgtaagatgatatacaataaaagatgat
acggagtaatgtgaaaacaaaagatagtattattactgttgtttaagcaagcctcaggcc
ttttagctagcaaagcttcatccagtaactgctcactttgtcttaagcactgtagtttta
ttctgaatgaaaaatatatttacatacctcctcttaaaatcatagttcaagtttaattct
caagatcaagatttattctgcttaataaaactcatttctaatttttttctaacctaataa
ctggtgttctaaatgctaatcttcttagaatgcacttctcctcaaatccaatgtgtcgcc
tctcccagtgaatcactggcttagaaataatgatggcaaacctatattacatgcttaata
ggtgccaggcacccttgtaaatacttttcaagtgctatcctctttgaattccaaattcgt
aatttaggcactattattattcccatttcaaagattaggaaataaatgacaagaggcata
agatgcctaagaggccacacatccgctaagtgacagggactcgatctgaacccaggaaag
ctcattctggagcccacatttttatttttgaatgactttagtttcttttcaacataggta
acacatcacctggtttaaaaaaaaattctagaaggcatgctgtaaggagtcttgcttcta
ctctggtcctgcctgttttctctttgcccactcctgaccccaactctaatacgcagttga
caacttttagtagtttctggaatatacctttggagattttaatgaaaatgcaagcacatg
caaatatatgctttttgtttcttctaccttccttccacaaaatgtagtatgctctacaca
cctttttttctctgttatttatatatctcatagctctttccatagcaggatacaaatcct
tctcattcttttatgctgcatattctgtcacatgactgtgtcatgatttaaccagttcag
gattgatggacactttcagttcttgtctattcacacagtacagtcatgaatgatcttgat
gttcatcttttcctatgtgtaagtgtatctgttgggtaaatttccagaggtggtacttcc
aggttgaaagattcttgatttttcagcttttatgatttcgtaacattcctggatttccct
tcaattagcacattttcctgcagattgtgtaaacatctatttattcttatggcctcatct
gcagaatgtgctgtcacactttgaatttttgcccattttataggtgataaaagatattct
cattgaattcacatttatcttattatggatgaggttgaacaccttctcatacatttaggg
cttgtttattatattttataaataagctattctaccctttgacaatttttcaattggttt
gttggttttttacttagtgaaactagagatattcttttaactattttgcagtagtgattc
ccaagaaagagtgaagacattaataaaggaaattgccataaacacaataggttatcaaaa
ttgttttaggtacaagttaaaagacttctctggttacttttgactttaaactctatcata
tgaaataatgtatatcaaaagttctacaaactctagtctgttagttattcattattatta
ttttttttatttttatttttttgagatggagtctccctctgtcacccaggctggagtcca
gtggctcgatctcagctcactgcaagcactgcctcccaggttcacgccgttctcctgcct
cagactcccgagtagctgggactacaggcgcccgccaccacgcccggctaattttttgta
tttttagtagagacggggtttcaccgttttagccaggatggtctcgatctcctgacctcg
tgatccgcccacctcggcctcccaaagtgctgggattacaggcgtgagccaccgcgccca
gctggttattcattattataatagacaaaacatttagagatgataatgtaaaactctaaa
tagctaagattcagaccccaagaatttcactaacaacaggtcattgatctactctaagaa
cctttcatctgtactcaactgatcagtgaccttttcaataatgagaaaataaaaaaaatt
aaaagccttttcttctgtcatatttcctgaagtgtgtgacaattagttttagtctagatc
tctcaaatacgatgccatttttcttttttaaagcactcacaggactcattaacaatcaac
agatcatctccttagaaacataggctcaggagttacccatagaaaccatcctaacccttt
agagtatttctatctgcaacacccagattttaggcaactggttgtcttggactgtaagtg
ctcaaatctgtacaaaacatttttaatttccactccttagtgtatcttttttttttgaga
tggagtctcgctctgttgcccaggttggagtgcagtggcatggttgtggctcacctcaac
ctccgcctcccgggttcaaccaattctcctgccacaacctccagagtagctgggattaca
ggaacctgccatcacgcccggctaatttttcgtatttttagtagagatggtgtttcacca
tgttggccagactggtctcaaactcctgaccttgtgatccgcccgcctcggcctcccaaa
gtgctgggattacaggtatgagccactgtgcccggccaggtatatctttacaatgtgtaa
gtttctaacctttccccttttccctggtctggggaaaggtagaggctggttccagagctg
atcccagggcctttgtgagctcagatatgcagtaatggcataggaccatctgccaggtca
aggtgtttgctgcctctgtggttatttggttataaagagccagcaaagccaggagacctc
tctgaaaaagatacacatagagcctaatatgtgaagtcgtttatattttgtatgaataaa
catacttaatacacatttacacatacatactaaacgcagtatgaaccaaatgcttacagg
agacagggcatgtgtatgggcataagactttggagagaaactctgaagtccacagaaccc
tcccatgggtcaagatcaaatgcctaccagatgctcagagcctccagtaaatccagtcag
agctggatttgagtagaagattcccttttatgcacaactgctgacataagtggcgtgaca
cttccttatttatgtctggagtttactgccctttgagtttattgcctaatacagcatggc
cacagaatgtctttttcaacgcaaaggcctataattctattacaagaacaccttggggat
attgtgggttcagttctagaccatcacaataaagcaaatattgcaataaagcaagtcaca
caaattttggtgtttcccagtgcatataagagttatgtttatgctatactgtagtccttt
aagtgtgtaatagcattatgtttaaaaacacaatagtgtgaaaaaacccgcaatatctgc
aaagcacaataaagcgaactgcagtaaaataaggtatgcctgtatattttttaaatgcac
ttgagcctttctaacccctttgagaattaagaagcagtttgcacaccctctgcaatctaa
aatggatcccacatctatgcacacacatgcaggactaggttcatgtattgtataacccac
acagtcaagtcctgcaagattcaataaaaacctgtagtcaggttcattctatttcagatg
cagaaattgtttgtaatgaatgaaaaatgaacactattagccacgtgcttttataattca
ctagataacatatgaaaccactaatgttgtccactaacgatgactaccatcatgaccaac
acaacaaaaccagaaacagtatttcctcctttttttttttttttttttgagacagtcttg
ccaccaggctggagtgcagtagcactatttcggctcactgcaacctccgcctcctgagtt
caagtgattctcctgcctcagcctctggagtagctgggattacaggcacccgccactata
cccagttaatttttttgtacttttagtagagatgggatttcatcatgttggccaggctgg
tctcgaactcctgatctcgtgatacacctgccttggcctcccaaagtgctgggattacag
gcatgagccaccgcgcccggcatatttcctcctttttacattgtactttcatagctgatt
ctcccctttcaacccaaaatgcaaacacaggctttaagagatttcatttcatttcagaat
gagctgtgacctggaggcccaaccaaaggcaggcttgttgcccagtgctatggagacagt
agacttggggatgtccttccataccatttatcctgatggcctgaaacaaaagcacatcac
catatccttttgatcacagcatagatggaatacaaaagatgacctccaagactccgcctg
accttgctccacctacctccccagcctctcccacccaactctccccaacacctctggggt
ccagacacaagagccttccttcagttctgcaaacacaccccacttctcccactcacagcc
acctcagcatcaccgcaggatgttgctgaatttacaatcgcctcctccctctctctcccc
tcccaggagcctttgctttgcctagctaacatccacaggattgcagatggcttgtcactt
tctccaagaatccttccttgaccccccgatttctcctcatgggacttaataacttggtgt
ctgaattccctgctagaatgccagctctatgagggcagagacagactttgtcttatccct
gccacatccccggcagctagcacagagaagggagcaaatgtccggtgagagaattatgag
tgtgaccctgacatgggctgtgtcttactgtctgtgccacgccgtctgcccagtgtaaat
gctaaagaaatgtttgccgagtgaatgaatggatgaatcaatgagttgttaaaaaaaaaa
actgttcacatcaacacaatttagcattaaaatactcactataaatcataaatattatta
tttttatcatttaagttctattcaagtgtttttcccccacatagtttcttagaaatttta
tggccaaaaaaacaattctcaggctaggcgtggtggctcatggctgtaatcccagccctt
tgggaggccaaggcgggaggatcacctgaggtcaggagttcgagaccagcctggccaaca
tggtgaaaccccgtctctactaaaaatacaaaaattagccaggtgtgatggcagccgcct
gtaatcccagctattcaggaggcaggagaatctcttgaacctgggaggcagaggttgcaa
tgagctgagattgcaccactgcactacagcctgggtgagagagcgagattctgtccccca
aaaaacaaaaaacaaagaacaacaattctgggatgcctgaaaaatgctccagcccacaga
aagtgaactgggaatctttttaagggtaggtatcatttctcccaggactagagtcctttt
aagtgactcatagttcccaagatctgagaggcttctcttttggccctgtctcatgaccca
tttctgaacatctgtgttgattttttctttctttttttaaaatctatttggctcagtgct
taagataaatgagaagtttcacattctaccctaaaggctaatagaatctggctgtactgg
attgcaattcaagagtccagtgatgtggcttctcctaagaaaataccctttctcctagaa
tcccagggacctatgagcaaaacctccaggattcaaagtctgagtttaaagagagaaatt
tttcacacacacaccatccaaaacaatcctacacacacccaacaagcacacagcacccaa
aagtaaaccctccacacacccaacatgcacccacacccaattctcacaaacaacccaaca
cacacatgcaacacctgcatatgcgacacacatagaacacacactgtacctgcaatcccc
accctcacatacgcaaccctccacacccccggcacacacaccacacacacaccggggcct
gacactcctcagtcctgagccgagggtctcctggaggcccagcttctctcttctttccct
accccattccatcatctcatccaggccctattggaggcaatttgcccttattctaaaagt
tattttagttttgattacggaagacttgaaagtaatgtcagttcttagaaaaattctaat
gaaaggctgggcaaggtggctcatgcctgtaatcccagcactttgggaggccgaggcaga
cagatcacctggggtcaggagtttgagaccagcctggccaaccaacatggtgaaaccctg
tttctactacaaatacaaaaaattagccaggcgttgtggcacacacctgtaatcccagct
acttgggaggctgaggcaggagaatcacttgaactcgggaggcagaggttgcagtgagcc
aagatcataccactgcactccagcctgggcgacagagggagactctgtctcaaaaaaaaa
aaaaaaaaaatttccaatgaaagcaaatcaggggtttggcctcctggtggcttttgggtg
cttgtcttggagatagcagttggataccacagcaaattggctgtggattatttagtagtt
cttatttttcatacaactgcctctgttgcccactttcttcattttttcttaccaaatggt
agaattgcccttctcaccttctaccgttatgtcctcctatcaggaaagcaaactagtgca
ttaaaccaccgtgatcaccaccacaaacctgtgaatgggggaaggaacccttttctccat
gaggacatgaaagtggagggaggttaggcggtgcacattgccccaaatcttccagtgaag
aaggatcccaagagaatggaaaggtggtctccttttttgacacccacactcctctgtccc
cacacggcccactgggctctgcacgactgctgtgtccaaagcattgtcccctgcagaagt
tgcgccagtcctccctccacctcttgctgcactcagacaggaaggcagtgaagccagaca
ggaaggcagtgaagccagacaggaaggcagtgaagccagacaggaaggcagtgaagccag
ccacgccagcctcagagcaggcactgagggcactgacgctcaccctggccctgcagaatc
tgtggaggagaggctgtgggtccacccttgtcttctgcttatcccagttgtcctacctca
tctcttcttttaatttctattatggaaagttcctaacaggaacaaaagtgcagagaatta
tattaaaaattcccacgtgcccattgcctgccttcaacaataaacgccttgtagctaaat
ttattattttgcattcctgagctcacttactcccgtgaattattttgaagcacatttgga
aaatcatgttaatctgtaattaaaaaaatatataacatcaaaaggcatggacgactccct
tttaaaaataaccgcaataccgtcaccacacacagaaaattaagatttctttaatgtcaa
cacctatgctatctgtgtttgccttcctccaacagtctcatgaacattttaagatttgct
tgcctgaactgggatcccaacgaggtctacactttgttctgaactcatgcatcccttaag
tgtctcactctaccagtttactctacatctcttccagactccctcaattttcttcttctt
cttgaaaaaaatattgcttgtcctgtctgaattttgctgattgcatctttgtgttcttct
atcccttttattttctgcaaattggtagttatatctggagggttgcctgagttcagtttt
ggtgtctttggtaagaatccttcgtaggtggtgttgaatgtggactttcattgggaggca
cagaaggtctggttgtctcccttttggggtgatggttgcccggagtatggtttactctta
actcctgtaatgtaaagggagggaggaaggaagaaaggaggaaggaaggaaggaaggagg
gaaaaaaggaaggaaggaaaaaaggaaggaaggaaaaaaggaaggaaggaaggcaggcag
gaaggaaggacctgtcagcctgctgcttgcctgaatgtgactgaccacggccccaggtgg
tggagctgccaccttccctgtctgcttgcccccaggaccaccactttcaccgaccacact
cagaatcagtgagcccctctgcagtgcctgccttgtctgggctgaccaccttcagtgcca
gagctgagccagagacttggccattttcgggagtgccataaggattattttgacactttt
gtccggcataatagttgcttttaggtaagatgatttgtcagcctcctccttctgtcgtgc
tggaagtgactcttctcaagtatttttgtcagcctctgagtaacagtaaagcccactcta
gcgtagcaaggatgagcagagccagattctgggttggcatgaagggtttaaagagagtga
ggttgagtgagctcccctggcccacagagcaaggttgacaaaggaaggaaaggccctgtg
gtgtggccccagtgaagggcaccagcgccgcctctggatctctgtgtcctcacctctggg
gtaagggcatgcttccctctggggtggatgtggctgacagcagatgccctgtcatggctc
ttgcctcagctgtgcgtgtccccatctttcctgtcctgaggccagactcataggtaaaac
cgggtctcaggcatctctccaggagggttgatgggacactgcaagctccttggccccgcc
agggctgtcttcccccagctttcagtgggtagtgacggccccgtgaccatcactgcatcg
ggggggagttgaccccgccagggctgtcctctcccagctttcagtgggtagtgacggccc
tgtgaccatcactgcagaccccgccagggctgtcctctcccagctttcagtgggtagtga
cggccccatgaccatcactgcactggggacgcttgaccctgcagtggctttagggcttcc
agcttaaacacagtcaaaaagcgaaaggtctagtcaccagaagacaacatttgacagtag
tagaaatcacaaccaaacattgtgctgttgtacaattgttatttgtcaattacaaaataa
tattaaaaaataaaaaaccccaaaacattgtactagccattagaaaatcattcctgacat
ccattacctgccaaaacagagtcatatctgtcctaaacatagcataacttagcttctaat
tttttctaagggagaaaataataatgggattctgtacaaaaaaaaatgttaaatatggac
tgggaactaactcacctttttaatctcaatctccaaggtcatctaattgtaaatagaatt
ttctaaactttggtagaacacaggacacattggtaattttcaatgtaattaaagttttcc
tgatttttttaaacttagaactgtttattaatttaaatgatcactaatattttatttaaa
atatctttaaaatgagtcaagggttttgcacttttctccagcacaactctagtttattta
tttgccaatccttttctgtttaaaccatttgtaattcttttttgcttaactcattcaaca
ggcagcatgaaggatcacaaaacaaaaattgttctaaatacttatttaaaatatcttttt
cacttacaaacaatgtctgtgaaattcttaattaatacaaacaagaatctaactaataat
gattcaaactctcactattacgctaggtgattttttttttactgtgttgaaattgcatta
tataatttaagttggacaaccaagacatttcatttttgatgttgattacaactttcaaaa
ttcgcaatctactaacataatttatttatattgacttaatgtaagtaaatcagttgtgcc
tttgaaaatgctacattgttcataaatgaataccaagcttatgcatagctatgtacaggg
aggtgaaaaatattcatcttctctgatattaacagacagttaaatacagtactatccttc
tcctatatatcatcactcaaatagctgtttcctatggagtcctagccaagctaagggaaa
aagaaaatatattgacctctaagatacacgtcagttgaatcagaactgtgtagtagtaga
atgcttggcaaatacaatgatttgtagaatacattgatacatattgtgaagtggttgaga
gacagccagcagttgccacagctgccaaactccagaagaaggctggtgttggtgcagggc
agagcttagggcgaaatgtggtgggctggggacaacacggaggagggagatttttctatt
cagtgcccagttgactccaccgctgagggccagtatagtgaagttaaaaaccagtttcac
acactgtgatgaaattctataaactcaggattatcctgtcaaatcaagatgacatgcgtc
ccattgtttaaaaacattctaatggatggaacttagcaaatactgctaagaacagaacca
gccgggctatgctgcagcgtctcagacatgtttccactcgctgctgcgatgtgtttgtca
aagagtttacttagagagctgcagagctatcagagaggagaagagaagcgcttcgccctc
acttgaagaacagtaactgcagtcaagcagaagacacttcaaacaaacaaacagacagac
agacagacagatctccccactcattctactggtcttgtgcttacctttcatttttcttgg
cctcttgcttcccctctctctgatggcatcttaaaggactcaatgttgaaatggtagcag
gcagcagcccatctgaaggtagcattagcatttgagaggaaagatcttgaggactgagtg
tgcttagccactgtgcacctcgaacctgcattgttcctcggttttcctatggagaaggat
ccccctgtgtgggactggcatcctctgaggactgcaggactgtacctgggtgatgagaaa
ggaagccaaggccatagcactataattgcagtgctctgccttaaagtccagcctcgagcc
tgcggctcgattttccagtaagctgagagcatggagaacaccagaaagccatttcggttt
ctgcttatttcttctctacagattttgagggttgaaaaagcacattccagaaaaggcagt
ggaaaattctaaaataaaagtgaggcagaatcagagtgaggggcatgttgagaatgcccc
taccatcttgaacggagcaaaagatggctcatatgttgacagctcccaatcccccacttc
tggagcagattttccagggggaaggacattacagagtccagatgcctcttccatgattcc
agcacctctaatgttgtaaggccgtgttatgagcaccctaaagatggcacttcagcacac
agttctcgaaattctgaccattctatcttcttttaaatccctctgtttttccaaatccta
aagccctgtgacacaccagcagccggtaagcgtctttcgagagaaggagcaggccagcag
ggcccccacatcttctttcctcagcttcatcccagatgcctggtactgtctcaagactgc
aggcactgaaacgtgaccccggtgtctcaggctgaaacagcaaactcccaaccgagtttt
aaattctcaacaatttgtggaaattatgagatttttatgagcatgtattttacaggactt
cctagaatgcctttttgagaaccctggaaggggaggaaggaaatatcaccctaggggaag
cagaattaaatgtgtactctctcctgtctctctttttctctccttccttccagcccattg
agaaatctacaagccatccatcgtctgaccccgtaaatttgtctttctgaggtaataaga
tgacacagcctttgccaggtcagatgctactttcataaaaagtgctgagttggtgaccca
atgccgtgaataaggatataatcaaatttcatatttcttccttgagcttcagcaatgacg
cccacttttcatggattgttactcagggaggacgcataaatgcctctcagaatcacctaa
ttcaatcttcataacaacagTCTAGGTGAGATGGCTTTGTCCCGTTGCAGGCGAGTTCCA
AGCACAGAGAACCAAATGGTTTCCACAGAGAACATGTGTAGAAGGGATTGTAACCCACAA
CTGTCTGAACCCAAGCACTAAGCTTCAAACCAGACTCTGTGCTGCTTCTGCTTTATACAC
AGGCCCTGGCTGAAAACCCTTGACTTTACCAGGCATGCAAGGAGATGCTAAGTCCACTTT
GGCTGCAGgtaagaattaagtaggactaacctgggtgttactaataaggagttcaaccag
ggcccagcaatcaaggagggcttcgtggaagaggtggaacttggagtggcctggaagaat
cgcatagaatcagcaaaaccatggaaacgacaatgagcagggaacacacacaggtcccac
tgtgacagaatgcacatgggtgatgagcagacatgtcctcagatgggtaggcaggaccct
ggaaaacaggaaatggagtctgtgtttgacagcagaagcaacggcaaccactgtcatctc
attcattcatttaataattgtttattgagggtatcatgtcaggtgcagttcttagtgata
gtgacctagcagtgagtaagccaggctgagtccctgccctcaaaaacctcaagatccagt
agtgggccagatggacattcatgatgtttaatagatcaagtagagttccccttcattgat
atctatttctaaagatgtctgtcttcccttctaacagATCTCTAAACGACCACGGCCCGA
AGTGTCAGTTTCAAATGCTTGTTTCAGCTCTGCCCTCCCCACATCAAATCCCACCTCTCT
CACGCTAAAGCATCATAATATATTTGTGCTGAGAGTTGCCTTAGAAATCATTCAGTATTC
AGTTCACGGGGGAAGAAACAGAAAGCCCCTAGAGGTGACCTCATTAGCCTACAGTTGCCC
TGAGAACTGGTGGCAGAAGCAGATTGGTGTCCAGCCTCCTGATGTACATGCCAGTGCTCT
TTCCCCCAAGCCATGTGTCTCCTGGTCACGCCCTTTGTCCTTGCTGTCCTCTACTATTCT
CTTCTGGAAGACTCACGATGAGAGAGCCGACTTCTCCAAGCTGCACTCCTAGCTCTCTGG
GACCCAGCAGGGACCGCTGCCTTCCAGCCAGCAGTTTGAAGAAGGACAGCTACCATCAAA
CACAGACTTACAGCCTCCCTGATGCCCTGGATGCCAGGAAATGTCTGGACCAGTCAAGAT
AAGAGCAAGGCAGAGCCAGGAAGAAATGGGGACAGGAGTTCCTATTTAAATATATAAAGA
ATCCTTTCCTAGGTAGAGAAAAGTCATCTAGCAATGTGACTGATCACCTCTCCGTTTATC
TGTTTGATCAACTGGAATTTCTATACAGAAGGTTTATACAAAGAAGCCACAAACAACCAT
TGTCACAATGACCCCTACATAATTCCTTGTGTAAATGCTCTGGAAATGCACCCAGAAGTC
TGGAGAAGGTCCAATCAAACTGGGTGGCAGGAAGAAGCAAGCTCTGTTCTCAGATCTTCA
ACAGAATCACCTGGACCCTGGGGTTGCCACCACGCTAAGCCAAGGAGGCCTCTGAATGCA
CGGGAGTGCAGGGTCTGAAGGGAGTTGTTAAAAGGTGTTTCTTGATCCAGGACCATGTAA
AGACCCAGGAGAAATAGGTATCCCAAAGAGAACAGCGTATAAGATTCACAAACCAATGAC
AAACACGCTGGGTTCGCTGCTGGTCTCCACAGTTGGTTGGTTCTGTAGGGCTCAGCTGCC
TCTTTCTCTCTACTTCTGGTTTCAGAAAACACGAGAGAGAAGCCGAGTGCTCATGGAGTT
TCCTCAAAGACTCAGCAAAAACTAGGCTTTGTGTTCTGAGATCAGGAAGTAACAGTGAGA
GTCCAAAATTTTCTTCCCTGACAATGTCTCCTACTCAAGCAGGGCCTGGAAGTCACCCCC
TAGAATCAAAGCCTTGACATATGCAAGCTCATAGTTTATTGCTTCTTCTCCCATCTGCCC
GTTGACAGATAAATCCCAGAGGGAATAAAAACACATTGCCCTCAGCAGATTATTCTTCAC
TGAAGAATACCAGTCTTTTAACACTCCGCTACAGAAATAGCTTTCTGCCGGCTGATGGCT
TGTTGCGCTGCACTAAGAGAGCCCGCACACCTCGAAGCTTCGTCAAGCAAAGCCTATGAT
TTCACAGACCCAGAAATGTTTTCTTTCTCTAAGCCAATAACATATGCTTGGGTTTATGCC
AACTCTACCAGAGGCGCACAGATACAATGAGGCATGAAGTTCAGAATAATAGAAAGTAGA
GAGTTGGAAAGCACAGGAGAACCCATCTAGACCAACCTGTTTTGTTGAAAAAGGAGCTCC
CTGACCCAGAGAGGTTAAGGGTTTGCTGTGAGACGGTGCCCCTGGTTAAAGGCAGCATGA
GATGCTGTCCTCTGATCCCCAGCTTCCTAGGGCTCTTGCCTCTAGGTCACACTGCCTTGA
GGCCAGGAGCTGATATTGATTGAACAGATGTGAAAACAGAAGAAAAAAAAATTGTGGTGA
CTGCCCTCTGACAATTTTCCACTTTCTTTGGACCAATTTTCTTTGCCATTATCTGGAAAA
AAAAAAAATGTCCAGAAGAGCATTTTAAATTCAGGAAGTGGTTCTGGAACTAGGAGAAGA
CACACCTTGATGACAGTAATATTGTCTAAGTGAGAAGGAACAAGCTCTTGAATGTTTCTA
GAAAAACCAAATATGATAGGAGACCATAAAATTATACTTCGTCATATGGATTTCCAGTTT
GAGAAAACTTAGTGGCTAAACAAAGGTGCCGCTTGAGAGATGCAGACAGAAATCAGCCTC
TGCTTTAAGAACAAGTTGCTACGCTGAAGAATGAGAAGAGGAATGGGGCCCAGAGGCTGA
AGGTCTGGACCAATCTCCCTTCCCAGATAAGCGCCTGGACCCTCGTTCCTCAGAAGCCAC
GTGTAATTACCAGCTCTTTTTGGCTACAGAGCACATGCCCAGGAGGCTTGGAGAAGCAGG
AATTTAAAACATGCTAGTTTCAGAGCCAAGATTGGTGACAACACCATCAGTTACTGTTTG
GGCTTCGGGAAGCCGTGGGCTGCAGCACTGGGTCTGGTGTCCTGGGCTGTGTGGGACCTC
AGCAAGGTTGTTTCCTGAAATGAAAGCTCCTCTTCTGGGGGATGACACACCAGGACCACC
TGCAGATGATGTTTATGAATCCCCCAGCAGGGGTGGATTGATCTTACAATGGGACTGTGT
AATATAAACATTTCATTATTCTACAAAAGAATACACACAATACCACCTAAGGGTCTCTAA
GAATAGGGTTGGAGAGTGACAATGAGAAAATGCCACTCAAAAAGAAATAGAGCCGCATTC
CTTCTACACAACATTAATATTAACTTTACATACAGGGGAAAAAAATGGCATTTTACCTTA
AGAGTTATTTGTAAACTCTCTCCACACCATGAGATAAAATCAGTGCAGAGCTCAGAGCTC
TGAATTTCCTCATTTGGGGGCTAATAGACTTTAATGGGGGCTCTTCTTGGCATGCAAATG
AACGTGTGTGTCTCTGAGTGCATGTGTCTGTGTGTGTACACACGTCCCTTTGAAGTTTAT
TTACTTGGTAGCACTAATTGTAAAAGGGCACACCCAGGGGAATTTAATGAGGCGACATGC
TAGAATATAGACATTAGAAAGGGAATTAATATTTTCCTCATAATAGCAAGTAGGTGAAGT
CAAGTATGAGGACAGAAGGAAAGAAAAAGGAAGGCAGGGAAAGAGGGAAGGAGAGGAGAG
GAACAGGTTTTGATGATCGTAGATAAGAACCAATAAACACTGTTGCTTCACACTCCCG
>6 chromosome:GRCh37:6:1080164:1105181:1
CCTCAAATAAGAGCCACAAACGTGGAAGATATATCCAAAGGAACCAAATTAAAGGACTGG
AGAAAGgtaagaaagggactatgcttcttatgagttttattttcctcagttacattgttt
taacttattttatgttcgagggtacatgtgcaggtttgttacataggtaagcccgtgtca
cgagggtttgtcgtacagattctttcatcccccaggtactaaacccagtactcaacagtt
atcttttttgcccctctccctcctctcaccctccaccctcaacagtgtctgttgtttttt
aaataaaacttgcacttctatccctaagtattttctgacgttgctgcccaggacccctgg
gtagcttttagactggatgagcaaagaccagactgaataactaagtttctcctgcaagcc
aatgggcctggcccgggacgtggaatccactgactttctcttcctatcagcaactttccc
cacaacgctgatggatctggaaccacttctaaacccgctgcctgtttgcgaggagggcag
accactgacggtgggaaggatgcatttccccaagccacggaccacactgccgaggccctg
actgtcctttcccggacccctgcctggcacgcctgggaaaggtttaccctgggggcgggg
gcaggttggcgccaggcagcttgcagaatgtgtgctcggaccccgggcatcgcgaagtgt
gcgggccgtgggccccggctgcaccgccagcccctgcctggccaccccaccgcttacttg
acctccaggaagcgcctgaaagaaagcgagctctgatatgtgcagctccagtgtgtttca
ataagctgttttcaaagagtttgggtgcctcttcagactaagcccgttcgaaacctccat
cttctttctagggttttcttcaacgggggcttagatgataaacggagacccctgttccct
accggttgaaactgtgtctgcggcaacagtaagcacccggccgagacacccacaccccca
tgtcgtgcgctcaggaccagggagcatggcgcatcacggccagcctattgccaagcaggt
tcctgagctgtgtaaggtcatgactctgaatttctgttgcaaacatttcagactgtgaaa
ctctaagagatataaaagactaggggagagggaaccaagcgaaaggggaaaaggtgttaa
tatttacctccattatcatgaagagattatcctgccctctggtacactgggacatggtaa
ttgctcaagggtttaactctttttcttaatgtgaagtaccagtacgaaccagttttgagg
tgtttgcattaaaactgctctgccatttgaaaaatctgatcaagagatcccagctgctca
gctggtggaaagaaccccgagttcatgaaattattagggtaatctaaatgaagcttaata
gcacttagcacttcaaagcacactgagcacattaactaattaatcgcagccttacccctt
caaggtacataaatggctattatcctcactttacagttgggataaatgagacctaggtaa
gcaggagtagttgccctgggtcccgaatgaagtcaatagctccagtaaaggcaaaatcgg
acatttcggagtcgcccgtcttggctgcctatctgctcttcttcccacattttctttcct
tctagagcttggctgaaaagcttcacatttggatttggagagatttcaaatctttttcct
acatatgactgtttatgacatagatactttaaaaccaagggagtccaaactgattaaagt
tataacaaattggaatgctggaaagtgcatgtcatcagccaaggaaagaggttagtctga
ttaaataatcagtttcatctgggtctgtttatgccatctgttgcaaaatgttttccaaat
tgtgtagtgtgcatgcaggatctcacagaataggaatatcaagtgttataacaaaagtaa
tatgttcttacttttcctaaaaaaaaaaaatgtaaatctttcccaatgtccctatgatat
aaaacacgcatggcaacgacatcataacacaatactcagaaaattgtagccgcctttaac
catgacatttccccaaattaataactgcacactaacgactgtgtaataaatctgtaaact
ttttcagcattgctacttcttcagcactagacctgattgtttctaaaacctctgagacat
ataacttctgataaagggaataatttttctggcaaaggaaatattagaacaggaagtgag
tcttgaagttcctggcttcaatccattaaggtgacaggcaagaaatctgaaggcagagaa
atgaagcaacaagaacaaggattctggtcccctcgttctcaagccactgcttacacagat
agaagggaagctgattaccatgtgcacgaggcctgtcatttcacagacggtaatctgagg
cagaaccaggagcaggacccaggcgtcctggttctcaggttgatgctgtttccattccac
tctgccctgctggctttgtaattccttttcctttatttgatttagtgaattgttcatttc
atttcatggtttgcttgagtgccttccccaaaacaccaccgtaagtaaatcattgcaaag
tggataatattttctcatgggaacaatgataaaaatcagggatttatttctaatcaagga
ggcagcatcaaacagatcctatacatgagcaacaccagtcataaggcagggattaagcaa
ccacaaacctcaatgacctcatgtgtaaagtaggcataatagagggatatctctcaagac
actgaaggattaatgcagacaacgtgggcaaagcactgggcgcagatcctggcagttagc
aagggcttgggaagcaccggactctctcactcgctgtgagttatgcattggcactcacat
gttttgttggcttataatcctcgcacggtgttaaaacctaggtgctgtcattatgcccac
tttacaaatgaggaaacagaggcccggggatgcaaagtaccttgttagaggctacataac
caggaagcaaccaaccaagatggcatttcaccccagatgatttgacttcagggtctgtgc
tttgaactcttatttcacacatatagttgacatataataaatactgttaatattatcact
tcacttaaatagatgagttattatctgtatcacatagagtagatgtactatgaccattat
ttcccaaaggcctcattttactataaagtaagcaaaacacatgaaaatagatgccaattg
agcatcaaggtggccccaaactaattttcaggagttttctgtccaataactgagaggcgc
tttatacaatgtatgacccatagtatcataacatactactgtacaagaaaattggagctc
atttcctttttttttttctgaataaatttcttactcaacaggcatcatctaaaaatactg
tgtgtggctggtgctccatactggctgctattgttaagaaggacatttgagcgggcgttt
tgctggtgaaaagcatgtgtgtgtgtttgtttgttagttaattgtgaaatattgaaagtg
tatagaaaaagttagaaaatacagtaatgcactcacatatacttcccactcagcattgtc
aaaccgtaacatttgatacatttcaatgttgtttcactgaaacacagggaaaaagaatag
aggggaaattccttaacctggaaaacacagctacaaaaattccacaattgggcccagcgt
ggtggctcacgcctgtaatcccagcactttgggaggctgaggcgggcggatcacctgagg
tcaggagctcaagaccagcttggccaacatggtgaaaccccatttctactaaaaatacaa
aaaaattagccaggcatggtggcacatgcctgtaatcccagctatttgggaggctgaggc
aggagaaccagttgaacccgggaggcagaggttgcagtgagccgagatcgtgccattgca
ctccagcctgggcaacaaaagtgaaactccgtctcagaaaaaaaaaaggaaaagaaaatt
ccacaattaaccacacccttcgtgtgtcatattctttaaagctgaaaacaagacagacat
gcccaccttgcctcctgtgtgcagggactggacttgggggacctgacaaagatgagaaaa
cgaatagggcaaggatcccaaaggaaactatggaactgtcatcattccatccggggtggt
ggtgggtttcgttgttaacttctgatttaactggatattagctggagaatctagtgcgta
ctaattcttgtattttgtcttgttttgtttttctggggatggaatctcactctgttgccc
aggctggagtgcagtggtgcaatctcggctcaccgcaatctctgcctcccaggttcaagc
aattctcctgcctcagtctcctgagtagctggaactacaggcgcccaccaccacgcccgg
ctaattttttgtgtttttagtagaggtggggtttcaccgtgttagccaggatggtctcga
tctcctgacctcgtgatctacccgcctcagcctcccaaagtgctgggattacgggtgtga
gccaccacacttggccctaattcttgtttgttattgagatttacattcaggctagttctt
ggtcaattttaggcaacgtcccgtgggggcttgactagaatgtgtgtattctactagggg
aatgcagaattgcctatatacagttaatagcgtcaactttgttagttgcatagctagaaa
cagcatagaaatgcgcttgctgtgctctaaaacctttcattgctaatgaatgaaggggat
agattgtataacatcacacttaggagtgtgctgtgtgccagatcatacacaccccagaag
gcccaaattgtcactgactgtccctctcttgagcatgggacatcgccaagaaggaattac
tccatatccaaataagccacatgatcatagaactaatttgttcctttgggtggttgaatt
tcctctatagagatcccaggaggcaacatgaatccctccagggctggactgcacagcctc
cattgataccctccagtgacggggcacttggcctctggtgacacgtcccctgggaatggg
aacttactctgtcatctttcaaaccaccttaagtggctccagaagggccaggacaaaatc
cttgacttttttttttttctggcattatttgccaattcctttaacaaatattaatcaagc
acctgctgttctagccccttggagtaaacagtgagcaaagctttgaggtgccttccctca
cagagtttattataatttagggataactaagttagtagtttttccattttctccttgtaa
gcctgtcaagttttgctttaaatacattgagatgatgttactagggttgaaagaaaatag
aattgcctattttcttattgtttagtgccttaaaaattcttaataatgatgttttaccat
aatgttaagcttgttatgaatatagcttcccagctcttctgaatctgcatagttcacctc
cacgtgctgcagggccattgacgagaattcccgggggagacttttgtccactcccagtcc
agaaaaggcagaaaggcccagtgttaccatagctgtttgatgggaggcgtttcctttatg
ctgctcgctcactgagacagcaatccctaatggccctggtgagaggcaggattcaagcac
ggttctcagcgcccacctcgcttacgctgagcggctgcaagcccaagctctacgtccctg
ggatgccacccacccacccccagcctgcctcagcctatgggctcctttttctattctgat
cccggaagcagcccatacttttttgcaagctcagctccacatttaaaaagatgtttgctt
ccgtctcccatgctttgtcctggacatgcagtgagtgagagtgaagcttgcgtcttctct
gtagacccagccatgttgcttccttccttttctcagcttattttctccatggagctggcc
ccaaggtgccatgagcctgagacttaggagaaagtaaaaggcaccactgaagactaaatc
taggctacgtgctgcagctgagattggaacctgtgcttagatgtgaacttccacatgggt
gcttccttgaagagttgagcactcattcagacctttataaattgccagatccattgagtt
taccagcctctctgagatcacaggctcaggaatcagatgactgggtttcaaatcctacca
cttactagctaacttgtctgtgtcttcaacttcctcatctctaactaaacatagtaattc
ctaacttatacatttgctgcaaggatggggctcaatgggcactgggatagattctacaac
accacatagtgcaaactaaggaatggcatttactggggaaatttagaaactaggagtcag
gccccaaaggcataggggtctccatcttctcataatcctatggaaaactgaaccaatgca
aagacaaagctctttgccatgcagtgggctgcagtcctgacctgagtgtcctatctcctc
gaaggatgaacacgaacaccactttccagtaaggagacagggggaccactcgattgccag
gccgtcggggtctagatgccagcagagctgagaaggcatctgaggaaggccagctgcctg
gcacccagggaacatgggtcctggggagaggggcagctctcctcttggggaatgtttgcg
gctggtcctgtgggaaactgagtttaggtgcacatcctccttcgaggaggcggggaaact
ccagttccagccagctcatttcctagatcatgtagactgagatctcaggatcattttttg
aatagttctgcttgttggcccatggagaattaagcaaaataaagcacataaagtagttag
tatagtatctaacaagtgctcactatatattaactgttattgttttaaaaggatgtttgc
taacattttcctagcgcttagagatatctggatttggagaggtttcagattacttatcca
cagcatttctggaaccagagggctttcctgagaagcgtttgtaaaagcaggaacaactta
acttttcttaccttcagtctctctcttctaagtttagtcaaagctagactcaggatcaac
cctccacatccaaatgtcctaggtcatttgggacctggttaaagggggcttcaaatcacc
ttgtccacacttgctgtggcaggcagagtttagcagcttgaggaagctgaggcctgaagt
attttggtttatcaggtaactctgaaccttgaaaacgccaaacatgcagattgcctgtgt
gcatttcatactcccctgcaaagcagctcctcgcttcacaggaagaggcggaacttaaat
ccaaatacagttacagtgtttatatcctgggctgcactagttaaaaagaacctaagattt
atggctcttttagatcacagaaccaaatcccaatacctcctgtcagatcttctctccttc
cagaagcaagtatttggggattataaaaagtgatgttatggatgatgtctcttaaaatat
cagatcgacttgatggcaggacctgctgttcaaatttctttagagacacctcctcgctgc
cccgcccttgcctctctcccgacgagtgccagcccatgcgcacacacgcacaggtgtgtg
cccaaccatgtgacttccctgctacctccagactaagcgggcatttcctttacatgtgct
gttttctctgctattgtctccttccatcatccttttattttaacatatgtttactaaatg
ccattgttctagaaacattgaggcatataaaagtgaataaaaccagcaaataaattccca
tcctcggccaagcgcggtggctcatgcctgtaatcccagcactttgggaagccgaggcag
gcggaccacctgagatagggagctcacgaccaacctggctaacatggcaaaaccccgttt
ctactaaaaataccaaaaattagccgtgtgtggtggtgggcacctgtaatcccagttact
caggaggctgagacaggagaatctcttgaacccaggaggcggaggttgccgtgagctgag
attgtgccactgcactccagcctgggagacagagggagactccgtctcaaaaaaaaaaaa
aaaaatccccatccctaaggaccctatattccagtggctagtcatcattactgctaccgt
ccattgagtatctgctgtataccaggctcggttctagctgctttacctatacattatttc
taatttgcataacttctctgaaagttgaattatcagcccatctaacagatgaagaagttg
agtctcacaaaaattaataaagccccaaaagtgattcaaagctacattccaaagtctttg
ctcctttcctgccaaggtggaaatctttcacctgaaccaaacaagtgtcttgctgacctg
tgaaacccttaccctccctcctccacccctgtacctcccacatatctgcactgcagttct
gagcttctcaccatggtaacctgtggacacaccagtccctctctgagctactgaaggtac
agaccatattctactcatcgtggtttcatcagtgtttggcacagtacaagatcaaattaa
aataagcagatcctgaattgctaaatgaatgttccttatatagtgcttactcagctttta
gatttattgccatctctacttctgtaccatctgcagggacgccgcccgttgaggtggtag
agattggcttaaggttgtacaaacagagattggaaacttctttccctgacttgttctcat
tttactgtcatatttgccaataagcacttaaaatgccaactcacacagctgggtggaata
tcttaaggaaagtaaatgagacagtgtatacatgtaagatgatatacaataaaagatgat
acggagtaatgtgaaaacaaaagatagtattattactgttgtttaagcaagcctcaggcc
ttttagctagcaaagcttcatccagtaactgctcactttgtcttaagcactgtagtttta
ttctgaatgaaaaatatatttacatacctcctcttaaaatcatagttcaagtttaattct
caagatcaagatttattctgcttaataaaactcatttctaatttttttctaacctaataa
ctggtgttctaaatgctaatcttcttagaatgcacttctcctcaaatccaatgtgtcgcc
tctcccagtgaatcactggcttagaaataatgatggcaaacctatattacatgcttaata
ggtgccaggcacccttgtaaatacttttcaagtgctatcctctttgaattccaaattcgt
aatttaggcactattattattcccatttcaaagattaggaaataaatgacaagaggcata
agatgcctaagaggccacacatccgctaagtgacagggactcgatctgaacccaggaaag
ctcattctggagcccacatttttatttttgaatgactttagtttcttttcaacataggta
acacatcacctggtttaaaaaaaaattctagaaggcatgctgtaaggagtcttgcttcta
ctctggtcctgcctgttttctctttgcccactcctgaccccaactctaatacgcagttga
caacttttagtagtttctggaatatacctttggagattttaatgaaaatgcaagcacatg
caaatatatgctttttgtttcttctaccttccttccacaaaatgtagtatgctctacaca
cctttttttctctgttatttatatatctcatagctctttccatagcaggatacaaatcct
tctcattcttttatgctgcatattctgtcacatgactgtgtcatgatttaaccagttcag
gattgatggacactttcagttcttgtctattcacacagtacagtcatgaatgatcttgat
gttcatcttttcctatgtgtaagtgtatctgttgggtaaatttccagaggtggtacttcc
aggttgaaagattcttgatttttcagcttttatgatttcgtaacattcctggatttccct
tcaattagcacattttcctgcagattgtgtaaacatctatttattcttatggcctcatct
gcagaatgtgctgtcacactttgaatttttgcccattttataggtgataaaagatattct
cattgaattcacatttatcttattatggatgaggttgaacaccttctcatacatttaggg
cttgtttattatattttataaataagctattctaccctttgacaatttttcaattggttt
gttggttttttacttagtgaaactagagatattcttttaactattttgcagtagtgattc
ccaagaaagagtgaagacattaataaaggaaattgccataaacacaataggttatcaaaa
ttgttttaggtacaagttaaaagacttctctggttacttttgactttaaactctatcata
tgaaataatgtatatcaaaagttctacaaactctagtctgttagttattcattattatta
ttttttttatttttatttttttgagatggagtctccctctgtcacccaggctggagtcca
gtggctcgatctcagctcactgcaagcactgcctcccaggttcacgccgttctcctgcct
cagactcccgagtagctgggactacaggcgcccgccaccacgcccggctaattttttgta
tttttagtagagacggggtttcaccgttttagccaggatggtctcgatctcctgacctcg
tgatccgcccacctcggcctcccaaagtgctgggattacaggcgtgagccaccgcgccca
gctggttattcattattataatagacaaaacatttagagatgataatgtaaaactctaaa
tagctaagattcagaccccaagaatttcactaacaacaggtcattgatctactctaagaa
cctttcatctgtactcaactgatcagtgaccttttcaataatgagaaaataaaaaaaatt
aaaagccttttcttctgtcatatttcctgaagtgtgtgacaattagttttagtctagatc
tctcaaatacgatgccatttttcttttttaaagcactcacaggactcattaacaatcaac
agatcatctccttagaaacataggctcaggagttacccatagaaaccatcctaacccttt
agagtatttctatctgcaacacccagattttaggcaactggttgtcttggactgtaagtg
ctcaaatctgtacaaaacatttttaatttccactccttagtgtatcttttttttttgaga
tggagtctcgctctgttgcccaggttggagtgcagtggcatggttgtggctcacctcaac
ctccgcctcccgggttcaaccaattctcctgccacaacctccagagtagctgggattaca
ggaacctgccatcacgcccggctaatttttcgtatttttagtagagatggtgtttcacca
tgttggccagactggtctcaaactcctgaccttgtgatccgcccgcctcggcctcccaaa
gtgctgggattacaggtatgagccactgtgcccggccaggtatatctttacaatgtgtaa
gtttctaacctttccccttttccctggtctggggaaaggtagaggctggttccagagctg
atcccagggcctttgtgagctcagatatgcagtaatggcataggaccatctgccaggtca
aggtgtttgctgcctctgtggttatttggttataaagagccagcaaagccaggagacctc
tctgaaaaagatacacatagagcctaatatgtgaagtcgtttatattttgtatgaataaa
catacttaatacacatttacacatacatactaaacgcagtatgaaccaaatgcttacagg
agacagggcatgtgtatgggcataagactttggagagaaactctgaagtccacagaaccc
tcccatgggtcaagatcaaatgcctaccagatgctcagagcctccagtaaatccagtcag
agctggatttgagtagaagattcccttttatgcacaactgctgacataagtggcgtgaca
cttccttatttatgtctggagtttactgccctttgagtttattgcctaatacagcatggc
cacagaatgtctttttcaacgcaaaggcctataattctattacaagaacaccttggggat
attgtgggttcagttctagaccatcacaataaagcaaatattgcaataaagcaagtcaca
caaattttggtgtttcccagtgcatataagagttatgtttatgctatactgtagtccttt
aagtgtgtaatagcattatgtttaaaaacacaatagtgtgaaaaaacccgcaatatctgc
aaagcacaataaagcgaactgcagtaaaataaggtatgcctgtatattttttaaatgcac
ttgagcctttctaacccctttgagaattaagaagcagtttgcacaccctctgcaatctaa
aatggatcccacatctatgcacacacatgcaggactaggttcatgtattgtataacccac
acagtcaagtcctgcaagattcaataaaaacctgtagtcaggttcattctatttcagatg
cagaaattgtttgtaatgaatgaaaaatgaacactattagccacgtgcttttataattca
ctagataacatatgaaaccactaatgttgtccactaacgatgactaccatcatgaccaac
acaacaaaaccagaaacagtatttcctcctttttttttttttttttttgagacagtcttg
ccaccaggctggagtgcagtagcactatttcggctcactgcaacctccgcctcctgagtt
caagtgattctcctgcctcagcctctggagtagctgggattacaggcacccgccactata
cccagttaatttttttgtacttttagtagagatgggatttcatcatgttggccaggctgg
tctcgaactcctgatctcgtgatacacctgccttggcctcccaaagtgctgggattacag
gcatgagccaccgcgcccggcatatttcctcctttttacattgtactttcatagctgatt
ctcccctttcaacccaaaatgcaaacacaggctttaagagatttcatttcatttcagaat
gagctgtgacctggaggcccaaccaaaggcaggcttgttgcccagtgctatggagacagt
agacttggggatgtccttccataccatttatcctgatggcctgaaacaaaagcacatcac
catatccttttgatcacagcatagatggaatacaaaagatgacctccaagactccgcctg
accttgctccacctacctccccagcctctcccacccaactctccccaacacctctggggt
ccagacacaagagccttccttcagttctgcaaacacaccccacttctcccactcacagcc
acctcagcatcaccgcaggatgttgctgaatttacaatcgcctcctccctctctctcccc
tcccaggagcctttgctttgcctagctaacatccacaggattgcagatggcttgtcactt
tctccaagaatccttccttgaccccccgatttctcctcatgggacttaataacttggtgt
ctgaattccctgctagaatgccagctctatgagggcagagacagactttgtcttatccct
gccacatccccggcagctagcacagagaagggagcaaatgtccggtgagagaattatgag
tgtgaccctgacatgggctgtgtcttactgtctgtgccacgccgtctgcccagtgtaaat
gctaaagaaatgtttgccgagtgaatgaatggatgaatcaatgagttgttaaaaaaaaaa
actgttcacatcaacacaatttagcattaaaatactcactataaatcataaatattatta
tttttatcatttaagttctattcaagtgtttttcccccacatagtttcttagaaatttta
tggccaaaaaaacaattctcaggctaggcgtggtggctcatggctgtaatcccagccctt
tgggaggccaaggcgggaggatcacctgaggtcaggagttcgagaccagcctggccaaca
tggtgaaaccccgtctctactaaaaatacaaaaattagccaggtgtgatggcagccgcct
gtaatcccagctattcaggaggcaggagaatctcttgaacctgggaggcagaggttgcaa
tgagctgagattgcaccactgcactacagcctgggtgagagagcgagattctgtccccca
aaaaacaaaaaacaaagaacaacaattctgggatgcctgaaaaatgctccagcccacaga
aagtgaactgggaatctttttaagggtaggtatcatttctcccaggactagagtcctttt
aagtgactcatagttcccaagatctgagaggcttctcttttggccctgtctcatgaccca
tttctgaacatctgtgttgattttttctttctttttttaaaatctatttggctcagtgct
taagataaatgagaagtttcacattctaccctaaaggctaatagaatctggctgtactgg
attgcaattcaagagtccagtgatgtggcttctcctaagaaaataccctttctcctagaa
tcccagggacctatgagcaaaacctccaggattcaaagtctgagtttaaagagagaaatt
tttcacacacacaccatccaaaacaatcctacacacacccaacaagcacacagcacccaa
aagtaaaccctccacacacccaacatgcacccacacccaattctcacaaacaacccaaca
cacacatgcaacacctgcatatgcgacacacatagaacacacactgtacctgcaatcccc
accctcacatacgcaaccctccacacccccggcacacacaccacacacacaccggggcct
gacactcctcagtcctgagccgagggtctcctggaggcccagcttctctcttctttccct
accccattccatcatctcatccaggccctattggaggcaatttgcccttattctaaaagt
tattttagttttgattacggaagacttgaaagtaatgtcagttcttagaaaaattctaat
gaaaggctgggcaaggtggctcatgcctgtaatcccagcactttgggaggccgaggcaga
cagatcacctggggtcaggagtttgagaccagcctggccaaccaacatggtgaaaccctg
tttctactacaaatacaaaaaattagccaggcgttgtggcacacacctgtaatcccagct
acttgggaggctgaggcaggagaatcacttgaactcgggaggcagaggttgcagtgagcc
aagatcataccactgcactccagcctgggcgacagagggagactctgtctcaaaaaaaaa
aaaaaaaaaatttccaatgaaagcaaatcaggggtttggcctcctggtggcttttgggtg
cttgtcttggagatagcagttggataccacagcaaattggctgtggattatttagtagtt
cttatttttcatacaactgcctctgttgcccactttcttcattttttcttaccaaatggt
agaattgcccttctcaccttctaccgttatgtcctcctatcaggaaagcaaactagtgca
ttaaaccaccgtgatcaccaccacaaacctgtgaatgggggaaggaacccttttctccat
gaggacatgaaagtggagggaggttaggcggtgcacattgccccaaatcttccagtgaag
aaggatcccaagagaatggaaaggtggtctccttttttgacacccacactcctctgtccc
cacacggcccactgggctctgcacgactgctgtgtccaaagcattgtcccctgcagaagt
tgcgccagtcctccctccacctcttgctgcactcagacaggaaggcagtgaagccagaca
ggaaggcagtgaagccagacaggaaggcagtgaagccagacaggaaggcagtgaagccag
ccacgccagcctcagagcaggcactgagggcactgacgctcaccctggccctgcagaatc
tgtggaggagaggctgtgggtccacccttgtcttctgcttatcccagttgtcctacctca
tctcttcttttaatttctattatggaaagttcctaacaggaacaaaagtgcagagaatta
tattaaaaattcccacgtgcccattgcctgccttcaacaataaacgccttgtagctaaat
ttattattttgcattcctgagctcacttactcccgtgaattattttgaagcacatttgga
aaatcatgttaatctgtaattaaaaaaatatataacatcaaaaggcatggacgactccct
tttaaaaataaccgcaataccgtcaccacacacagaaaattaagatttctttaatgtcaa
cacctatgctatctgtgtttgccttcctccaacagtctcatgaacattttaagatttgct
tgcctgaactgggatcccaacgaggtctacactttgttctgaactcatgcatcccttaag
tgtctcactctaccagtttactctacatctcttccagactccctcaattttcttcttctt
cttgaaaaaaatattgcttgtcctgtctgaattttgctgattgcatctttgtgttcttct
atcccttttattttctgcaaattggtagttatatctggagggttgcctgagttcagtttt
ggtgtctttggtaagaatccttcgtaggtggtgttgaatgtggactttcattgggaggca
cagaaggtctggttgtctcccttttggggtgatggttgcccggagtatggtttactctta
actcctgtaatgtaaagggagggaggaaggaagaaaggaggaaggaaggaaggaaggagg
gaaaaaaggaaggaaggaaaaaaggaaggaaggaaaaaaggaaggaaggaaggcaggcag
gaaggaaggacctgtcagcctgctgcttgcctgaatgtgactgaccacggccccaggtgg
tggagctgccaccttccctgtctgcttgcccccaggaccaccactttcaccgaccacact
cagaatcagtgagcccctctgcagtgcctgccttgtctgggctgaccaccttcagtgcca
gagctgagccagagacttggccattttcgggagtgccataaggattattttgacactttt
gtccggcataatagttgcttttaggtaagatgatttgtcagcctcctccttctgtcgtgc
tggaagtgactcttctcaagtatttttgtcagcctctgagtaacagtaaagcccactcta
gcgtagcaaggatgagcagagccagattctgggttggcatgaagggtttaaagagagtga
ggttgagtgagctcccctggcccacagagcaaggttgacaaaggaaggaaaggccctgtg
gtgtggccccagtgaagggcaccagcgccgcctctggatctctgtgtcctcacctctggg
gtaagggcatgcttccctctggggtggatgtggctgacagcagatgccctgtcatggctc
ttgcctcagctgtgcgtgtccccatctttcctgtcctgaggccagactcataggtaaaac
cgggtctcaggcatctctccaggagggttgatgggacactgcaagctccttggccccgcc
agggctgtcttcccccagctttcagtgggtagtgacggccccgtgaccatcactgcatcg
ggggggagttgaccccgccagggctgtcctctcccagctttcagtgggtagtgacggccc
tgtgaccatcactgcagaccccgccagggctgtcctctcccagctttcagtgggtagtga
cggccccatgaccatcactgcactggggacgcttgaccctgcagtggctttagggcttcc
agcttaaacacagtcaaaaagcgaaaggtctagtcaccagaagacaacatttgacagtag
tagaaatcacaaccaaacattgtgctgttgtacaattgttatttgtcaattacaaaataa
tattaaaaaataaaaaaccccaaaacattgtactagccattagaaaatcattcctgacat
ccattacctgccaaaacagagtcatatctgtcctaaacatagcataacttagcttctaat
tttttctaagggagaaaataataatgggattctgtacaaaaaaaaatgttaaatatggac
tgggaactaactcacctttttaatctcaatctccaaggtcatctaattgtaaatagaatt
ttctaaactttggtagaacacaggacacattggtaattttcaatgtaattaaagttttcc
tgatttttttaaacttagaactgtttattaatttaaatgatcactaatattttatttaaa
atatctttaaaatgagtcaagggttttgcacttttctccagcacaactctagtttattta
tttgccaatccttttctgtttaaaccatttgtaattcttttttgcttaactcattcaaca
ggcagcatgaaggatcacaaaacaaaaattgttctaaatacttatttaaaatatcttttt
cacttacaaacaatgtctgtgaaattcttaattaatacaaacaagaatctaactaataat
gattcaaactctcactattacgctaggtgattttttttttactgtgttgaaattgcatta
tataatttaagttggacaaccaagacatttcatttttgatgttgattacaactttcaaaa
ttcgcaatctactaacataatttatttatattgacttaatgtaagtaaatcagttgtgcc
tttgaaaatgctacattgttcataaatgaataccaagcttatgcatagctatgtacaggg
aggtgaaaaatattcatcttctctgatattaacagacagttaaatacagtactatccttc
tcctatatatcatcactcaaatagctgtttcctatggagtcctagccaagctaagggaaa
aagaaaatatattgacctctaagatacacgtcagttgaatcagaactgtgtagtagtaga
atgcttggcaaatacaatgatttgtagaatacattgatacatattgtgaagtggttgaga
gacagccagcagttgccacagctgccaaactccagaagaaggctggtgttggtgcagggc
agagcttagggcgaaatgtggtgggctggggacaacacggaggagggagatttttctatt
cagtgcccagttgactccaccgctgagggccagtatagtgaagttaaaaaccagtttcac
acactgtgatgaaattctataaactcaggattatcctgtcaaatcaagatgacatgcgtc
ccattgtttaaaaacattctaatggatggaacttagcaaatactgctaagaacagaacca
gccgggctatgctgcagcgtctcagacatgtttccactcgctgctgcgatgtgtttgtca
aagagtttacttagagagctgcagagctatcagagaggagaagagaagcgcttcgccctc
acttgaagaacagtaactgcagtcaagcagaagacacttcaaacaaacaaacagacagac
agacagacagatctccccactcattctactggtcttgtgcttacctttcatttttcttgg
cctcttgcttcccctctctctgatggcatcttaaaggactcaatgttgaaatggtagcag
gcagcagcccatctgaaggtagcattagcatttgagaggaaagatcttgaggactgagtg
tgcttagccactgtgcacctcgaacctgcattgttcctcggttttcctatggagaaggat
ccccctgtgtgggactggcatcctctgaggactgcaggactgtacctgggtgatgagaaa
ggaagccaaggccatagcactataattgcagtgctctgccttaaagtccagcctcgagcc
tgcggctcgattttccagtaagctgagagcatggagaacaccagaaagccatttcggttt
ctgcttatttcttctctacagattttgagggttgaaaaagcacattccagaaaaggcagt
ggaaaattctaaaataaaagtgaggcagaatcagagtgaggggcatgttgagaatgcccc
taccatcttgaacggagcaaaagatggctcatatgttgacagctcccaatcccccacttc
tggagcagattttccagggggaaggacattacagagtccagatgcctcttccatgattcc
agcacctctaatgttgtaaggccgtgttatgagcaccctaaagatggcacttcagcacac
agttctcgaaattctgaccattctatcttcttttaaatccctctgtttttccaaatccta
aagccctgtgacacaccagcagccggtaagcgtctttcgagagaaggagcaggccagcag
ggcccccacatcttctttcctcagcttcatcccagatgcctggtactgtctcaagactgc
aggcactgaaacgtgaccccggtgtctcaggctgaaacagcaaactcccaaccgagtttt
aaattctcaacaatttgtggaaattatgagatttttatgagcatgtattttacaggactt
cctagaatgcctttttgagaaccctggaaggggaggaaggaaatatcaccctaggggaag
cagaattaaatgtgtactctctcctgtctctctttttctctccttccttccagcccattg
agaaatctacaagccatccatcgtctgaccccgtaaatttgtctttctgaggtaataaga
tgacacagcctttgccaggtcagatgctactttcataaaaagtgctgagttggtgaccca
atgccgtgaataaggatataatcaaatttcatatttcttccttgagcttcagcaatgacg
cccacttttcatggattgttactcagggaggacgcataaatgcctctcagaatcacctaa
ttcaatcttcataacaacagTCTAGGTGAGATGGCTTTGTCCCGTTGCAGGCGAGTTCCA
AGCACAGAGAACCAAATGGTTTCCACAGAGAACATGTGTAGAAGGGATTGTAACCCACAA
CTGTCTGAACCCAAGCACTAAGCTTCAAACCAGACTCTGTGCTGCTTCTGCTTTATACAC
AGGCCCTGGCTGAAAACCCTTGACTTTACCAGGCATGCAAGGAGATGCTAAGTCCACTTT
GGCTGCAGgtaagaattaagtaggactaacctgggtgttactaataaggagttcaaccag
ggcccagcaatcaaggagggcttcgtggaagaggtggaacttggagtggcctggaagaat
cgcatagaatcagcaaaaccatggaaacgacaatgagcagggaacacacacaggtcccac
tgtgacagaatgcacatgggtgatgagcagacatgtcctcagatgggtaggcaggaccct
ggaaaacaggaaatggagtctgtgtttgacagcagaagcaacggcaaccactgtcatctc
attcattcatttaataattgtttattgagggtatcatgtcaggtgcagttcttagtgata
gtgacctagcagtgagtaagccaggctgagtccctgccctcaaaaacctcaagatccagt
agtgggccagatggacattcatgatgtttaatagatcaagtagagttccccttcattgat
atctatttctaaagatgtctgtcttcccttctaacagATCTCTAAACGACCACGGCCCGA
AGTGTCAGTTTCAAATGCTTGTTTCAGCTCTGCCCTCCCCACATCAAATCCCACCTCTCT
CACGCTAAAGCATCATAATATATTTGTGCTGAGAGTTGCCTTAGAAATCATTCAGTATTC
AGTTCACGGGGGAAGAAACAGAAAGCCCCTAGAGGTGACCTCATTAGCCTACAGTTGCCC
TGAGAACTGGTGGCAGAAGCAGATTGGTGTCCAGCCTCCTGATGTACATGCCAGTGCTCT
TTCCCCCAAGCCATGTGTCTCCTGGTCACGCCCTTTGTCCTTGCTGTCCTCTACTATTCT
CTTCTGGAAGACTCACGATGAGAGAGCCGACTTCTCCAAGCTGCACTCCTAGCTCTCTGG
GACCCAGCAGGGACCGCTGCCTTCCAGCCAGCAGTTTGAAGAAGGACAGCTACCATCAAA
CACAGACTTACAGCCTCCCTGATGCCCTGGATGCCAGGAAATGTCTGGACCAGTCAAGAT
AAGAGCAAGGCAGAGCCAGGAAGAAATGGGGACAGGAGTTCCTATTTAAATATATAAAGA
ATCCTTTCCTAGGTAGAGAAAAGTCATCTAGCAATGTGACTGATCACCTCTCCGTTTATC
TGTTTGATCAACTGGAATTTCTATACAGAAGGTTTATACAAAGAAGCCACAAACAACCAT
TGTCACAATGACCCCTACATAATTCCTTGTGTAAATGCTCTGGAAATGCACCCAGAAGTC
TGGAGAAGGTCCAATCAAACTGGGTGGCAGGAAGAAGCAAGCTCTGTTCTCAGATCTTCA
ACAGAATCACCTGGACCCTGGGGTTGCCACCACGCTAAGCCAAGGAGGCCTCTGAATGCA
CGGGAGTGCAGGGTCTGAAGGGAGTTGTTAAAAGGTGTTTCTTGATCCAGGACCATGTAA
AGACCCAGGAGAAATAGGTATCCCAAAGAGAACAGCGTATAAGATTCACAAACCAATGAC
AAACACGCTGGGTTCGCTGCTGGTCTCCACAGTTGGTTGGTTCTGTAGGGCTCAGCTGCC
TCTTTCTCTCTACTTCTGGTTTCAGAAAACACGAGAGAGAAGCCGAGTGCTCATGGAGTT
TCCTCAAAGACTCAGCAAAAACTAGGCTTTGTGTTCTGAGATCAGGAAGTAACAGTGAGA
GTCCAAAATTTTCTTCCCTGACAATGTCTCCTACTCAAGCAGGGCCTGGAAGTCACCCCC
TAGAATCAAAGCCTTGACATATGCAAGCTCATAGTTTATTGCTTCTTCTCCCATCTGCCC
GTTGACAGATAAATCCCAGAGGGAATAAAAACACATTGCCCTCAGCAGATTATTCTTCAC
TGAAGAATACCAGTCTTTTAACACTCCGCTACAGAAATAGCTTTCTGCCGGCTGATGGCT
TGTTGCGCTGCACTAAGAGAGCCCGCACACCTCGAAGCTTCGTCAAGCAAAGCCTATGAT
TTCACAGACCCAGAAATGTTTTCTTTCTCTAAGCCAATAACATATGCTTGGGTTTATGCC
AACTCTACCAGAGGCGCACAGATACAATGAGGCATGAAGTTCAGAATAATAGAAAGTAGA
GAGTTGGAAAGCACAGGAGAACCCATCTAGACCAACCTGTTTTGTTGAAAAAGGAGCTCC
CTGACCCAGAGAGGTTAAGGGTTTGCTGTGAGACGGTGCCCCTGGTTAAAGGCAGCATGA
GATGCTGTCCTCTGATCCCCAGCTTCCTAGGGCTCTTGCCTCTAGGTCACACTGCCTTGA
GGCCAGGAGCTGATATTGATTGAACAGATGTGAAAACAGAAGAAAAAAAAATTGTGGTGA
CTGCCCTCTGACAATTTTCCACTTTCTTTGGACCAATTTTCTTTGCCATTATCTGGAAAA
AAAAAAAATGTCCAGAAGAGCATTTTAAATTCAGGAAGTGGTTCTGGAACTAGGAGAAGA
CACACCTTGATGACAGTAATATTGTCTAAGTGAGAAGGAACAAGCTCTTGAATGTTTCTA
GAAAAACCAAATATGATAGGAGACCATAAAATTATACTTCGTCATATGGATTTCCAGTTT
GAGAAAACTTAGTGGCTAAACAAAGGTGCCGCTTGAGAGATGCAGACAGAAATCAGCCTC
TGCTTTAAGAACAAGTTGCTACGCTGAAGAATGAGAAGAGGAATGGGGCCCAGAGGCTGA
AGGTCTGGACCAATCTCCCTTCCCAGATAAGCGCCTGGACCCTCGTTCCTCAGAAGCCAC
GTGTAATTACCAGCTCTTTTTGGCTACAGAGCACATGCCCAGGAGGCTTGGAGAAGCAGG
AATTTAAAACATGCTAGTTTCAGAGCCAAGATTGGTGACAACACCATCAGTTACTGTTTG
GGCTTCGGGAAGCCGTGGGCTGCAGCACTGGGTCTGGTGTCCTGGGCTGTGTGGGACCTC
AGCAAGGTTGTTTCCTGAAATGAAAGCTCCTCTTCTGGGGGATGACACACCAGGACCACC
TGCAGATGATGTTTATGAATCCCCCAGCAGGGGTGGATTGATCTTACAATGGGACTGTGT
AATATAAACATTTCATTATTCTACAAAAGAATACACACAATACCACCTAAGGGTCTCTAA
GAATAGGGTTGGAGAGTGACAATGAGAAAATGCCACTCAAAAAGAAATAGAGCCGCATTC
CTTCTACACAACATTAATATTAACTTTACATACAGGGGAAAAAAATGGCATTTTACCTTA
AGAGTTATTTGTAAACTCTCTCCACACCATGAGATAAAATCAGTGCAGAGCTCAGAGCTC
TGAATTTCCTCATTTGGGGGCTAATAGACTTTAATGGGGGCTCTTCTTGGCATGCAAATG
AACGTGTGTGTCTCTGAGTGCATGTGTCTGTGTGTGTACACACGTCCCTTTGAAGTTTAT
TTACTTGGTAGCACTAATTGTAAAAGGGCACACCCAGGGGAATTTAATGAGGCGACATGC
TAGAATATAGACATTAGAAAGGGAATTAATATTTTCCTCATAATAGCAAGTAGGTGAAGT
CAAGTATGAGGACAGAAGGAAAGAAAAAGGAAGGCAGGGAAAGAGGGAAGGAGAGGAGAG
GAACAGGTTTTGATGATCGTAGATAAGAACCAATAAACACTGTTGCTTCACACTCCCG
>6_sm chromosome:GRCh37:6:1080164:1080464:1
CCTCAAATAAGAGCCACAAACGTGGAAGATATATCCAAAGGAACCAAATTAAAGGACTGG
AGAAAGGTAAGAAAGGGACTATGCTTCTTATGAGTTTTATTTTCCTCAGTTACAttgttt
taacttattttatgttcgagggtacatgtgcaggtttgttacataggtaagcccgtgtca
cgagggtttgtcgtacagattctttcatcccccaggtactaaacccagtactcaacagtt
atcttttttgcccctctccctcctctcaccctccaccctcaacagtgtctgttgtttTTT
A
>6_hm chromosome:GRCh37:6:1080164:1080464:1
CCTCAAATAAGAGCCACAAACGTGGAAGATATATCCAAAGGAACCAAATTAAAGGACTGG
AGAAAGGTAAGAAAGGGACTATGCTTCTTATGAGTTTTATTTTCCTCAGTTACANNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNTTT
A
