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

package Plack::Middleware::EnsemblRestHeaders;

use strict;
use warnings;
use parent qw/Plack::Middleware/;
use Plack::Util;
use EnsEMBL::REST;

=head2 call

Adds Ensembl REST specific headers to the response. At the moment this is just the REST API's version.

=cut

sub call {
  my $self = shift; 
  my $res  = $self->app->(@_);

  $self->response_cb($res, sub {
  	my $local_res = shift;
  	my $headers = $local_res->[1];
  	Plack::Util::header_set($headers, 'X-Ensembl-REST-Version', $EnsEMBL::REST::VERSION);
  	return;
  });
}

1;
