=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::REST::Model::Eqtl;

use Moose;
use Catalyst::Exception qw(throw);
use Bio::EnsEMBL::Utils::Scalar qw/wrap_array/;
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
eval { require Bio::EnsEMBL::HDF5::EQTLAdaptor };

use feature qw(say);
use Data::Dumper;

extends 'Catalyst::Model';
with 'Catalyst::Component::InstancePerContext';

# Overwrite potentially, check Catalyst doc
# Assign all these to $self->context
sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  return $self->new({ registry => $c->model('Registry'), %$self, @args });

}

=head2 fetch_eqtl

  Arg [1]    : HASHREF $constraints
  Example    : $eqtls = $eqtl_adaptor->fetch_eqtl($constraints);
  Description: Validates tissue constraint.
               Fetches all statistics for from the DB using the constraints supplied.
  Returntype : HASHREF
  Exceptions : Throws if constraint is not present in Database
  Caller     : general
  Status     : Stable

=cut

sub fetch_eqtl {
  my ($self, $constraints ) = @_;

  # fails in registry if species is wrong/not available in Ensembl
  my $user_species    = $constraints->{species};
  my $ensembl_species = $self->{'registry'}->get_alias($user_species);

  if(! $ensembl_species) {
    Catalyst::Exception->throw("Species '$user_species' not recognised. Check your URL");
  }

  my $eqtl_a = $self->{'registry'}->get_eqtl_adaptor($ensembl_species);

  if (!defined $eqtl_a) {
    Catalyst::Exception->throw("No EQTL adaptor available");
  }

  $self->_validate_stable_id ($eqtl_a, $constraints->{stable_id});
  $self->_validate_tissue    ($eqtl_a, $constraints->{tissue});
  $self->_validate_statistic ($eqtl_a, $constraints->{statistic});

  my $results = $eqtl_a->fetch( {
        gene          => $constraints->{stable_id},
        tissue        => $constraints->{tissue},
        snp           => $constraints->{variant_name},
        statistic     => $constraints->{statistic},
      });

  return $results;
}

=head2 fetch_eqtl

  Arg [1]    : HASHREF $constraints
  Example    : $eqtls = $eqtl_adaptor->fetch_eqtl($constraints);
  Description: Fetches all tissues currently available in the DB
  Returntype : HASHREF
  Exceptions : Throws if species is not available in Ensembl
  Caller     : general
  Status     : Stable

=cut

sub fetch_all_tissues {
  my ($self, $constraints) = @_;

  my $user_species    = $constraints->{species};
  my $ensembl_species = $self->{'registry'}->get_alias($user_species);
  if(! $ensembl_species) {
    Catalyst::Exception->throw("Species '$user_species' not recognised. Check your URL");
  }

  my $eqtl_a = $self->{'registry'}->get_eqtl_adaptor($ensembl_species);
  if (defined $eqtl_a) {
    my $result = $eqtl_a->fetch_all_tissues();
    return ($result);
  } else {
    Catalyst::Exception->throw("No EQTL adaptor available");
  }

}

=head2 _validate_stable_id

  Arg [1]    : Bio::EnsEMBL::HDF5::EQTLAdaptor
  Arg [2]    : $stable_id
  Example    : $self->_validate_stable_id($eqtl_a, $constraints->{stable_id});
  Description: Validates if stable_id exists in Database.
  Returntype : None
  Exceptions : Throws if stable_id is not present in Database
  Caller     : general
  Status     : Stable

=cut

sub _validate_stable_id {
  my ($self, $eqtl_a, $stable_id) = @_;
  # Check for EnsemblIDs with more/less than 11 digits
  if (defined $stable_id){
    if( ($stable_id =~ /ENS[A-Z]+[0-9]{11}/)  and (! exists $eqtl_a->{gene_ids}->{$stable_id}) ) {
      Catalyst::Exception->throw("Stable ID '$stable_id' not present in EQTL database.");
    }
  }
}

=head2 _validate_tissue

  Arg [1]    : Bio::EnsEMBL::HDF5::EQTLAdaptor
  Arg [2]    : $tissue
  Example    : $self->_validate_tissue($eqtl_a, $constraints->{tissue});
  Description: Validates if tissue exists in Database.
  Returntype : None
  Exceptions : Throws if tissue is not present in Database
  Caller     : general
  Status     : Stable

=cut

sub _validate_tissue {
  my ($self, $eqtl_a, $tissue) = @_;
  if (defined $tissue){
    if(! exists $eqtl_a->{tissue_ids}->{$tissue}) {
      my $tissues = join(", ", map { $_ } sort keys %{$eqtl_a->{tissue_ids}});
      Catalyst::Exception->throw("Tissue '$tissue' not recognised. Available tissues: $tissues");
    }
  }
}

=head2 _validate_statistic

  Arg [1]    : Bio::EnsEMBL::HDF5::EQTLAdaptor
  Arg [2]    : $statistic name
  Example    : $self->_validate_statistic($eqtl_a, $constraints->{statistic});
  Description: Validates if statistic exists in Database.
  Returntype : None
  Exceptions : Throws if statistic is not present in Database
  Caller     : general
  Status     : Stable

=cut

sub _validate_statistic {
  my ($self, $eqtl_a, $statistic) = @_;

  if (defined $statistic){
    if(! exists $eqtl_a->{statistic_ids}->{$statistic}) {
      my $statistics = join(", ", map { $_ } sort keys %{$eqtl_a->{statistic_ids}});
      Catalyst::Exception->throw("Statistic '$statistic' not recognised. Available statistics: $statistics");
    }
  }
}

1;
