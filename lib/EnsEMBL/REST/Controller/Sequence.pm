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
    'text/fasta'          => [qw/View FASTAText/],
    'text/x-yaml'         => 'YAML',
    'application/json'    => 'JSON',
  }
);
EnsEMBL::REST->turn_on_jsonp(__PACKAGE__);


my %disallowed_seq_serialiser_formats = map { $_ => 1 } ('application/json', 'text/x-yaml');

my %allowed_values = (
  type    => { map { $_, 1} qw(cds cdna genomic)},
  format  => { map { $_, 1} qw(fasta) },
  mask    => { map { $_, 1} qw(soft hard) },
);

sub id_GET { }

sub id :Path('id') Args(1) ActionClass('REST') {
  my ($self, $c, $stable_id) = @_;
  $self->_format_detection($c, $stable_id);
  
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
  $self->_format_detection($c, '');
}

sub region :Chained('get_species') PathPart('') Args(1) ActionClass('REST') {
  my ($self, $c, $region) = @_;
  
  try {
    $c->log()->debug('Finding the Slice');
    my $slice = $c->model('Lookup')->find_slice($c, $region);
    $slice = $self->_enrich_slice($c, $slice);
    $c->log()->debug('Producing the sequence');
    my $seq = $slice->seq();
    $c->stash()->{seq_ref} = \$seq;
    $c->stash()->{molecule} = 'dna';
    $c->stash()->{id} = $slice->name();
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
  my $ref = ref($object);
  my $type = $c->request()->param('type');

  my $seq;
  my $slice;
  my $molecule = 'dna';

  #Translations
  if($object->isa('Bio::EnsEMBL::Translation')) {
    $molecule = 'protein';
    $seq = $object->transcript()->translate()->seq();
  }
  #Transcripts
  elsif($object->isa('Bio::EnsEMBL::Transcript')) {
    if($type eq 'cdna') {
      $seq = $object->spliced_seq();
    }
    elsif($type eq 'cds') {
      $seq = $object->translateable_seq();
    }
    elsif($type eq 'protein') {
      $seq = $object->translate()->seq();
      $molecule = 'protein';
    }
    else {
      $slice = $object->feature_Slice();
    }
  }
  # Anything else
  else {
    $slice = $object->feature_Slice();
  }
  
  if($slice) {
    $slice = $self->_enrich_slice($c, $slice);
    $seq = $slice->seq();
    $s->{desc} = $slice->name();
  }

  $s->{seq_ref} = \$seq;
  $s->{molecule} = $molecule;
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
  $self->status_ok(
    $c, entity => { seq => ${$s->{seq_ref}}, id => $s->{id}, molecule => $s->{molecule}, desc => $s->{desc} }
  );
}

sub _format_detection {
  my ($self, $c, $stable_id) = @_;
  
  my ($id, $format);
  $format = $c->request()->param('format') || undef;
  if ( $stable_id =~ /(.+)\.(fasta+)$/ ) {
    $c->log()->debug("ID '$stable_id' had a format extension");
    $id = $1;
    $format = $2;
  }
  else {
    $id = $stable_id;
  }
  
  if($format && ! $allowed_values{format}{$format}) {
    $c->go( 'ReturnError', 'custom', ["Unsupported format type '$format'"] );
  }
  
  #Sniff the right type out; will go in time 
  if(!$format) {
    $c->log()->debug("Sniffing the correct format from the headers");
    my $content_type = $c->request()->params->{'content-type'} || $c->request()->headers()->content_type() || q{};
    $format = { 'text/fasta' => 'fasta' }->{$content_type};
    #And now optionally dis-regard it if the content type was not one of the above 2
    if ( $format && $disallowed_seq_serialiser_formats{$content_type} ) {
      $c->log->debug("Ignoring output format $format because content type '$content_type' has already been set");
      $format = undef;
    }
    if($format) {
      $c->log->debug("Format is $format");
    }
  }
  
  $c->stash()->{id} = $id;
  $c->stash()->{format} = $format;
  return;
}

sub default_length {
  return 1e7;
}

sub length_config_key {
  return 'Sequence';
}

with 'EnsEMBL::REST::Role::SliceLength';

__PACKAGE__->meta->make_immutable;

1;

