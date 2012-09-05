# required module imports
use strict;
use warnings;
use feature 'say';
use HTTP::Tiny;
use JSON qw/decode_json/;

my $server = '127.0.0.1';
my $port = 3000;
# my $server = '174.129.135.49';
# my $port = 3001;

my $http = HTTP::Tiny->new();
my $iterations = 1;
$iterations = $ARGV[0]-1 if @ARGV;
foreach my $iter (0..$iterations) {
  my $resp = $http->get("http://${server}:${port}/sequence/id/ENSG00000139618", {
    headers => { 'Content-type' => 'application/json' }
  });
  my $json = decode_json($resp->{content});
  say "definition: ".$json->{stable_id};
  say "nalen:      ".length($json->{seq});
}
