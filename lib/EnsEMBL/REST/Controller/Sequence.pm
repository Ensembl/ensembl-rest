=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::REST::Controller::Sequence;

use Moose;
use namespace::autoclean;

use Try::Tiny;
require EnsEMBL::REST;

BEGIN { extends 'Catalyst::Controller::REST'; }
with 'EnsEMBL::REST::Role::PostLimiter';
__PACKAGE__->config(
  map => {
    'text/html'           => [qw/View FASTAHTML/],
    'text/plain'          => [qw/View SequenceText/],
    'text/x-fasta'        => [qw/View FASTAText/],
    'text/x-seqxml+xml'   => [qw/View SeqXML/],
    'text/x-seqxml'       => [qw/View SeqXML/], #naughty but needs must
  }
);
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

has 'max_slice_length' => ( isa => 'Num', is => 'ro', default => 1e7);

my %allowed_values = (
  type    => { map { $_, 1} qw(cds cdna genomic protein)},
  mask    => { map { $_, 1} qw(soft hard) },
);

my $DEFAULT_TYPE = 'genomic';

sub id_GET { 
  my ($self, $c, $stable_id) = @_;
  $c->stash->{id} = $stable_id;

  try {
    $c->log()->debug('Finding the object');
    $c->model('Lookup')->find_object_by_stable_id($c->stash()->{id});
    $c->log()->debug('Processing the sequences');
    $self->_process($c);
    $c->log()->debug('Pushing out the entity');
    $self->_write($c);
  } catch {
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
}

sub id :Path('id') ActionClass('REST') {
  my ($self, $c, $stable_id) = @_;
  $c->stash->{id} = $stable_id;
  if ($c->request->param('mask') && $c->request->param('mask_feature')) {
    $c->go('ReturnError', 'custom', [qq{'You cannot mask both repeats and features on the same sequence'}]);
  }
  return;
}

sub id_POST { 
  my ($self, $c) = @_;
  my $post_data = $c->req->data;
  my $id_list = $post_data->{'ids'};
  $self->assert_post_size($c,$id_list);

  my @errors;
  $c->request->params->{'multiple_sequences'} = 1;
  # Force multiple sequences on, since the user has undoubtedly submitted many things.
  foreach my $id (@$id_list) {
    try {
      $c->model('Lookup')->find_object_by_stable_id($id);
      $self->_process($c);
    } ;
  }
  $self->_write($c);
  if (@errors) { $c->go('ReturnError', 'custom', [join(',',@errors)]) };
}


sub get_species :Chained('/') PathPart('sequence/region') CaptureArgs(1) {
  my ($self, $c, $species) = @_;
  $c->stash()->{species} = $species;
}

sub region_GET {
  my ($self, $c, $region) = @_;
  try {
    $self->_get_region_sequence($c,$region);
  } catch {
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  $self->_write($c);
}

sub region_POST {
  my ($self, $c) = @_;
  my $post_data = $c->req->data;
  my $regions = $post_data->{'regions'};
  $self->assert_post_size($c,$regions);
  my @errors;
  try {
    foreach my $reg (@$regions) {
      $self->_get_region_sequence($c,$reg);
    }
  };
  $self->_write($c);
}

sub region :Chained('get_species') PathPart('') ActionClass('REST') {
  my ($self, $c) = @_;
  if ($c->req->param('mask') && $c->req->param('mask_feature')) {
    $c->go('ReturnError', 'custom', [qq{'You cannot mask both repeats and features on the same sequence'}]);
  }
}

sub _get_region_sequence {
  my ($self, $c, $region) = @_;
  my $seq_stash = $c->stash()->{sequences};
  my ($sr_name) = $c->model('Lookup')->decode_region( $region );
  my $slice = $c->model('Lookup')->find_slice($region);
  $slice = $self->_enrich_slice($c, $slice);
  my $seq = $self->_mask_slice_features($slice, $c);
  push @$seq_stash, {
    id => $slice->name(),
    molecule => 'dna',
    seq => $seq,
  };
  $c->stash()->{sequences} = $seq_stash;
}

sub _process {
  my ($self, $c) = @_;
  my $s = $c->stash();
  my $object = $s->{object};
  my $type = $c->request()->param('type') || $DEFAULT_TYPE;
  my $multiple_sequences = $c->request->param('multiple_sequences');
  
  Catalyst::Exception->throw(qq{The type '$type' is not understood by this service}) unless $allowed_values{type}{$type};
  
  my $sequences = $self->_process_feature($c, $object, $type);
  my $sequence_count = scalar(@{$sequences});
  if($sequence_count > 1 && ! $multiple_sequences) {
    my $err;
    if($object->isa('Bio::EnsEMBL::Gene') && $type ne 'genomic') {
      $err = qq{Requesting a gene and type not equal to "genomic" can result in multiple sequences. $sequence_count sequences detected.};
    }
    elsif($object->isa('Bio::EnsEMBL::Transcript') && ! $object->isa('Bio::EnsEMBL::PredictionTranscript') && $type eq 'protein') {
      $err = qq{Requesting a transcript and type "protein" can result in multiple sequences. $sequence_count sequences detected.};
    }
    Catalyst::Exception->throw(qq{$err Please rerun your request and specify the multiple_sequences parameter}) if $err;
  }
  if ($sequence_count == 0) {
    Catalyst::Exception->throw(qq{No sequences returned, please check the type specified is compatible with the object requested});
  }
  if (exists $s->{sequences}) {
    my $existing_seq = $s->{sequences};
    unshift @$sequences,@$existing_seq;
  }
  $s->{sequences} = $sequences;
  return;
}

sub _process_feature {
  my ($self, $c, $object, $type) = @_;
  
  my @sequences;
  
  my $molecule = 'dna';
  my $seq;
  my $slice;
  my $desc;
  my $mask_feature = $c->request->param('mask_feature');
  
  #Translations
  if($object->isa('Bio::EnsEMBL::Translation')) {
    $molecule = 'protein';
    $seq = $object->transcript()->translate()->seq();
  }
  #Transcripts
  elsif($object->isa('Bio::EnsEMBL::PredictionTranscript')) {
    if($type eq 'cdna') {
      $seq = $object->spliced_seq($mask_feature);
    }
    elsif($type eq 'cds') {
      $seq = $object->translateable_seq();
    }
    elsif($type eq 'protein') {
      $molecule = 'protein';
      $seq = $object->translate()->seq();
    }
  }
  elsif($object->isa('Bio::EnsEMBL::Transcript')) {
    if($type eq 'cdna') {
      $seq = $object->spliced_seq($mask_feature);
    }
    elsif($type eq 'cds') {
      $seq = $object->translateable_seq();
    }
    #If protein perform recursive calls with the Translation object 
    elsif($type eq 'protein') {
      my @translations = ($object->translation());
      push(@translations, @{$object->get_all_alternative_translations()});
      foreach my $t (@translations) {
        next unless $t;
        push(@sequences, @{$self->_process_feature($c, $t, $type)});
      }
    }
    elsif($type eq 'genomic') {
      $slice = $object->feature_Slice();
    }
    else {
      $c->go('ReturnError', 'custom', ["The type $type is not understood"]);
    }
  }
  elsif($object->isa('Bio::EnsEMBL::Gene')) {
    #If type was not genomic then recursivly call this method with all transcripts
    if($type ne 'genomic') {
      my $transcripts = $object->get_all_Transcripts();
      foreach my $transcript (@{$transcripts}) {
        push(@sequences, @{$self->_process_feature($c, $transcript, $type)});
      }
    }
    else {
      $slice = $object->feature_Slice();
    }
  }
  # Anything else (like exon)
  else {
    $slice = $object->feature_Slice();
  }
  
  if($slice) {
    $slice = $self->_enrich_slice($c, $slice);
    $seq = $self->_mask_slice_features($slice, $c, $type, $object);
    $desc = $slice->name();
  }
  
  if($seq) {
    push(@sequences, {
      id => $object->stable_id(),
      seq => $seq,
      molecule => $molecule,
      desc => $desc 
    });
  }
  
  return \@sequences;
}

sub _enrich_slice {
  my ($self, $c, $slice) = @_;
  $slice = $self->_expand_slice($c, $slice);
  $slice = $self->_mask_slice($c, $slice);
  $self->assert_slice_length($c, $slice);
  return $slice;
}

sub _expand_slice {
  my ($self, $c, $slice) = @_;
  my $five = $c->request()->param('expand_5prime') || 0;
  my $three = $c->request()->param('expand_3prime') || 0;
  if($five || $three) {
    return $slice->expand($five, $three);
  }
  return $slice;
}

sub _mask_slice {
  my ($self, $c, $slice) = @_;
  my $mask = $c->request()->param('mask') || q{};
  my $soft_mask = ($mask eq 'soft') ? 1 : 0;
  if($mask) {
    $c->go('ReturnError', 'custom', ["'$mask' is not an allowed value for masking"]) unless $allowed_values{mask}{$mask};
    return $slice->get_repeatmasked_seq(undef, $soft_mask);
  }
  return $slice;
}

sub _mask_slice_features {
  my ($self, $slice, $c, $type, $object) = @_;
  my $seq = $slice->seq();
  my @features;
  if ($c->request()->param('mask_feature')) {
    if (defined $type) {
      if ($type eq 'genomic' && !$object->isa('Bio::EnsEMBL::Exon')) {
        @features = @{ $object->get_all_Introns() };
        $slice->_mask_features(\$seq, \@features, 1);
      }
    } else {
      @features = @{ $slice->get_all_Exons() };
      $slice->_mask_features(\$seq, \@features, 1);
      # Exons have been softmasked, invert casing
      $seq =~ tr/ACGTacgt/acgtACGT/;
    }
  }
  return $seq; 
}

sub _write {
  my ($self, $c) = @_;
  my $s = $c->stash();
  my $data = $s->{sequences};
  if ((defined $data && scalar @$data == 0) || !defined $data) {
    $self->status_not_found($c, message => 'No results found');
  }
  if($c->request->param('multiple_sequences')) {
    $self->status_ok($c, entity => $data);
  }
  else {
    $self->status_ok($c, entity => $data->[0]);
  }
}

with 'EnsEMBL::REST::Role::SliceLength';
with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;

