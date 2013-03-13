package EnsEMBL::REST::View::HTML;
use Moose;
use namespace::autoclean;
use File::Spec;
use Template::Stash::XS;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    RENDER_DIE => 1,
    WRAPPER => 'wrapper.tt',
    COMPILE_DIR => File::Spec->catdir(File::Spec->tmpdir(),'ensrest', $ENV{USER}, 'template_cache'),
    STASH => Template::Stash::XS->new(),
);

1;
