=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
Copyright [2016-2017] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

# Inserts a second log handler into a Plack enabled server to handle the access log
# Otherwise Starman (and relatives) can only write to a single log, or else is forced
# to write un-rotateable logs.


package Plack::Middleware::Log4Access;

use strict;
use warnings;
use Plack::Util;
use Plack::Middleware::AccessLog;
use Log::Dispatch::FileRotate;


use parent 'Plack::Middleware::AccessLog';

sub prepare_app {
  my $self = shift;
  # enable access log
  my %config = %{$self};
  delete $config{app};
  $self->{'access.logger'} = Log::Dispatch::FileRotate->new(%$self);

  
  $self->SUPER::prepare_app(@_);
}

sub call {
  my $self = shift;
  my ($env) = @_;

  my $res = $self->app->($env);

  return $self->response_cb($res, sub {
    my $res = shift;
    my $content_length = Plack::Util::content_length($res->[2]);
    my $log_line = $self->log_line($res->[0], $res->[1], $env, { content_length => $content_length });
    if ( my $logger = $self->{'access.logger'} ) {
      $logger->log(level=>'info',message=>$log_line);
    }
    else {
      $env->{'psgi.errors'}->print($log_line);
    }  
  });
}

1;
