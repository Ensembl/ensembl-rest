=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
Copyright [2016-2025] EMBL-European Bioinformatics Institute

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
