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
  my $gt = $c->model('Lookup')->find_genetree_by_stable_id($id);
  $self->status_ok( $c, entity => $gt );
}

sub get_genetree_by_member_id_GET { }

sub get_genetree_by_member_id : Chained('/') PathPart('genetree/member/id') Args(1) ActionClass('REST') {
  my ($self, $c, $id) = @_;
   
  my $gt = $c->model('Lookup')->find_genetree_by_member_id($id);
  $c->go('ReturnError', 'custom', ["Could not fetch GeneTree"]) unless $gt;
  
  $self->status_ok( $c, entity => $gt);
}


sub get_genetree_by_symbol_GET { }

sub get_genetree_by_symbol : Chained('/') PathPart('genetree/member/symbol') Args(2) ActionClass('REST') {
  my ($self, $c, $species, $symbol) = @_;
  $c->stash(species => $species);
  my $object_type = $c->request->param('object_type');
  unless ($object_type) {$c->request->param('object_type','gene')};
  unless ($c->request->param('db_type') ) {$c->request->param('db_type','core')}; 
  
  my @objects = @{$c->model('Lookup')->find_objects_by_symbol($symbol) };
  my @genes = grep { $_->slice->is_reference() } @objects;
  $c->log()->debug(scalar(@genes). " objects found with symbol: ".$symbol);
  $c->go('ReturnError', 'custom', ["Lookup found nothing."]) unless (@genes && scalar(@genes) > 0);
  
  my $stable_id = $genes[0]->stable_id;
  
  my $gt = $c->model('Lookup')->find_genetree_by_member_id($stable_id);
  $c->go('ReturnError', 'custom', ["Could not fetch GeneTree for $symbol,$stable_id"]) unless $gt;
  $self->status_ok( $c, entity => $gt);
}

__PACKAGE__->meta->make_immutable;

1;
