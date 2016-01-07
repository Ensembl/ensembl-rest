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

use feature qw(say);
extends 'Catalyst::Model';

with 'Catalyst::Component::InstancePerContext';
#with 'CatalystX::LeakChecker';

# set to read only at initiaion time
has 'context' => (is => 'ro');


# Overwrite potentially, check Catalyst doc
# Assign all these to $self->context
sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  return $self->new({ context => $c, %$self, @args });
}

# Field / Member of the class (Getter/Setter), shortcut to add something new to the class
# It is statefull, retains states between calls
# Is run the first time it is accessed
#has 'eqtl_adaptor' => (
#    is      => 'ro',
#    isa     => 'Bio::EnsEMBL::HDF5::EQTLAdaptor',
#    builder => '_get_eqtl_adaptor',
#    lazy    => 1
#    );

sub fetch_eqtl {
  my ($self) = @_;

  my $c            = $self->context;
  my $tissue       = $c->stash->{tissue};
  my $stable_id    = $c->stash->{stable_id};
  my $variant_name = $c->stash->{variant_name};
  my $stat         = $c->stash->{statistic};
  my $species      = $c->stash->{species};

  my $eqtl_a = $c->model('Registry')->get_eqtl_adaptor($species);

  my $results = $eqtl_a->fetch( {
        gene          => $stable_id,
        tissue        => $tissue,
        snp           => $variant_name,
        statistic     => $stat,
      });

  return $results;
}

# replace with grep
sub validate_species {
  my ($self, $species) = @_;

  my $found = 0;
  my $tmp_species = $self->context->model('Registry')->eqtl_species();
  my $eqtl_species = {map { $_ => 1 } @{$tmp_species}};

  if(exists $eqtl_species->{$species}){
    $found = 1;
  }

  return $found;
}

1;
