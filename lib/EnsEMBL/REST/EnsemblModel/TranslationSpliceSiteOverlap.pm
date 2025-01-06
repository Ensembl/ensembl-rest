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

package EnsEMBL::REST::EnsemblModel::TranslationSpliceSiteOverlap;

=pod

=head1 NAME

EnsEMBL::REST::EnsemblModel::TranslationSpliceSiteOverlap
 
=head1 DESCRIPTION

Provides a way of accessing splice site information for a translation specifically those
whose codons are held by two different exons

=cut

use Moose;

=head2 ATTRIBUTES

=over 8

=item translation - Translation this splice site is linked to

=item start - The position this feature start at

=back

=cut

has 'start' => (isa => 'Int', is => 'ro', required => 1);
has 'translation' => (isa => 'Str', is => 'ro', required => 1);

=head2 get_by_Translation

  Args [1]    : Bio::EnsEMBL::Translation Translation to calculate splice sites for
  Example     : my $splice_sites = EnsEMBL::REST::EnsemblModel::TranslationSpliceSiteOverlap->get_by_Translation($translation);
  Description : Loops through all available translatable exons and detects those which have their base pairs
                represented by more than one exon
  Returntype  : ArrayRef of TranslationSpliceSiteOverlap objects

=cut

sub get_by_Translation {
  my ($class, $translation) = @_;
  my $id = $translation->stable_id();
  my $transcript = $translation->transcript();
  my $translatable_exons = $transcript->get_all_translateable_Exons();
  my $cdna_length = 0;
  my $protein_length = $translation->length();
  my @objs;
  foreach my $e (@{$translatable_exons}) {
    $cdna_length += $e->length();
    my $overlap_length = $cdna_length % 3;
    my ($position, $residue_overlap);
    if($overlap_length) {
      # Calculating the current length minus the residue_overlap and divide by 3
      # + 1 to get us to the actual splice position
      # e.g. ENSP00000288602
      #      1st residue spanning splice site @ cDNA 608bp (606bp last full codon. 2bp overhang). Peptide coord is 203aa
      #      $overlap_length == 608 % 3 == 2
      #      (608 - 2) == 606
      #      606 / 3 == 202 + 1 == 203
      $position = (($cdna_length - $overlap_length) / 3) + 1;

      if($position < $protein_length) {
        push(@objs, $class->new(start => $position, residue_overlap => $residue_overlap, translation => $id));
      }
    }
  }
  return \@objs;
}

=head2 summary_as_hash

  Example     : my $hash = $obj->summary_as_hash();
  Description : Converts the current object into an unblessed hash fit for
                serialisation purposes
  Returntype  : HashRef Basic representation of the current object

=cut

sub summary_as_hash {
  my ($self) = @_;
  my $summary = { 
    start => $self->start(), 
    end => $self->start(),
    seq_region_name => $self->translation(),
  };
  return $summary;
}

=head2 SO_term

  Description : Returns the SO term trans_splice_site
  Returntype  : String the SO term trans_splice_site

=cut

sub SO_term {
  my ($self) = @_;
  return 'SO:0001420'; #trans_splice_site
}

1;
