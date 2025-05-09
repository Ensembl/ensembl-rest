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
