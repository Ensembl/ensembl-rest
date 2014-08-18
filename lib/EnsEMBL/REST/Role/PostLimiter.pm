=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::REST::Role::PostLimiter;

use Moose::Role;
use EnsEMBL::REST;
use Data::Dumper;

has 'max_post_size' => (
  isa => 'Int',
  is => 'ro',
  builder => '_load_post_conf',
  lazy => 1,
);

sub _load_post_conf {
  my ($self) = @_;
  # translate package name into configuration section name
  my $config_name = ref($self);
  $config_name =~ s/Catalyst:://;
  $config_name =~ s/EnsEMBL::REST:://;
  my %config = %{ EnsEMBL::REST->config()->{$config_name} };
  return $config{max_post_size};
}

sub assert_post_size {
  my ($self, $c, $list) = @_;
  my $max_size = $self->max_post_size;
  return unless $max_size;
  my $post_size = scalar @$list;

  if($post_size > $max_size) {
    my $msg = "POST message too large. You have submitted $post_size elements but a limit of $max_size in place. Request smaller regions of sequence";
    $c->go('ReturnError', 'custom', [qq{$msg}]);
  }
  return;
}

1;