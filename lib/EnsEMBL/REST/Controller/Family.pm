
=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
Copyright [2016-2018] EMBL-European Bioinformatics Institute

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

package EnsEMBL::REST::Controller::Family;
use Moose;
use namespace::autoclean;
use Try::Tiny;
use Bio::EnsEMBL::Compara::Utils::FamilyHash;

require EnsEMBL::REST;


BEGIN { extends 'Catalyst::Controller::REST'; }

__PACKAGE__->config(
  default => 'text/html',
  map => {
    'text/x-orthoxml+xml' => [qw/View OrthoXML_family/],
  }
);

EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);
#We want to find every "non-special" format. To generate the regex used then invoke this command:
#perl -MRegexp::Assemble -e 'my $ra = Regexp::Assemble->new; $ra->add($_) for qw(application\/json text\/javascript text\/xml ); print $ra->re, "\n"'
my $CONTENT_TYPE_REGEX = qr/(?^:(?:text\/(?:javascript|xml)|application\/json))/;


my $FORMAT_LOOKUP = { full => 1, condensed => 1 };

sub get_family_GET { }

sub get_family : Chained('/') PathPart('family/id') Args(1) ActionClass('REST') {
  my ($self, $c, $id) = @_;
  my $s = $c->stash();
  my $format = $c->request->param('format') || 'full';
  my $target = $FORMAT_LOOKUP->{$format};
  $c->go('ReturnError', 'custom', [qq{The format '$format' is not an understood encoding}]) unless $target;

  try { 
    my $fam = $c->model('Lookup')->find_family_by_stable_id($id);
    $self->_load_family($c, $fam);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  }
}

sub get_family_by_member_id_GET { }

sub get_family_by_member_id : Chained('/') PathPart('family/member/id') Args(1) ActionClass('REST') {
  my ($self, $c, $id) = @_;
  try {
    my $fam = $c->model('Lookup')->find_family_by_member_id($id);
    $self->_load_family($c, $fam);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  }
}

sub get_family_by_symbol_GET { }

sub get_family_by_symbol : Chained('/') PathPart('family/member/symbol') Args(2) ActionClass('REST') {
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
  
  try {
    my $fam = $c->model('Lookup')->find_family_by_member_id($stable_id);
    $self->_load_family($c, $fam);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  }
}

sub _load_family {
  my ($self, $c, $fam) = @_;  
  my $member_source   = $c->request->param('member_source') || 'all';
  my $aligned         = $c->request->param('aligned') // 1;
  my $cigar_line      = $c->request->param('cigar_line') // 1;
  my $sequence_param  = $c->request()->param('sequence') || 'protein';
  my $no_seq          = $sequence_param eq 'none' ? 1 : 0;
  my $seq_type        = $sequence_param eq 'protein' ? undef : 'cds';
  
  if($self->is_content_type($c, $CONTENT_TYPE_REGEX)) {
    my $hash;
    if (ref $fam ne 'ARRAY') { 
      $fam->preload();
      $hash = Bio::EnsEMBL::Compara::Utils::FamilyHash->convert($fam, -MEMBER_SOURCE => $member_source, -ALIGNED => $aligned, -NO_SEQ => $no_seq, -SEQ_TYPE => $seq_type, -CIGAR_LINE => $cigar_line );
    } else {
      my %hash_tmp;
      my $i = 0;
      foreach my $f (@$fam) {
        $f->preload();
        my $h = Bio::EnsEMBL::Compara::Utils::FamilyHash->convert($f, -MEMBER_SOURCE => $member_source, -ALIGNED => $aligned, -NO_SEQ => $no_seq, -SEQ_TYPE => $seq_type, -CIGAR_LINE => $cigar_line);
        $hash_tmp{++$i} = $h;
      }
      $hash = \%hash_tmp;
    }
    return $self->status_ok($c, entity => $hash);
  }
  $fam->preload();
  return $self->status_ok($c, entity => $fam);
}

with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;

