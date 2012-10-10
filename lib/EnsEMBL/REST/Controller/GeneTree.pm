package EnsEMBL::REST::Controller::GeneTree;
use Moose;
use namespace::autoclean;
use Try::Tiny;
require EnsEMBL::REST;

BEGIN { extends 'Catalyst::Controller::REST'; }

__PACKAGE__->config(
  default => 'text/html',
  map => {
    'text/html'           => [qw/View PhyloXMLHTML/],
    'text/x-phyloxml+xml' => [qw/View PhyloXML/],
    'text/x-phyloxml'     => [qw/View PhyloXML/], #naughty but needs must
    'text/x-nh'           => [qw/View NHTree/],
    'text/x-nhx'          => [qw/View NHXTree/],
    'application/json'    => [],
    'text/x-yaml'         => [],
    'text/xml'            => [qw/View PhyloXML/],
  }
);

sub get_genetree_GET { }

sub get_genetree : Chained('/') PathPart('genetree/id') Args(1) ActionClass('REST') {
  my ($self, $c, $id) = @_;
  my $s = $c->stash();
  my $gt = $c->model('Lookup')->find_genetree_by_stable_id($c, $id);
  $self->status_ok( $c, entity => $gt );
}

__PACKAGE__->meta->make_immutable;

1;
