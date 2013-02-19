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
   
  my $compara_name = $c->request->parameters->{compara}; 
  my $reg = $c->model('Registry');
  
  my ($species, $type, $db) = $c->model('Lookup')->find_object_location($c, $id);
  
  $c->go('ReturnError', 'custom', ["Unable to find given object: $id"]) unless $species;
  
  my $r = $c->request;
    
  my $dba = $reg->get_best_compara_DBAdaptor($c,$species,$compara_name);
  my $ma = $dba->get_MemberAdaptor;
  my $member = $ma->fetch_by_source_stable_id('ENSEMBLGENE',$id);
  $c->go('ReturnError', 'custom', ["Could not fetch GeneTree Member"]) unless $member;
  
  my $gta = $dba->get_GeneTreeAdaptor;
  my $gt = $gta->fetch_default_for_Member($member);
  $c->go('ReturnError', 'custom', ["Could not fetch GeneTree"]) unless $gt;
  
  $self->status_ok( $c, entity => $gt);
}

__PACKAGE__->meta->make_immutable;

1;
