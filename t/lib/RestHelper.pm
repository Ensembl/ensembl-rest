package RestHelper;

use strict;
use warnings;
use base qw/Exporter/;

our @EXPORT = qw/is_json_GET json_GET/;

use Test::More;
use JSON;
use HTTP::Request;

sub is_json_GET {
  my ($url, $expected, $msg) = @_;
  my $json = json_GET($url, $msg);
  if($json) {
    my $rc = is_deeply($json, $expected, "$url | $msg");
    return 1 if $rc;
    diag explain $json;
  }
  return 0;
}

sub json_GET {
  my ($url, $msg) = @_;
  note "JSON GET $url";
  my $req = HTTP::Request->new(GET => $url);
  $req->header('Content-Type', 'application/json');
  
  #Go a level higher until you get out of this package
  my ($parent) = caller(0);
  if($parent eq __PACKAGE__) {
    $parent = caller(1);
  }
  my $parent_request_name = "${parent}::request";
  
  my $resp;
  {
    no strict 'refs';
    $resp = &$parent_request_name($req);
  }
  if(! $resp->is_success()) {
    my $code = $resp->code();
    note "Response code $code";
    return fail($msg);
  }
  my $raw = $resp->decoded_content();
  my $json = eval { decode_json($resp->decoded_content())};
  if(! $json) {
    diag "Could not decode JSON";
    diag explain $json;
    fail $msg;
    return;
  }
  pass("JSON retrieved | $msg");
  return $json;
}

1;