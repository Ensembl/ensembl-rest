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

sub get_genetree_by_member_id_GET { }

sub get_genetree_by_member_id : Chained('/') PathPart('genetree/member/id') Args(1) ActionClass('REST') {
  my ($self, $c, $id) = @_;
   
  my $gt = $c->model('Lookup')->find_genetree_by_member_id($c,$id);
  $c->go('ReturnError', 'custom', ["Could not fetch GeneTree"]) unless $gt;
  
  $self->status_ok( $c, entity => $gt);
}


sub get_genetree_by_symbol_GET { }

sub get_genetree_by_symbol : Chained('/') PathPart('genetree/member/symbol') Args(2) ActionClass('REST') {
  my ($self, $c, $species, $symbol) = @_;

  my $reg = $c->model('Registry');
  
  my $gene_adaptor = $reg->get_adaptor($species, 'core', 'Gene');
  my $gene = $gene_adaptor->fetch_by_display_label($symbol);
  $c->go('ReturnError','custom', ["Given symbol $symbol not found in Gene table"]) unless $gene;
  
  my $gt = $c->model('Lookup')->find_genetree_by_member_id($c,$gene->stable_id);
  $c->go('ReturnError', 'custom', ["Could not fetch GeneTree for $symbol"]) unless $gt;
  $self->status_ok( $c, entity => $gt);
}

__PACKAGE__->meta->make_immutable;

1;
