#!/usr/bin/env perl

use File::Slurp;
use JSON qw/decode_json/;
use Perl6::Form;

#JSON must be retrieved from the JIRA REST endpoint

my $content = read_file($ARGV[0]);
my $hash = decode_json($content);

my %issues = ( 'Bugfixes' => [], 'New Features' => []);

foreach my $issue (@{$hash->{issues}}) {
  my $fields = $issue->{fields};
  my $summary = $fields->{summary};
  my $issue_type = $fields->{issuetype}->{name};
  my $target = { 'Bug' => 'Bugfixes', 'New Feature' => 'New Features'}->{$issue_type};
  push(@{$issues{$target}}, $summary);
}

format_for_file();
format_for_html();

sub format_for_file {
  foreach my $type (q/New Features/, 'Bugfixes') {
    my $sorted_issues = [sort @{$issues{$type}}];
    next unless @{$sorted_issues};
    print $type.":\n\n";
    foreach my $issue (@{$sorted_issues}) {
      my $bullet = '-';
      print form "  {>} {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
        $bullet, $issue,
        "\n";
    }
    print "\n";
  }
}

sub format_for_html {
  foreach my $type (q/New Features/, 'Bugfixes') {
    my $sorted_issues = [sort @{$issues{$type}}];
    next unless @{$sorted_issues};
    print "<h3>$type</h3>\n";
    print "<ul>\n";
    foreach my $issue (@{$sorted_issues}) {
      $issue =~ s/(\[[a-z\/_:]+\])/<tt>$1<\/tt>/g;
      print "\t<li>${issue}</li>\n";
    }
    print "</ul>\n";
    print "\n";
  }
}