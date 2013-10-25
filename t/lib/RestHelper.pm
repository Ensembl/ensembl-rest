package RestHelper;

use strict;
use warnings;
use base qw/Exporter/;

our @EXPORT = qw/is_json_GET fasta_GET json_GET seqxml_GET text_GET gff_GET bed_GET xml_GET action_bad action_bad_regex/;

use Test::More;
use Test::Differences;
use Test::JSON;
use Test::XML::Simple;
use JSON;
use HTTP::Request;

sub is_json_GET($$$) {
  my ($url, $expected, $msg) = @_;
  my $json = json_GET($url, $msg);
  return eq_or_diff_data($json, $expected, "$url | $msg") if $json;
  return;
}

sub json_GET($$) {
  my ($url, $msg) = @_;
  my $resp = do_GET($url, 'application/json');
  if(! $resp->is_success()) {
    my $code = $resp->code();
    note "Response code $code";
    return fail($msg);
  }
  my $raw = $resp->decoded_content();
  is_valid_json($raw, "$url | $msg (testing JSON validity)");
  my $json = eval { decode_json($resp->decoded_content())};
  return $json if $json;
  return;
}

sub seqxml_GET($$) {
  my ($url, $msg) = @_;
  return xml_GET($url, $msg, 'text/x-seqxml+xml');
}

sub xml_GET($$;$) {
  my ($url, $msg, $content_type) = @_;
  $content_type ||= 'text/xml';
  my $xml = text_GET($url, $msg, $content_type);
  xml_valid($xml, "$url | $msg (testing XML validity)") or diag explain $xml;
  return $xml;
}

sub fasta_GET($$) {
  my ($url, $msg) = @_;
  return text_GET($url, $msg, 'text/x-fasta');
}

sub gff_GET($$) {
  my ($url, $msg) = @_;
  return text_GET($url, $msg, 'text/x-gff3');
}

sub bed_GET($$) {
  my ($url, $msg) = @_;
  return text_GET($url, $msg, 'text/x-bed');
}

sub text_GET($$;$) {
  my ($url, $msg, $content_type) = @_;
  $content_type ||= 'text/plain';
  my $resp = do_GET($url, $content_type);
  if(! $resp->is_success()) {
    my $code = $resp->code();
    note "Response code for $url was $code";
    fail($msg);
    return;
  }
  return $resp->decoded_content();
}

sub do_GET($;$) {
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