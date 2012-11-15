package TapAppender;

use strict;
use warnings;
use base qw/Log::Log4perl::Appender/;
use Test::Builder;

sub new {
  my ($class, @options) = @_;

  my $self = {
    name   => "unknown name",
    note => 1,
    @options,
  };

  bless $self, $class;
}

sub log {
  my ($self, %params) = @_;
  my $b = Test::Builder->new;
  if($self->{note}) {
    $b->note($params{message});
  }
  else {
    $b->diag($params{message});
  }
  return;
}

1;
