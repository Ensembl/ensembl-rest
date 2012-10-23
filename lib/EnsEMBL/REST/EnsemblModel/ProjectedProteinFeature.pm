package EnsEMBL::REST::EnsemblModel::ProjectedProteinFeature;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::Utils::Proxy/;

sub new_from_Features {
  my ($class, $features) = @_;
  my @protein_features;
  foreach my $feature (@{$features}) {
    my $ppf = $class->new($feature);
    push(@protein_features, $ppf);
  }
  return @protein_features;
}

sub new {
  my ($class, $proxy_feature, $transcript) = @_;
  my $self = $class->SUPER::new($proxy_feature);
  $self->{transcript} = $transcript;
  return $self;
}

sub _coords {
  my ($self) = @_;
  return $self->{_coords} if $self->{_coords};
  my $proxy = $self->__proxy();
  my $transcript = $self->{transcript};
  my ($sr_start, $sr_end, $sr_strand) = $proxy->$_() for qw(start end strand);
  my @coords = grep { ! $_->isa('Bio::EnsEMBL::Mapper::Gap') } $transcript->genomic2pep($sr_start, $sr_end, $sr_strand);
  $self->{_coords} = {
    start => $coords[0]->start(),
    end => $coords[-1]->end()
  };
  return $self->{_coords};
}

sub seq_region_start {
  my ($self) = @_;
  return $self->_coords()->{start};
}

sub strand {
  my ($self) = @_;
  return 1;
}

sub seq_region_end {
  my ($self) = @_;
  return $self->_coords()->{end};
}


1;