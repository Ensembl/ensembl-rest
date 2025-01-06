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

package EnsEMBL::REST::EnsemblModel::TranscriptVariation;

use strict;
use warnings;

use Bio::EnsEMBL::Utils::Scalar qw/assert_ref split_array/;

sub new {
  my ($class, $proxy_vf, $transcript_variant, $rank) = @_;
  my $self = bless({}, $class);
  my $tva = $transcript_variant->get_all_alternate_TranscriptVariationAlleles->[0];
  $self->{translation_start} = $transcript_variant->translation_start;
  $self->{translation_end} = $transcript_variant->translation_end;
  $self->{translation_id} = $transcript_variant->transcript->translation->stable_id;
  $self->{ID} = $proxy_vf->variation_name;
  $self->{type} = $transcript_variant->display_consequence;
  $self->{allele} = $proxy_vf->allele_string(undef);
  $self->{codon} = $transcript_variant->codons;
  $self->{residues} = $transcript_variant->pep_allele_string;
  $self->sift($tva->sift_score);
  $self->{polyphen} = $tva->polyphen_score;
  $self->{parent} = $transcript_variant->transcript->stable_id();
  $self->minor_allele_frequency($proxy_vf->minor_allele_frequency);
  $self->{clinical_significance} = \@{$proxy_vf->get_all_clinical_significance_states};
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

sub minor_allele_frequency {
  my ($self, $minor_allele_frequency) = @_;
  $self->{'minor_allele_frequency'} = $minor_allele_frequency - 0 if defined $minor_allele_frequency;
  return $self->{'minor_allele_frequency'};
}

sub sift {
  my ($self, $sift) = @_;
  $self->{'sift'} = $sift - 0 if defined $sift;
  return $self->{'sift'};
}

sub polyphen {
  my ($self, $polyphen) = @_;
  $self->{'polyphen'} = $polyphen if defined $polyphen;
  return $self->{'polyphen'};
}

sub allele {
  my ($self, $allele) = @_;
  $self->{'allele'} = $allele if defined $allele;
  return $self->{'allele'};
}

sub codon {
  my ($self, $codon) = @_;
  $self->{'codon'} = $codon if defined $codon;
  return $self->{'codon'};
}

sub residues {
  my ($self, $residues) = @_;
  $self->{'residues'} = $residues if defined $residues;
  return $self->{'residues'};
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

sub translation_end {
  my ($self, $translation_end) = @_;
  $self->{'translation_end'} = $translation_end if defined $translation_end;
  return $self->{'translation_end'};
}

sub parent {
  my ($self, $parent) = @_;
  $self->{'parent'} = $parent if defined $parent;
  return $self->{'parent'};
}

sub ID {
  my ($self, $id) = @_;
  $self->{'ID'} = $id if defined $id;
  return $self->{'ID'};
}

sub clinical_significance{
  my ($self, $clinical_significance) = @_;
  $self->{clinical_significance} = $clinical_significance if defined $clinical_significance;
  return $self->{clinical_significance};
}

sub summary_as_hash {
  my ($self) = @_;
  my $summary = {};
  $summary->{id} = $self->ID;
  $summary->{start} = $self->translation_start || 0;
  $summary->{end} = $self->translation_end || 0;
  $summary->{translation} = $self->translation_id;
  $summary->{allele} = $self->allele;
  $summary->{type} = $self->type;
  $summary->{codons} = $self->codon;
  $summary->{residues} = $self->residues;
  $summary->{sift} = $self->sift;
  $summary->{polyphen} = $self->polyphen;
  $summary->{Parent} = $self->parent;
  $summary->{minor_allele_frequency} = $self->minor_allele_frequency;
  $summary->{clinical_significance} = $self->{clinical_significance} ;

  $summary->{seq_region_name} = $summary->{translation};
  return $summary;
}

sub SO_term {
  my ($self) = @_;
  return 'SO:0001146'; # polypeptide_variation_site
}

=head seq_region_name

  Description : Returns the stable id of the current Translation
  Returntype  : A fake slice name which is just the stable id of the attached Translation

=cut

sub seq_region_name {
  my ($self) = @_;
  return $self->translation_id();
}

=head seq_region_start

  Description : Returns the start of the current attached variation feature
  Returntype  : A start which is just the variation feature's

=cut

sub seq_region_start {
  my ($self) = @_;
  return $self->translation_start() || 0;
}

=head seq_region_end

  Description : Returns the start of the current attached variation feature
  Returntype  : A start which is just the variation feature's

=cut

sub seq_region_end {
  my ($self) = @_;
  return $self->translation_start() || 0;
}

=head seq_region_strand

  Description : Returns the strand of the current attached protein feature
  Returntype  : A strand which is just the protein feature's

=cut

sub seq_region_strand {
  my ($self) = @_;
  return 1;
}

=head display_id

  Description : Returns the display id of the feature
  Returntype  : String display identifier

=cut

sub display_id {
  my ($self) = @_;
  return $self->ID();
}

1;
