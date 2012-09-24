package EnsEMBL::REST::EnsemblModel::CDS;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::Feature/;
use Bio::EnsEMBL::Utils::Scalar qw/assert_ref/;

sub new_from_Transcripts {
  my ($class, $transcripts) = @_;
  my @cds_features;
  foreach my $transcript (@{$transcripts}) {
    my $translatable_exons = $transcript->get_all_translateable_Exons();
    foreach my $exon (@{$translatable_exons}) {
      my $obj = $class->new($transcript, $exon);
      push(@cds_features, $obj);
    }
  }
  return \@cds_features;
}

sub new {
  my ($class, $transcript, $exon) = @_;
  my $self = $class->SUPER::new();
  $self->transcript($transcript);
  $self->translateable_exon($exon);
  return $self;
}

sub transcript {
  my ($self, $transcript) = @_;
  $self->{'transcript'} = $transcript if defined $transcript;
  return $self->{'transcript'};
}

sub translateable_exon {
  my ($self, $translateable_exon) = @_;
  $self->{'translateable_exon'} = $translateable_exon if defined $translateable_exon;
  return $self->{'translateable_exon'};
}

sub seq_region_name {
  my ($self) = @_;
  return $self->transcript()->seq_region_name();
}

sub seq_region_start {
  my ($self) = @_;
  return $self->translateable_exon()->seq_region_start();
}

sub strand {
  my ($self) = @_;
  return $self->transcript()->strand();
}

sub seq_region_end {
  my ($self) = @_;
  return $self->translateable_exon()->seq_region_end();
}

sub summary_as_hash {
  my ($self) = @_;
  my $summary = $self->SUPER::summary_as_hash();
  $summary->{Parent} = $self->transcript()->stable_id;
  $summary->{ID} = $self->transcript()->translation->stable_id();
  $summary->{phase} = 0;
  return $summary;
}

sub SO_term {
  my ($self) = @_;
  return 'SO:0000316'; #CDS
}

1;