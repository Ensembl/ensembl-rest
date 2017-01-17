=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2017] EMBL-European Bioinformatics Institute

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

# This is a partial re-write of the trait to support correct Accepts behaviour

package Catalyst::TraitFor::Request::REST;
use Moose::Role;
use HTTP::Headers::Util qw(split_header_words);
use namespace::autoclean;

# VERSION

has [qw/ data accept_only /] => ( is => 'rw' );

has accepted_content_types => (
    is       => 'ro',
    isa      => 'ArrayRef',
    lazy     => 1,
    builder  => '_build_accepted_content_types',
    init_arg => undef,
);

has preferred_content_type => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    builder  => '_build_preferred_content_type',
    init_arg => undef,
);

has priority_listings => (
    is        => 'ro',
    isa       => 'HashRef',
    lazy      => 1,
    builder   => '_build_priority_listings',
    init_arg  => undef,
);

sub _build_accepted_content_types {
    my $self = shift;
    my $priority = $self->priority_listings()->{$self->method()};
    my %types;

    $types{ $self->content_type } = $priority->{content_type}
        if $self->content_type;

    if ($self->method eq "GET" && $self->param('content-type')) {
        $types{ $self->param('content-type') } = $priority->{content_type_param};
    }

    # Third, we parse the Accept header, and see if the client
    # takes a format we understand.
    #
    # This is taken from chansen's Apache2::UploadProgress.
    if ( $self->header('Accept') ) {
        $self->accept_only(1) unless keys %types;

        my $accept_header = $self->header('Accept');
        my $counter       = 0;

        foreach my $pair ( split_header_words($accept_header) ) {
            my ( $type, $qvalue ) = @{$pair}[ 0, 3 ];
            next if $types{$type};

            # cope with invalid (missing required q parameter) header like:
            # application/json; charset="utf-8"
            # http://tools.ietf.org/html/rfc2616#section-14.1
            unless ( defined $pair->[2] && lc $pair->[2] eq 'q' ) {
                $qvalue = undef;
            }

            unless ( defined $qvalue ) {
                $qvalue = $priority->{accept} - ( ++$counter / 1000 );
            }

            $types{$type} = sprintf( '%.3f', $qvalue );
        }
    }

    [ sort { $types{$b} <=> $types{$a} } keys %types ];
}

sub _build_preferred_content_type { $_[0]->accepted_content_types->[0] }

sub _build_priority_listings {
  my ($self) = @_;
  my $highest_priority= 3;
  my $medium_priority = 2;
  my $lowest_priority = 1;
  my $default = { accept => $lowest_priority, content_type => $highest_priority, content_type_param =>  $medium_priority};
  return {
    GET => $default,
    OPTIONS => $default,
    PUT => $default,
    DELETE => $default,
    TRACE => $default,
    CONNECT => $default,
    HEAD => $default,
    POST => { accept => $highest_priority, content_type => $medium_priority, content_type_param =>  $lowest_priority},
  };
}

sub accepts {
    my $self = shift;
    my $type = shift;

    return grep { $_ eq $type } @{ $self->accepted_content_types };
}

1;
__END__

=head1 NAME

Catalyst::TraitFor::Request::REST - A role to apply to Catalyst::Request giving it REST methods and attributes.

=head1 SYNOPSIS

     if ( $c->request->accepts('application/json') ) {
         ...
     }

     my $types = $c->request->accepted_content_types();

=head1 DESCRIPTION

This is a L<Moose::Role> applied to L<Catalyst::Request> that adds a few
methods to the request object to facilitate writing REST-y code.
Currently, these methods are all related to the content types accepted by
the client.

=head1 METHODS

=over

=item data

If the request went through the Deserializer action, this method will
return the deserialized data structure.

=item accepted_content_types

Returns an array reference of content types accepted by the
client.

The list of types is created by looking at the following sources:

=over 8

=item * Content-type header

If this exists, this will always be the first type in the list.

=item * content-type parameter

If the request is a GET request and there is a "content-type"
parameter in the query string, this will come before any types in the
Accept header.

=item * Accept header

This will be parsed and the types found will be ordered by the
relative quality specified for each type.

=back

If a type appears in more than one of these places, it is ordered based on
where it is first found.

=item preferred_content_type

This returns the first content type found. It is shorthand for:

  $request->accepted_content_types->[0]

=item accepts($type)

Given a content type, this returns true if the type is accepted.

Note that this does not do any wildcard expansion of types.

=back

=head1 AUTHORS

See L<Catalyst::Action::REST> for authors.

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut

