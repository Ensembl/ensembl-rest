package EnsEMBL::REST::EnsemblModel::TranslationProteinFeature;

=pod

=head1 NAME

EnsEMBL::REST::EnsemblModel::TranslationProteinFeature
 
=head1 DESCRIPTION

Provides a wrapper for ProteinFeature objects so we can add to the
summary hash and control the addition of seq_region_name since
these objects lack a slice (and GFFSerialiser hates that).

=cut

use Moose;

=head2 ATTRIBUTES

=over 8

=item translation - Translation this ProteinFeature is linked to

=item protein_feature - The protein feature in question

=back

=cut

has 'translation' => (isa => 'Bio::EnsEMBL::Translation', is => 'ro', required => 1);
has 'protein_feature' => (isa => 'Bio::EnsEMBL::ProteinFeature', is => 'ro', required => 1);

=head2 get_from_ProteinFeatures

	Args [1]		:	ArrayRef[Bio::EnsEMBL::ProteinFeature] Array of protein features to link to a Translation
  Args [2]    : Bio::EnsEMBL::Translation Translation to link a ProteinFeature to
  Description : Loops through all available ProteinFeature objects creating an instance of this 
  							class for each one
  Returntype  : ArrayRef of TranslationProteinFeature objects

=cut

sub get_from_ProteinFeatures {
	my ($class, $protein_features, $translation) = @_;
	my @features;
	foreach my $pf (@{$protein_features}) {
		push(@features, $class->new(translation => $translation, protein_feature => $pf));
	}
	return \@features;
}

=head2 summary_as_hash

  Description : Calls the summary_as_hash for ProteinFeature and adds
  							the current linked Translation's stable id as a
  							seq_region_name attribute
  Returntype  : HashRef Summary of this object as a hash

=cut

sub summary_as_hash {
	my ($self) = @_;
	my $summary = $self->protein_feature->summary_as_hash();
	$summary->{seq_region_name} = $self->translation()->stable_id();
	return $summary;
}

=head2 SO_term

  Description : Returns the SO term polypeptide_region
  Returntype  : String the SO term polypeptide_region

=cut

sub SO_term {
  my ($self) = @_;
  return 'SO:0000839'; #polypeptide_region
}

1;