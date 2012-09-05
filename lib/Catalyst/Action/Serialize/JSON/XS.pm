package Catalyst::Action::Serialize::JSON::XS;

use Moose;
use namespace::autoclean;

extends 'Catalyst::Action::Serialize::JSON';
use JSON::XS ();

our $VERSION = '0.91';
$VERSION = eval $VERSION;

sub _build_encoder {
    my $self = shift;

    my $json = JSON->new->utf8->allow_blessed->convert_blessed(1);

    return $json;

    #   return JSON::XS->new->convert_blessed;
}

__PACKAGE__->meta->make_immutable;

1;
