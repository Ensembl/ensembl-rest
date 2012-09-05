package Catalyst::Action::Serialize::YAML::XS;

use Moose;
use namespace::autoclean;

extends 'Catalyst::Action';
use YAML::XS;

our $VERSION = '1.00';
$VERSION = eval $VERSION;

sub execute {
    my $self = shift;
    my ( $controller, $c ) = @_;

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
    my $self = shift;
    my $data = shift;
    Dump($data);
}

__PACKAGE__->meta->make_immutable;

1;
