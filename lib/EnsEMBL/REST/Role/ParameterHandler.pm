=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::REST::Role::ParameterHandler;

use Moose::Role;
use Bio::EnsEMBL::Mongoose::IOException;

# Usage: my $final_config = $self->merge_configs($c,['id'])
# Merges body parameters with request parameters, (favouring request params)
# Some body params should be ignored, as they are actual data, which we shouldn't be persisting everywhere
sub merge_configs {
  my ($self,$c,$ignore_list) = @_;
  my $params = $c->req->parameters;
  my $body = $c->reg->data;

  # merge the things
  my $body_params = keys %$body;
  my %final_params = (%$body_params,%$params);
  foreach my $dud_key (@$ignore_list) {
    delete $final_params{$dud_key};
  }
  return \%final_params;
}

# For when user config needs to be mixed with server config (e.g. VEP)
# The white list from the controller is used to choose which options can be squished with server options.
sub stamp_on_user_config {
  my ($self, $c, $config, $whitelist) = @_;

  my $short_package_name = ref $self;
  $short_package_name =~ s/(.+::EnsEMBL::REST::)//;
  my $server_config = $c->config->{$short_package_name};
  my %copy = %$server_config;
  # Remove server options from copy prior to merging onto user options
  foreach my $option (@$whitelist) {
    delete $copy{$option} if exists $config->{$option};
  }
  %$config = (%$config, %copy);
  return $config;
}