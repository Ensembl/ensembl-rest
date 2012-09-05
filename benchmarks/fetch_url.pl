use strict;
use warnings;
use LWP::Simple;

my $file = $ARGV[0];
my $iterations = $ARGV[1];

open my $fh, '<', $file or die "Cannot open $file: $!";
my @ids = map { chomp($_); $_ } <$fh>;
close $fh;

$iterations ||= 10;

foreach my $iter (1..$iterations) {
  my $url = $ids[rand($#ids)];
  my $content = get($url);
}
