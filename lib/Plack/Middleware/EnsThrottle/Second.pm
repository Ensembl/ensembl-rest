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

package Plack::Middleware::EnsThrottle::Second;

use Time::HiRes qw//;

use parent 'Plack::Middleware::EnsThrottle';

sub key {
  my ($self, $env) = @_;
  my ($seconds,$microseconds) = Time::HiRes::time();
  return sprintf('%s_%d', $self->_client_id($env),$seconds);
}
 
sub reset_time {
  my ($self) = @_;
  my ($seconds, $microseconds) = Time::HiRes::time;
  #Current millis from microseconds
  my $millis = $microseconds/1000;
  #The time remaining in seconds before we will allow more requests
  my $diff = (1000 - $millis)/1000; 
  return $diff;
}

sub period {
  return 1;
}

1;
