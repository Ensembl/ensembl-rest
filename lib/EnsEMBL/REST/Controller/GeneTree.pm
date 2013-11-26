=head1 LICENSE

Copyright [1999-2013] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::REST::Controller::GeneTree;
use Moose;
use namespace::autoclean;
use Try::Tiny;
use EnsEMBL::REST::Builder::TreeHash;
require EnsEMBL::REST;

BEGIN { extends 'Catalyst::Controller::REST'; }

__PACKAGE__->config(
  default => 'text/html',
  map => {
    'text/html'           => [qw/View PhyloXMLHTML/],
    'text/x-phyloxml+xml' => [qw/View PhyloXML/],
    'text/x-phyloxml'     => [qw/View PhyloXML/], #naughty but needs must
    'text/x-nh'           => [qw/View NHTree/],
    'text/xml'            => [qw/View PhyloXML/],
  }
);

EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

#We want to find every "non-special" format. To generate the regex used then invoke this command:
#perl -MRegexp::Assemble -e 'my $ra = Regexp::Assemble->new; $ra->add($_) for qw(application\/json text\/javascript application\/x-sereal text\/x-yaml application\/x-msgpack); print $ra->re, "\n"'
my $CONTENT_TYPE_REGEX = qr/(?-xism:(?:application\/(?:x-(?:msgpack|sereal)|json)|text\/(?:javascript|x-yaml)))/;

sub get_genetree_GET { }

sub get_genetree : Chained('/') PathPart('genetree/id') Args(1) ActionClass('REST') {
  my ($self, $c, $id) = @_;
  my $s = $c->stash();
  my $gt = $c->model('Lookup')->find_genetree_by_stable_id($id);
  $self->_set_genetree($c, $gt);
}

sub get_genetree_by_member_id_GET { }

sub get_genetree_by_member_id : Chained('/') PathPart('genetree/member/id') Args(1) ActionClass('REST') {
  my ($self, $c, $id) = @_;
   
  my $gt = $c->model('Lookup')->find_genetree_by_member_id($id);
  $c->go('ReturnError', 'custom', ["Could not fetch GeneTree"]) unless $gt;
  $self->_set_genetree($c, $gt);
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
  $self->_set_genetree($c, $gt);
}

sub _set_genetree {
  my ($self, $c, $gt) = @_;

  if($self->is_content_type($c, $CONTENT_TYPE_REGEX)) {
    # If it wasn't a special format convert GT into a Hash data structure and let the normal serialisation
    # code deal with it.
    my $builder = EnsEMBL::REST::Builder::TreeHash->new();
    $builder->aligned(1) if $c->request()->param('aligned') || $c->request()->param('phyloxml_aligned');
    my $sequence = $c->request->param('sequence') || $c->request()->param('phyloxml_sequence') || 'protein';
    $builder->cdna(1) if $sequence eq 'cdna';
    $builder->no_sequences(1) if $sequence eq 'none';
    $gt->preload();
    my $hash = $builder->convert($gt);
    return $self->status_ok($c, entity => $hash);
  }
  return $self->status_ok($c, entity => $gt);
}

with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;
