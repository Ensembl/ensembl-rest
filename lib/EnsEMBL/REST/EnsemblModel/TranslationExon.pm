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

package EnsEMBL::REST::EnsemblModel::TranslationExon;

=pod

=head1 NAME

EnsEMBL::REST::EnsemblModel::TranslationExon
 
=head1 DESCRIPTION

Provides a way of accessing exon information for a translation

=cut

use Moose;

=head2 ATTRIBUTES

=over 8

=item translation - Translation this exon is linked to. Only specify the stable ID

=item exon - The exon to be linked. Only specify the stable ID

=item start - The start of this exon in aa coordinates

=item end - The end of this exon in aa coordinates

=item rank - The position of this codon in the coding sequence

=back

=cut

has 'start' => (isa => 'Int', is => 'ro', required => 1);
has 'end' => (isa => 'Int', is => 'ro', required => 1);
has 'translation' => (isa => 'Str', is => 'ro', required => 1);
has 'exon' => (isa => 'Str', is => 'ro', required => 1);
has 'rank' => (isa => 'Int', is => 'ro', required => 1);

=head2 get_by_Translation

  Args [1]    : Bio::EnsEMBL::Translation Translation to calculate exon locations for
  Example     : my $splice_sites = EnsEMBL::REST::EnsemblModel::TranslationExon->get_by_Translation($c, 'human');
  Description : Loops through all translatable exons linked to the given translation
                and converts them into protein coordinates
  Returntype  : ArrayRef of TranslationExon objects

=cut

sub get_by_Translation {
  my ($class, $translation) = @_;
  my $id = $translation->stable_id();
  my $transcript = $translation->transcript();
  my $translatable_exons = $transcript->get_all_translateable_Exons();
  my @objs;
  my $rank = 1;
  foreach my $e (@{$translatable_exons}) {
    my ($coord) = $translation->transcript->genomic2pep($e->start(), $e->end(), $e->strand());
    push(@objs, $class->new(start => $coord->start, end => $coord->end, translation => $id, exon => $e->stable_id(), rank => $rank));
    $rank++;
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
    end => $self->end(),
    id => $self->exon(),
    seq_region_name => $self->translation(),
    rank => $self->rank(),
  };
  return $summary;
}

=head2 SO_term

  Description : Returns the SO term coding_exon
  Returntype  : String the SO term coding_exon

=cut

sub SO_term {
  my ($self) = @_;
  return 'SO:0000195'; #coding_exon
}

1;
