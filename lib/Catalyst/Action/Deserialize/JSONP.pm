package Catalyst::Action::Deserialize::JSONP;
 
use Moose;
use namespace::autoclean;
 
extends 'Catalyst::Action::Deserialize::JSON';
 
__PACKAGE__->meta->make_immutable;

1;