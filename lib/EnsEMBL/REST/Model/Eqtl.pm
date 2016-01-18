=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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
use Bio::EnsEMBL::HDF5::EQTLAdaptor;
use Bio::EnsEMBL::DBSQL::DBAdaptor;

#use feature qw(say);
#use Data::Dumper;

extends 'Catalyst::Model';
with 'Catalyst::Component::InstancePerContext';

# Overwrite potentially, check Catalyst doc
# Assign all these to $self->context
sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  return $self->new({ registry => $c->model('Registry'), %$self, @args });

}

=head2 fetch_qetl

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
  my $eqtl_a = $self->{'registry'}->get_eqtl_adaptor($constraints->{species});

  $self->_validate_tissue($eqtl_a, $constraints->{tissue});

  my $results = $eqtl_a->fetch( {
        gene          => $constraints->{stable_id},
        tissue        => $constraints->{tissue},
        snp           => $constraints->{variant_name},
        statistic     => $constraints->{statistic},
      });

  return $results;
}

=head2 _validate_tissue

  Arg [1]    : Bio::EnsEMBL::HDF5::EQTLAdaptor
  Arg [2]    : $tissue name
  Example    : $self->_validate_tissue($eqtl_a, $constraints->{tissue});
  Description: Validates if tissue exists in Database.
  Returntype : None
  Exceptions : Throws if tissue is not present in Database
  Caller     : general
  Status     : Stable

=cut

sub _validate_tissue {
  my ($self, $eqtl_a, $tissue) = @_;

  if(! exists $eqtl_a->{tissues}->{$tissue}) {
    my $tissues = join(", ", map { $_ } sort keys %{$eqtl_a->{tissues}});
    Catalyst::Exception->throw("Tissue '$tissue' not recognised. Available tissues: $tissues ");
  }
}


1;
