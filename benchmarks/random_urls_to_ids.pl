#!/usr/bin/env perl

use strict;
use warnings;
use Cwd;
my $file = $ARGV[0];
open my $fh, '<', $file or die "Cannot open $file: $!";
while(my $line = <$fh>) {
  chomp $line;
  my ($id) = $line =~ /^http:\/\/beta.rest.ensembl.org\/sequence\/id\/(.+)\?/;
  print $id, "\n";
}
close $fh;