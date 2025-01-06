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

package Plack::Middleware::EnsThrottle::Hour;

use DateTime;
use parent 'Plack::Middleware::EnsThrottle';

sub key {
  my ( $self, $env ) = @_;
  return $self->_client_id($env) . "_" . DateTime->now->strftime("%Y-%m-%d-%H");
}

sub reset_time {
  my $dt = DateTime->now;
  return (3600 - (( 60 * $dt->minute ) + $dt->second));
}

sub period {
	return 3600;
}

1;
