package EnsEMBL::REST::Controller::Lookup;
use Moose;
use namespace::autoclean;
use Try::Tiny;

BEGIN {extends 'Catalyst::Controller::REST'; }

require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

my $FORMAT_TYPES = { full => 1, condensed => 1 };

sub old_id_GET {}

sub old_id : Chained('') Args(1) PathPart('lookup') {
  my ($self, $c, $id) = @_;
  $c->go('/lookup/id', $id);
}

sub id : Chained('') Args(1) PathPart('lookup/id') {
  my ($self, $c, $id) = @_;

  # output format check
  my $include = $c->request->param('include');
  my $format = $c->request->param('format') || 'full';
  $c->go('ReturnError', 'custom', [qq{The format '$format' is not an understood encoding}]) unless $FORMAT_TYPES->{$format};

  my $features;
  try {
    $features = $c->model('Lookup')->find_and_locate_object($id);
    $c->go('ReturnError', 'custom',  [qq{No valid lookup found for ID $id}]) unless $features->{species};
      }
  catch {
    $c->go('ReturnError', 'from_ensembl', [$_]);
  };
  
  $self->status_ok( $c, entity => $features);
}

sub id_GET {}

__PACKAGE__->meta->make_immutable;

1;
