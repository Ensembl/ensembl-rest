package EnsEMBL::REST::View::HTML;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    RENDER_DIE => 1,
    WRAPPER => 'wrapper.tt'
);

1;
