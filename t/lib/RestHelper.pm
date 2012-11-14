package RestHelper;

use strict;
use warnings;
use base qw/Exporter/;

our @EXPORT = qw/is_json_GET json_GET action_bad action_bad_regex/;

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
  my $resp = do_GET($url, 'application/json');
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

sub do_GET {
  my ($url, $content_type) = @_;
  $content_type = 'application/json' unless defined $content_type;
  note "GET $url";
  my $req = HTTP::Request->new(GET => $url);
  $req->header('Content-Type', $content_type);
  
  #Go a level higher until you get out of this package
  my $parent;
  my $level = 0;
  while(1) {
    ($parent) = caller($level++);
    if($parent ne __PACKAGE__) {
      last;
    }
  }
  my $parent_request_name = "${parent}::request";
  
  my $resp;
  {
    no strict 'refs';
    $resp = &$parent_request_name($req);
  }
  return $resp;
}

sub action_bad_regex {
  my ($url, $regex, $msg) = @_;
  my $resp = do_GET($url);
  if($resp->is_success()) {
    return fail("$url | $msg");
  }
  my $content = $resp->decoded_content();
  my $ok = like($content, $regex, "$url | $msg");
  diag explain $content unless $ok;
  return $ok;
}

sub action_bad {
  my ($url, $msg) = @_;
  my $resp = do_GET($url);
  if($resp->is_success()) {
    return fail("$url | $msg");
  }
  return pass("$url | $msg");
}

1;