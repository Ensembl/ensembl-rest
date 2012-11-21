package Catalyst::Action::Serialize::Sereal;

use Moose;
use namespace::autoclean;

extends 'Catalyst::Action';

use Sereal::Encoder ();

our $VERSION = '0.0.1';
$VERSION = eval $VERSION;

has encoder => (
  is         => 'ro',
  lazy_build => 1,
  isa        => 'Sereal::Encoder', 
);

sub _build_encoder {
  my ( $self, $controller ) = @_;
  my $encoder = Sereal::Encoder->new();
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
  $self->encoder->encode($data);
}

__PACKAGE__->meta->make_immutable;

1;
