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
EnsEMBL::REST->turn_on_jsonp(__PACKAGE__);

has 'max_slice_length' => ( isa => 'Num', is => 'ro', default => 1e7);

my %allowed_values = (
  type    => { map { $_, 1} qw(cds cdna genomic protein)},
  mask    => { map { $_, 1} qw(soft hard) },
);

my $DEFAULT_TYPE = 'genomic';

sub id_GET { }

sub id :Path('id') Args(1) ActionClass('REST') {
  my ($self, $c, $stable_id) = @_;
  $c->stash->{id} = $stable_id;
  
  try {
    $c->log()->debug('Finding the object');
    $c->model('Lookup')->find_object_by_stable_id($c, $c->stash()->{id});
    $c->log()->debug('Processing the sequences');
    $self->_process($c);
    $c->log()->debug('Pushing out the entity');
    $self->_write($c);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [$_]);
  };
  return;
}

sub region_GET { }

sub get_species :Chained('/') PathPart('sequence/region') CaptureArgs(1) {
  my ($self, $c, $species) = @_;
  $c->stash()->{species} = $species;
}

sub region :Chained('get_species') PathPart('') Args(1) ActionClass('REST') {
  my ($self, $c, $region) = @_;
  
  try {
    $c->log()->debug('Finding the Slice');
    my $slice = $c->model('Lookup')->find_slice($c, $region);
    $slice = $self->_enrich_slice($c, $slice);
    $c->log()->debug('Producing the sequence');
    my $seq = $slice->seq();
    $c->stash()->{sequences} = [{
      id => $slice->name(),
      molecule => 'dna',
      seq => $seq,
    }];
    $c->log()->debug('Pushing out the entity');
    $self->_write($c);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [$_]);
  };
  return;
}

sub _process {
  my ($self, $c) = @_;
  my $s = $c->stash();
  my $object = $s->{object};
  my $type = $c->request()->param('type') || $DEFAULT_TYPE;
  my $multiple_sequences = $c->request->param('multiple_sequences');
  
  $c->go('ReturnError', 'custom', ["The type '$type' is not understood by this service"]) unless $allowed_values{type}{$type};
  
  
  my $sequences = $self->_process_feature($c, $object, $type);
  my $sequence_count = scalar(@{$sequences});
  if($sequence_count > 1 && ! $multiple_sequences) {
    my $err;
    if($object->isa('Bio::EnsEMBL::Gene') && $type ne 'genomic') {
      $err = qq{Requesting a gene and type not equal to "genomic" can result in multiple sequences. $sequence_count sequencs detected.};
    }
    elsif($object->isa('Bio::EnsEMBL::Transcript') && ! $object->isa('Bio::EnsEMBL::PredictionTranscript') && $type eq 'protein') {
      $err = qq{Requesting a transcript and type "protein" can result in multiple sequences. $sequence_count sequences detected.};
    }
    $c->go('ReturnError', 'custom', ["$err Please rerun your request and specify the multiple_sequences parameter"]) if $err;
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
  
  #Translations
  if($object->isa('Bio::EnsEMBL::Translation')) {
    $molecule = 'protein';
    $seq = $object->transcript()->translate()->seq();
  }
  #Transcripts
  elsif($object->isa('Bio::EnsEMBL::PredictionTranscript')) {
    if($type eq 'cdna') {
      $seq = $object->spliced_seq();
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
      $seq = $object->spliced_seq();
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
    $seq = $slice->seq();
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

sub _write {
  my ($self, $c) = @_;
  my $s = $c->stash();
  if($c->request->param('multiple_sequences')) {
    $self->status_ok($c, entity => $c->stash()->{sequences});
  }
  else {
    $self->status_ok($c, entity => $c->stash()->{sequences}->[0]);
  }
}

with 'EnsEMBL::REST::Role::SliceLength';
with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;

