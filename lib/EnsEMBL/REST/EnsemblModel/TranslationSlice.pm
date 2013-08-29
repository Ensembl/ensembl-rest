package EnsEMBL::REST::EnsemblModel::TranslationSlice;

=pod

=head1 NAME

EnsEMBL::REST::EnsemblModel::TranslationSlice
 
=head1 DESCRIPTION

Fake Bio::EnsEMBL::Slice slightly compatable model object. Used
to fake GFF serialisation into using a Translation as a valid Slice
coordinate system.

=cut

use Moose;

=head2 ATTRIBUTES

=over 8

=item translation - Translation this ProteinFeature is linked to

=back

=cut

has 'translation' => (isa => 'Bio::EnsEMBL::Translation', is => 'ro', required => 1);

=head2 seq_region_name

  Description : Returns the linked translation's stable id
  Returntype  : String stable id of the linked translation

=cut

sub seq_region_name {
  my ($self) = @_;
  return $self->translation()->stable_id();
}

=head2 start

  Description : Returns the start of the slice
  Returntype  : Int hardcoded to return 1

=cut

sub start {
  my ($self) = @_;
  return 1;
}

=head2 end

  Description : Returns the end of this slice
  Returntype  : Int end of the slice which is the same as the translation length

=cut

sub end {
  my ($self) = @_;
  return $self->translation()->length();
}

1;