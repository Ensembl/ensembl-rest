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

package EnsEMBL::REST::Controller::Documentation;

use Moose;
use namespace::autoclean;
require EnsEMBL::REST;
use Bio::EnsEMBL::ApiVersion qw/software_version/;

BEGIN { extends 'Catalyst::Controller'; }

sub begin : Private {
  my ($self, $c) = @_;
  my $endpoints = $c->model('Documentation')->merged_config($c);
  $c->stash()->{endpoints} = $endpoints;
  my $cfg = EnsEMBL::REST->config();
  $c->stash(
    site_name => $cfg->{site_name},
    service_name => $cfg->{service_name},
    service_logo => $cfg->{service_logo},
    service_parent_url => $cfg->{service_parent_url},
    user_guide => $cfg->{user_guide},
    service_version => $EnsEMBL::REST::VERSION,
    ensembl_version => software_version(),
    copyright_footer => $cfg->{copyright_footer},
    wiki_url => $cfg->{wiki_url},
    bootstrap_css => $cfg->{bootstrap_css},
  );
  return;
}

sub index :Path :Args(0) {
  my ($self, $c) = @_;
  $c->stash()->{groups} = $c->model('Documentation')->get_groups();
  $c->stash()->{template_title} = $c->stash()->{service_name}.' Endpoints';
}

sub info :Path('info') :Args(1) {
  my ($self, $c, $endpoint) = @_;
  my $endpoint_cfg = $c->stash()->{endpoints}->{$endpoint};
  if($endpoint_cfg) {
    $endpoint_cfg = $c->model('Documentation')->enrich($endpoint_cfg);
    $c->stash()->{endpoint} = $endpoint_cfg;
    $c->stash()->{template_title} = join(',',@{ $endpoint_cfg->{method} } ) . ' ' . $endpoint_cfg->{endpoint};
  }
  else {
    $c->response->status(404);
    $c->stash()->{template} = 'documentation/no_info.tt';
    $c->stash()->{template_title} = "Endpoint '${endpoint}' Documentation Cannot Be Found";
  }
  return;
}

sub change_log :Path('change_log') {
  my ($self, $c, $endpoint) = @_;
  $c->stash()->{template_title} = 'Change Log';
  return;
}

1;
