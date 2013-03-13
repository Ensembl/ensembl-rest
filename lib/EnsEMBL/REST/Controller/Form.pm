package EnsEMBL::REST::Controller::Form;
use Moose;
use namespace::autoclean;

require EnsEMBL::REST;
use Bio::EnsEMBL::ApiVersion qw/software_version/;
BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

EnsEMBL::REST::Controller::form - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched EnsEMBL::REST::Controller::form in form.');
}


sub chained :Path('chained') {
  my ($self, $c, $endpoint) = @_;
  $c->stash()->{template_title} = 'Endpoint Chaining form';
  return;
}

=head1 AUTHOR

,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
