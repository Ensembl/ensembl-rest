package EnsEMBL::REST::EnsemblModel::TranscriptVariation;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::Utils::Proxy/;
use Bio::EnsEMBL::Utils::Scalar qw/assert_ref split_array/;


sub new {
  my ($class, $proxy_vf, $transcript_variant, $rank) = @_;
  my $self = $class->SUPER::new($proxy_vf);
  $self->{translation_start} = $transcript_variant->translation_start;
  $self->{translation_id} = $transcript_variant->transcript->translation->stable_id;
  $self->{ID} = $proxy_vf->variation_name;
  $self->{type} = $transcript_variant->display_consequence;
  $self->{allele} = $proxy_vf->allele_string(undef);
  return $self;
}


sub new_from_variation_feature {
  my ($class, $vf, $tv) = @_;
  my $vf_obj = $class->new($vf, $tv);
  return $vf_obj;
}


sub type {
  my ($self, $type) = @_;
  $self->{'type'} = $type if defined $type;
  return $self->{'type'};
}

sub allele {
  my ($self, $allele) = @_;
  $self->{'allele'} = $allele if defined $allele;
  return $self->{'allele'};
}

sub translation_id {
  my ($self, $translation_id) = @_;
  $self->{'translation_id'} = $translation_id if defined $translation_id;
  return $self->{'translation_id'};
}

sub translation_start {
  my ($self, $translation_start) = @_;
  $self->{'translation_start'} = $translation_start if defined $translation_start;
  return $self->{'translation_start'};
}

sub ID {
  my ($self, $id) = @_;
  $self->{'ID'} = $id if defined $id;
  return $self->{'ID'};
}

sub summary_as_hash {
  my ($self) = @_;
  my $summary;
#  my $summary = $self->SUPER::summary_as_hash();
  $summary->{ID} = $self->ID;
  $summary->{start} = $self->translation_start;
  $summary->{translation} = $self->translation_id;
  $summary->{allele} = $self->allele;
  $summary->{type} = $self->type;
  return $summary;
}

1;
