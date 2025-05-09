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

package EnsEMBL::REST::EnsemblModel::Biotype;

=pod

=head1 NAME

EnsEMBL::REST::EnsemblModel::Biotype
 
=head1 DESCRIPTION

Provides access to all biotypes in a given species for both genes and
transcripts. The code will loop through all available GeneAdaptor instances
in the registry as a guide to applicable DBs. Please use the
C<EnsEMBL::REST::EnsemblModel::Biotype::get_Biotypes()> method
to populate the object.

=cut

use Moose;
use Bio::EnsEMBL::Utils::Scalar qw/assert_ref/;

=head2 ATTRIBUTES

=over 8

=item biotype - String name of the biotype

=item groups - ArrayRef[String] Groups this biotype is found in

=item objects - ArrayRef[String] The object type this biotype was found in

=back

=cut

has 'biotype' => ( isa => 'Str', is => 'ro', required => 1);
has 'groups'  => ( isa => 'HashRef[Str]', is => 'ro', required => 0, default => sub {{}});
has 'objects' => ( isa => 'HashRef[Str]', is => 'ro', required => 0, default => sub {{}});

=head2 get_Biotypes

  Args [1]    : Catalyst Catalyst context instance to use for lookup
  Args [2]    : String Species name to lookup
  Example     : my $biotypes = EnsEMBL::REST::EnsemblModel::Biotype->get_Biotypes($c, 'human');
  Description : Loops through all available GeneAdaptor instances for the given species and
                queries for distinct biotypes in the gene and transcript table.
  Returntype  : ArrayRef of Biotype objects
  Exceptions  : SQL based exceptions

=cut

sub get_Biotypes {
  my ($class, $c, $species) = @_;
  assert_ref($c, 'Catalyst', 'Catalyst Context');
  my %biotypes;
  my $adaptors = $c->model('Registry')->get_all_adaptors_by_type($species, 'gene');
  foreach my $adaptor (@{$adaptors}) {
    my $dba = $adaptor->db();
    my $species_id = $dba->species_id();
    my $dbc = $dba->dbc();
    foreach my $object (qw/gene transcript/) {
      my $sql = "select distinct biotype from $object o, seq_region s, coord_system cs where s.seq_region_id = o.seq_region_id and s.coord_system_id = cs.coord_system_id and species_id = $species_id";
      $dbc->sql_helper->execute_no_return(-SQL => $sql, -CALLBACK => sub {
        my ($row) = @_;
        my ($biotype) = @{$row};
        my $biotype_obj = $biotypes{$biotype};
        if(! $biotype_obj) {
          $biotype_obj = $class->new(biotype => $biotype);
          $biotypes{$biotype} = $biotype_obj;
        }
        $biotype_obj->groups()->{$dba->group} = 1;
        $biotype_obj->objects()->{$object} = 1;
      });  
    }
  }
  return [values %biotypes];
}

=head2 summary_as_hash

  Example     : my $hash = $obj->summary_as_hash();
  Description : Converts the current object into an unblessed hash fit for
                serialisation purposes
  Returntype  : HashRef Basic representation of the current object

=cut

sub summary_as_hash {
  my ($self) = @_;
  return { 
    biotype => $self->biotype(), 
    groups  => [ sort keys %{$self->groups()}],
    objects => [ sort keys %{$self->objects()}],
  };
}

1;
