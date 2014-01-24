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

package Catalyst::Action::Serialize::MessagePack;

use Moose;
use namespace::autoclean;

extends 'Catalyst::Action';

use Data::MessagePack;

our $VERSION = '0.0.1';
$VERSION = eval $VERSION;

has encoder => (
  is         => 'ro',
  lazy_build => 1,
  isa        => 'Data::MessagePack', 
);

sub _build_encoder {
  my ( $self, $controller ) = @_;
  my $encoder = Data::MessagePack->new();
  return $encoder;
}

sub execute {
  my ( $self, $controller, $c ) = @_;

  my $stash_key = (
        $controller->{'serialize'}
      ? $controller->{'serialize'}->{'stash_key'}
      : $controller->{'stash_key'}
    )
    || 'rest';
  my $output = $self->serialize( $c->stash->{$stash_key} );
  $c->response->output($output);
  return 1;
}

sub serialize {
  my ($self, $data) = @_;
  return $self->encoder->pack($data);
}

__PACKAGE__->meta->make_immutable;

1;
