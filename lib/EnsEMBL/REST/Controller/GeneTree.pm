package EnsEMBL::REST::Controller::GeneTree;
use Moose;
use namespace::autoclean;
use Try::Tiny;
use EnsEMBL::REST;

BEGIN { extends 'Catalyst::Controller::REST'; }

__PACKAGE__->config(
  default => 'text/html',
  map => {
    'text/html'         => [qw/View PhyloXMLHTML/],
    'text/phyloxml'     => [qw/View PhyloXML/],
    'text/nh'           => [qw/View NHTree/],
    'text/nhx'          => [qw/View NHXTree/],
    'application/json'  => [],
    'text/x-yaml'       => [],
    'text/xml'          => [qw/View PhyloXML/],
  }
);

sub get_adaptors : Chained('/') PathPart('genetree') CaptureArgs(0) {
  my ($self, $c) = @_;
  
  my $reg = $c->model('Registry');
  my $default_compara = EnsEMBL::REST->config()->{Compara}->{default_compara};
  my $compara_name = $c->request()->param('compara') || $default_compara;
  
  try {
    my $ma = $reg->get_adaptor($compara_name, 'compara', 'member');
    $c->go('ReturnError', 'custom', ["No member adaptor found for $compara_name"]) unless $ma;
    $c->stash(member_adaptor => $ma);
  
    my $ha = $reg->get_adaptor($compara_name, 'compara', 'homology');
    $c->go('ReturnError', 'custom', ["No homology adaptor found for $compara_name"]) unless $ha;
    $c->stash(homology_adaptor => $ha);
  }
  catch {
    $c->go('ReturnError', 'from_ensembl', [$_]);
  };
}

sub get_genetree_GET { }

sub get_genetree : Chained('get_adaptors') PathPart('id') Args(1) ActionClass('REST') {
  my ($self, $c, $id) = @_;
  my $s = $c->stash();
  my $gt = $c->model('Lookup')->find_genetree_by_stable_id($c, $id);
  $self->status_ok( $c, entity => $gt );
}

__PACKAGE__->meta->make_immutable;

1;
