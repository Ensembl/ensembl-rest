# required module imports
use strict;
use warnings;
use feature 'say';
use HTTP::Tiny;
use IO::String;
use Bio::SeqIO;

# setup http object
my $http = HTTP::Tiny->new();

my $iterations = 1;
if(@ARGV) {
  $iterations = $ARGV[0];
}

foreach my $iter (0..$iterations) {
  my $resp = $http->get('http://127.0.0.1:3000/sequence/id/ENSG00000139618.fasta', {
    headers => { 'Content-type' => 'text/plain' }
  });

  my $io = IO::String->new($resp->{content});
  my $seq_io = Bio::SeqIO->new(-fh => $io, -format => 'fasta');
  while(my $seq = $seq_io->next_seq()) {
    say "definition: ".$seq->display_id();
    say "nalen:      ".$seq->length();
  }
}
