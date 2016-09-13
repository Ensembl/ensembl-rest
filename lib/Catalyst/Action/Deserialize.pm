package Catalyst::Action::Deserialize;

use Moose;
use namespace::autoclean;

extends 'Catalyst::Action::SerializeBase';
use Module::Pluggable::Object;
use MRO::Compat;
use Moose::Util::TypeConstraints;

our $VERSION = '1.11';
$VERSION = eval $VERSION;

has plugins => ( is => 'rw' );

has deserialize_http_methods => (
    traits  => ['Hash'],
    isa     => do {
        my $tc = subtype as 'HashRef[Str]';
        coerce $tc, from 'ArrayRef[Str]',
            via { +{ map { ($_ => 1) } @$_ } };
        $tc;
    },
    coerce  => 1,
    builder => '_build_deserialize_http_methods',
    handles => {
        deserialize_http_methods         => 'keys',
        _deserialize_handles_http_method => 'exists',
    },
);

sub _build_deserialize_http_methods { [qw(POST PUT OPTIONS DELETE)] }

sub execute {
    my $self = shift;
    my ( $controller, $c ) = @_;

    if ( !defined($c->req->data) && $self->_deserialize_handles_http_method($c->request->method) ) {
        my ( $sclass, $sarg, $content_type ) =
          $self->_load_content_plugins( 'Catalyst::Action::Deserialize',
            $controller, $c );
        return 1 unless defined($sclass);
        my $rc;
        if ( defined($sarg) ) {
            $rc = $sclass->execute( $controller, $c, $sarg );
        } else {
            $rc = $sclass->execute( $controller, $c );
        }
        if ( $rc eq "0" ) {
            return $self->unsupported_media_type( $c, $content_type );
        } elsif ( $rc ne "1" ) {
            return $self->serialize_bad_request( $c, $content_type, $rc );
        }
    }

    $self->maybe::next::method(@_);

    return 1;
}


sub _load_content_plugins {
    my $self = shift;
    my ( $search_path, $controller, $c ) = @_;

    unless ( defined( $self->_loaded_plugins ) ) {
        $self->_loaded_plugins( {} );
    }

    # Load the Serialize Classes
    unless ( defined( $self->_serialize_plugins ) ) {
        my @plugins;
        my $mpo =
          Module::Pluggable::Object->new( 'search_path' => [$search_path], );
        @plugins = $mpo->plugins;
        $self->_serialize_plugins( \@plugins );
    }

    # Finally, we load the class.  If you have a default serializer,
    # and we still don't have a content-type that exists in the map,
    # we'll use it.
    my $sclass = $search_path . "::";
    my $sarg;
    my $map;

    my $config;

    if ( exists $controller->{'serialize'} ) {
        $c->log->info("Catalyst::Action::REST - deprecated use of 'serialize' for configuration.");
        $c->log->info("Please see 'CONFIGURATION' in Catalyst::Controller::REST.");
        $config = $controller->{'serialize'};
        # if they're using the deprecated config, they may be expecting a
        # default mapping too.
        $config->{map} ||= $controller->{map};
    } else {
        $config = $controller;
    }
    $map = $config->{'map'};

    # For deserializing, force content-type to be application/json
    my $content_type = 'application/json';

    return $self->unsupported_media_type($c, $content_type)
        if not $content_type;

    # carp about old text/x-json
    if ($content_type eq 'text/x-json') {
        $c->log->info('Using deprecated text/x-json content-type.');
        $c->log->info('Use application/json instead!');
    }

    if ( exists( $map->{$content_type} ) ) {
        my $mc;
        if ( ref( $map->{$content_type} ) eq "ARRAY" ) {
            $mc   = $map->{$content_type}->[0];
            $sarg = $map->{$content_type}->[1];
        } else {
            $mc = $map->{$content_type};
        }
        $sclass .= $mc;
        if ( !grep( /^$sclass$/, @{ $self->_serialize_plugins } ) ) {
            return $self->unsupported_media_type($c, $content_type);
        }
    } else {
        return $self->unsupported_media_type($c, $content_type);
    }
    unless ( exists( $self->_loaded_plugins->{$sclass} ) ) {
        my $load_class = $sclass;
        $load_class =~ s/::/\//g;
        $load_class =~ s/$/.pm/g;
        eval { require $load_class; };
        if ($@) {
            $c->log->error(
                "Error loading $sclass for " . $content_type . ": $!" );
            return $self->unsupported_media_type($c, $content_type);
        } else {
            $self->_loaded_plugins->{$sclass} = 1;
        }
    }

    return $sclass, $sarg, $content_type;
}

__PACKAGE__->meta->make_immutable;

1;
