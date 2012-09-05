package EnsEMBL::REST::Controller::Root;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::REST' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(
  namespace => '',
);

sub index : Path : Args(0) {
  my ( $self, $c ) = @_;
  $c->go('EnsEMBL::REST::Controller::Documentation','index');
}

=head2 default

Standard 404 error page

=cut

sub default : Path {
  my ( $self, $c ) = @_;
  my $url = $c->uri_for('/');
  $c->go( 'ReturnError', 'not_found', [qq{page not found. Please check your uri and refer to our documentation $url}] );
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

__PACKAGE__->meta->make_immutable;

1;
