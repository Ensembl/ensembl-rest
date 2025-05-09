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

package EnsEMBL::REST::Role::Active;

use Moose::Role;
use EnsEMBL::REST;

has '_active' => (
  isa     => 'Bool',
  is      => 'ro',
  builder => '_load_active_flag',
  lazy    => 1,
);

sub controller_active {
    my ($self) = @_;

    return $self->_active;
}

sub _load_active_flag {
    my ($self) = @_;

    # translate package name into configuration section name
    my $config_name = ref($self);
    $config_name =~ s/Catalyst:://;
    $config_name =~ s/EnsEMBL::REST:://;

    # Fetch this section of the configuration
    my $config = EnsEMBL::REST->config()->{$config_name};

    if (defined $config && defined $config->{active}) {
	# Initialize the Moose attribute with the config parameter
	return $config->{active};
    } else {
	# Default to controller being active
	return 1;
    }
}

1;
