package EnsEMBL::REST::EnsemblModel::ExonTranscript;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::Utils::Proxy/;

sub new {
  my ($class, $proxy_exon, $transcript) = @_;
  my $self = $class->SUPER::new($proxy_exon);
  $self->{transcript} = $transcript;
  return $self;
}

sub build_all_from_Transcript {
  my ($class, $transcript) = @_;
  my $exons = $transcript->get_all_Exons();
  my $rank = 1;
  my @results;
  foreach my $exon (@{$exons}) {
    my $et = $class->new($exon, $transcript);
    $et->rank($rank++);
    push(@results, $et);
  }
  return @results;
}

sub rank {
  my ($self, $rank) = @_;
  $self->{'rank'} = $rank if defined $rank;
  return $self->{'rank'};
}

sub transcript {
  my ($self, $transcript) = @_;
  $self->{'transcript'} = $transcript if defined $transcript;
  return $self->{'transcript'};
}

sub summary_as_hash {
  my ($self) = @_;
  my $proxy = $self->__proxy();
  my $exon_summary = $proxy->summary_as_hash();
  $exon_summary->{Parent} = $self->transcript()->stable_id;
  $exon_summary->{rank} = $self->rank();
  return $exon_summary;
}

sub SO_term {
  my ($self) = @_;
  return 'SO:0000147';
}

sub __resolver {
  my ($invoker, $package, $method) = @_;
  return sub {
    my ($self, @args);
    return $self->$method(@args);
  };
}

1;