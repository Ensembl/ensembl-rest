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

package EnsEMBL::REST::Controller::Sequence;

use Moose;
use namespace::autoclean;

use Try::Tiny;
require EnsEMBL::REST;

BEGIN { extends 'Catalyst::Controller::REST'; }
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

# This list describes user overridable variables for this endpoint. It protects other more fundamental variables
has valid_user_params => ( 
  is => 'ro', 
  isa => 'HashRef', 
  traits => ['Hash'], 
  handles => { valid_user_param => 'exists' },
  default => sub { return { map {$_ => 1} (qw/
    multiple_sequences
    start
    end
    type
    expand_5prime
    expand_3prime
    mask_feature
    mask
    /) }
  }
);

has 'max_slice_length' => ( isa => 'Num', is => 'ro', default => 1e7);

has allowed_values => (isa => 'HashRef', is => 'ro', default => sub {{
  type => { map { $_, 1} qw(cds cdna genomic protein) },
  mask => { map { $_, 1} qw(soft hard) }
}});

with 'EnsEMBL::REST::Role::PostLimiter','EnsEMBL::REST::Role::SliceLength','EnsEMBL::REST::Role::Content';

my $DEFAULT_TYPE = 'genomic';

sub id_GET { 
  my ($self, $c, $stable_id) = @_;
  $c->stash->{id} = $stable_id;

  try {
    $c->log()->debug('Finding the object');
    $c->model('Lookup')->find_object_by_stable_id($c->stash()->{id});
    $c->log()->debug('Processing the sequences');
    $self->_process($c, $stable_id);
    $c->log()->debug('Pushing out the entity');
    $self->_write($c);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
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
  $self->_include_user_params($c,$post_data);

  my @errors;
  $c->request->params->{'multiple_sequences'} = 1;
  # Force multiple sequences on, since the user has undoubtedly submitted many things.
  foreach my $id (@$id_list) {
    try {
      $c->model('Lookup')->find_object_by_stable_id($id);
      $self->_process($c, $id);
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
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  $self->_write($c);
}

sub region_POST {
  my ($self, $c) = @_;
  my $post_data = $c->req->data;
  my $regions = $post_data->{'regions'};
  $self->assert_post_size($c,$regions);
  $c->request->params->{'multiple_sequences'} = 1; # required by _write to allow multiple hits.
  $self->_include_user_params($c,$post_data);
  my @errors;
  foreach my $reg (@$regions) {
    $c->log->debug($reg);
    try {
      $self->_get_region_sequence($c,$reg);
    };
  }
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
    query => $region,
    seq => $seq,
  };
  $c->stash()->{sequences} = $seq_stash;
}

sub _process {
  my ($self, $c, $id) = @_;
  my $s = $c->stash();
  my $object = $s->{object};
  my $type = $c->request()->param('type') || $DEFAULT_TYPE;
  my $multiple_sequences = $c->request->param('multiple_sequences');
  
  Catalyst::Exception->throw(qq{The type '$type' is not understood by this service}) unless $self->allowed_values->{type}{$type};
  
  if($c->request->param('start') || $c->request->param('end')) {
      # We don't support circular features at this time, if it's a circular
      # feature, and not a translation, throw an error.
      unless($object->isa('Bio::EnsEMBL::Translation')) {
        my $feat_slice = $object->feature_Slice();
        Catalyst::Exception->throw(qq{Circular slices aren't supported for sequence trimming at this time}) if($feat_slice->is_circular());
      }

      # It doesn't make sense to expand the sequence when doing a sub-sequence
      if($c->request->param('expand_5prime') || $c->request->param('expand_3prime')) {
        Catalyst::Exception->throw(qq{You may not expand the 3prime or 5prime sequence end when requesting a sub-sequence});
      }

      # Remember this for later when we're processing the object
      $s->{dosubseq} = 1;
  }

  my $sequences = $self->_process_feature($c, $object, $type, $id);
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
  my ($self, $c, $object, $type, $id) = @_;
  
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
      # Grab the subsequence if we've been asked to trim the ends
    }
    elsif($type eq 'cds') {
      $seq = $object->translateable_seq();
      # Grab the subsequence if we've been asked to trim the ends
    }
    elsif($type eq 'protein') {
      $molecule = 'protein';
      $seq = $object->translate()->seq();
      # It's a protein that's been requested so we have to translate
      # the coordinates first
      $self->_translate_coordinates($c, $object) if($c->stash()->{dosubseq});
    }
    elsif($type eq 'genomic') {
      $slice = $object->feature_Slice();
    }
  }
  elsif($object->isa('Bio::EnsEMBL::Transcript')) {
    if($type eq 'cdna') {
      $seq = $object->spliced_seq($mask_feature);
    }
    elsif($type eq 'cds') {
      $seq = $object->translateable_seq();
      # We might not have a translatable sequence, be sure
      # we do before attempting to trim
    }
    #If protein perform recursive calls with the Translation object 
    elsif($type eq 'protein') {
      # If we're retreiving a subsequence, try to translate the coordinates
      # to the peptide if needed
      $self->_translate_coordinates($c, $object) if($c->stash()->{dosubseq});

      my @translations = ($object->translation());
      push(@translations, @{$object->get_all_alternative_translations()});
      foreach my $t (@translations) {
        # Catch case where no translation is available for a transcript
        next unless $t;

        push(@sequences, @{$self->_process_feature($c, $t, $type, $id)});
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
        # Because each transcript will have different coordinates if
        # we're asking for a protein, we have to save the original
        # coordinates before we translate them each cycle
        $self->_push_start_end($c) if($c->stash()->{dosubseq});
        push(@sequences, @{$self->_process_feature($c, $transcript, $type, $id)});
        $self->_pop_start_end($c) if($c->stash()->{dosubseq});
      }
    }
    else {
      $slice = $object->feature_Slice();
    }
  }
  # Anything else (like exon)
  else {
    # Special case, it doesn't make sense to try and fetch coding sequence from an exon,
    # we have no idea which transcript the exon is associated with. So throw an error.
    if($object->isa('Bio::EnsEMBL::Exon') && (($type eq 'cds') || ($type eq 'protein'))) {
      $c->go('ReturnError', 'custom', ["The type $type can not be use when retrieving an Exon"]);
    }

    $slice = $object->feature_Slice();
  }
  
  if($slice) {
    # If the user set limits on the range they wanted, process that
    if($c->stash()->{dosubseq}) {
      my ($start, $end) = $self->_check_limits($c, $slice->length());
      $slice = $slice->sub_Slice($start, $end);
      $c->stash()->{dosubseq} = 0;
    }

    $slice = $self->_enrich_slice($c, $slice);
    $seq = $self->_mask_slice_features($slice, $c, $type, $object);
    $desc = $slice->name();
  }
  
  if($seq) {
    # Grab the subsequence if we've been asked to trim the ends

    $seq = $self->_process_subseq($c, $seq) if($c->stash()->{dosubseq});

    push(@sequences, {
      id => $object->stable_id(),
      version => $object->version(),
      seq => $seq,
      molecule => $molecule,
      query => $id,
      desc => $desc 
    });
  }
  return \@sequences;
}

# For grabbing the sub-sequence if requested
# The start and end coordinates come from the user request
sub _process_subseq {
  my ($self, $c, $seq) = @_;

  my $seq_len = length $seq;

  # Get our start/end points and do some sanity checking
  my ($start, $end) = $self->_check_limits($c, $seq_len);

  # Deal with zero indexing, we do the minus one here rather than the
  # sanity checking routine so the sanity checking routine can be
  # reused for the Slice() execution path where we need a default
  # start of 1.
  return substr $seq, $start-1, $end-$start+1;
}

# Check the trimming start/end we're given by the user to ensure
# they make sense, and fill in sensible default if one is left out.
sub _check_limits {
  my ($self, $c, $seq_len) = @_;

  # Oh the fun of zero indexing strings in a one-indexed sub-sequence world
  my $start = $c->request->param('start') ? $c->request->param('start') : 1;
  my $end = defined($c->request->param('end')) ? $c->request->param('end') : $seq_len;

  # Sanity checking
  if($start < 0 || $start > $seq_len) {
      Catalyst::Exception->throw(qq{Your start coordinate is not within the sequence requested})
  }

  if($end < 1 || $end > $seq_len + 1) {
      Catalyst::Exception->throw(qq{Your end coordinate is not within the sequence requested})
  }

  if($start > $end) {
      Catalyst::Exception->throw(qq{Your start coordinate cannot be larger than your end})
  }

  return ($start, $end);
}

# For grabbing the sub-sequence for a protein sequence from
# a translation object. The object type in our stash must
# be a Bio::EnsEMBL::PredictionTranscript or Bio::EnsEMBL::Transcript
sub _translate_coordinates {
  my ($self, $c, $obj) = @_;

  # Return if we've already translated the coordinates
  return if($c->stash->{coordstranslated});

  # Do we have a translation?
  return unless($obj->translate());

  my $start; my $end;
  if($obj->strand() == 1) {
      $start = $c->request->param('start') ? $c->request->param('start') + $obj->seq_region_start() - 1 : $obj->seq_region_start();
      $end = $c->request->param('end') ? $obj->seq_region_start() + $c->request->param('end') : $obj->seq_region_end();
  } else {
      # Things get a little messy if we're on the reverse strand, we have to count from
      # opposite ends.
      $end = $c->request->param('start') ? $obj->seq_region_end() - $c->request->param('start') : $obj->seq_region_end();
      $start = $c->request->param('end') ? $obj->seq_region_end() - $c->request->param('end') : $obj->seq_region_start();
  }

  my $transcript_mapper = $obj->get_TranscriptMapper();

  # Grab the coordinates for the peptide sequence that maps from
  # this subsequence of the transcript
  my @coords = $transcript_mapper->genomic2pep($start, $end, $obj->strand());

  # Go through and build the coordinates from the pieces returned
  my $pep_start = length $obj->translate()->seq(); my $pep_end = 0;
  foreach my $coord (@coords) {
      if($coord->isa('Bio::EnsEMBL::Mapper::Coordinate')) {
          $pep_start = $coord->start if($coord->start < $pep_start);
          $pep_end = $coord->end if($coord->end > $pep_end);
      }
  }

  # See if we don't find any peptide sequence in this window, so
  # no coordinates should be returned.
  if($pep_end < $pep_start) {
      $c->request->params->{'start'} = 0;
      $c->request->params->{'end'} = 0;
  } else {
      $c->request->params->{'start'} = $pep_start;
      $c->request->params->{'end'} = $pep_end;
  }

  # Remember we've translated the coordinates so we don't try again
  $c->stash->{coordstranslated} = 1;
}

# For the fustrating flow where you're going from a Gene and are outputting
# protein sequences, we obviously need a different mapping for each transcript
# so we have to stash away the originally reqested start/end. The alternative
# would have been a lot more conditions and paramters to the other calls.
sub _push_start_end {
  my ($self, $c) = @_;

  $c->stash->{orig_start} = $c->request->param('start') if($c->request->param('start'));
  $c->stash->{orig_end} = $c->request->param('end') if($c->request->param('end'));
}

sub _pop_start_end {
  my ($self, $c) = @_;

  $c->request->params->{'start'} = $c->stash->{orig_start} ? $c->stash->{orig_start} : undef;
  $c->request->params->{'end'} = $c->stash->{orig_end} ? $c->stash->{orig_end} : undef;

  $c->stash->{coordstranslated} = 0;
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
    $c->go('ReturnError', 'custom', ["'$mask' is not an allowed value for masking"]) unless $self->allowed_values->{mask}{$mask};
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
    return;
  }
  if($c->request->param('multiple_sequences')) {
    $self->status_ok($c, entity => $data);
  }
  else {
    $self->status_ok($c, entity => $data->[0]);
  }
}

sub _include_user_params {
  my ($self,$c,$user_config) = @_;

  foreach my $key (keys %$user_config) {
    if ($self->valid_user_param($key)) {
      $c->request->params->{$key} = $user_config->{$key};
    }
  }
}

__PACKAGE__->meta->make_immutable;

1;

