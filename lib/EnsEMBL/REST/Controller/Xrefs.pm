=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
Copyright [2016-2025] EMBL-European Bioinformatics Institute

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

package EnsEMBL::REST::Controller::Xrefs;
use Moose;
use namespace::autoclean;
use feature "switch";
require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);
use Try::Tiny;

BEGIN {extends 'Catalyst::Controller::REST'; }


# Expect 3 URLs coming from this class
#   - /xrefs/symbol/:species/:symbol
#   - /xrefs/id/:id
#   - /xrefs/name/:species/:name
# 
# Respond to params
#   - external_db='HGNC'
#   - db_type=core (might need to look in another DB)
#
# For /id/
#   - db_type=core
#   - object=gene
#   - species=human
#   - all_levels=1
#
# For /name

sub id_GET {}

sub id :Chained('/') PathPart('xrefs/id') Args(1)  ActionClass('REST') {
  my ($self, $c, $id) = @_;
  $c->stash()->{id} = $id;
  try {
    $c->log()->debug('Finding the object');
    my $obj = $c->model('Lookup')->find_object_by_stable_id($id);
    $c->log()->debug('Processing the Xrefs');
    my $method = $c->request()->param('all_levels') ? 'get_all_DBLinks' : 'get_all_DBEntries';
    my $can = $obj->can($method);
    if(!$can) {
      my $msg = sprintf('The object type "%s" for ID "%s" cannot respond to the given request for Xrefs. Are you sure it has them?', ref($obj), $id);
      $c->log()->debug($msg);
      $c->go('ReturnError', 'custom', [$msg]);
    }
    my @args = ($obj);
    push(@args, $c->request->param('external_db')) if $c->request->param('external_db');
    my $entries = $can->(@args);
    $c->stash(entries => $entries);
    $c->forward('_encode');
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  $self->status_ok($c, entity => $c->stash->{entity});
}

sub symbol_GET {}

sub symbol :Chained('/') PathPart('xrefs/symbol') Args(2) ActionClass('REST') {
  my ($self, $c, $species, $symbol) = @_;
  $c->stash(species => $species, symbol => $symbol);
  my $db_type = $c->request->param('db_type');
  unless ($db_type) {
      $db_type = 'core';
      $c->request->param('db_type',$db_type);
  }
  my @entries;
  try {
    my $objects_linked_to_name = $c->model('Lookup')->find_objects_by_symbol($symbol);
    while(my $obj = shift @{$objects_linked_to_name}) {
      my $encoded = {
        id => $obj->stable_id(),
        type => lc( [split(/::/,ref($obj))]->[-1] )
      }; # type is classname trimmed down, e.g. Bio::EnsEMBL::Gene -> gene
      push(@entries, $encoded);
    }
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  $self->status_ok( $c, entity => \@entries);
}

sub name_GET {}

sub name :Chained('/') PathPart('xrefs/name') Args(2) ActionClass('REST') {
  my ($self, $c, $species, $name) = @_;
  $c->stash(species => $species, name => $name);
  my $external_db = $c->request->param('external_db');
  my $db_type = $c->request->param('db_type') || 'core';
  try {
    my $dbentry_adaptor = $c->model('Registry')->get_adaptor($species, $db_type, 'dbentry');
    my $entries = $dbentry_adaptor->fetch_all_by_name($name, $external_db);
    $c->stash(entries => $entries);
    $c->forward('_encode');
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  $self->status_ok($c, entity => $c->stash->{entity});
}

sub _encode :Private {
  my ($self, $c) = @_;
  my @encoded;
  foreach my $dbe (@{$c->stash()->{entries}}) {
    my $enc = {
      dbname          => $dbe->dbname(),
      db_display_name => $dbe->db_display_name(),
      display_id      => $dbe->display_id(),
      primary_id      => $dbe->primary_id(),
      description     => $dbe->description(),
      synonyms        => $dbe->get_all_synonyms(),
      version         => $dbe->version(),
      info_type       => $dbe->info_type(),
      info_text       => $dbe->info_text(),
    };
    if (ref($dbe) eq 'Bio::EnsEMBL::IdentityXref') {
        $enc->{xref_identity}     = ($dbe->xref_identity()*1);
        $enc->{xref_start}        = ($dbe->xref_start()*1);
        $enc->{xref_end}          = ($dbe->xref_end()*1);
        $enc->{ensembl_identity}  = ($dbe->ensembl_identity()*1);
        $enc->{ensembl_start}     = ($dbe->ensembl_start()*1);
        $enc->{ensembl_end}       = ($dbe->ensembl_end()*1);
        $enc->{score}             = ($dbe->score()*1);
        $enc->{evalue}            = $dbe->evalue();
        $enc->{cigar_line}        = $dbe->cigar_line() if $dbe->cigar_line();
        $enc->{evalue}            = ($enc->{evalue}*1) if defined $enc->{evalue}; 
    } elsif (ref($dbe) eq 'Bio::EnsEMBL::OntologyXref') {
        $enc->{linkage_types} = $dbe->get_all_linkage_types();
    }
    push(@encoded, $enc);
  }
  $c->stash(entity => \@encoded);
}

__PACKAGE__->meta->make_immutable;

1;
