=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::REST::Model::Variation;

use Moose;
extends 'Catalyst::Model';

with 'Catalyst::Component::InstancePerContext';

has 'context' => (is => 'ro');

sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  return $self->new({ context => $c, %$self, @args });
}

sub fetch_variation {
  my ($self, $variation_id) = @_;

  my $c = $self->context();
  my $species = $c->stash->{species};

  $c->go('ReturnError', 'custom', ["No variation given. Please specify a variation to retrieve from this service"]) if ! $variation_id;

  my $vfa = $c->model('Registry')->get_adaptor($species, 'Variation', 'Variation');
  my $variation = $vfa->fetch_by_name($variation_id);
  if (!$variation) {
    $c->go('ReturnError', 'custom', ["$variation_id not found for $species"]);
  }
  return $self->to_hash($variation);
}


sub to_hash {
  my ($self, $variation) = @_;
  my $hashed;

  $hashed->{name} = $variation->name,
  $hashed->{source} = $variation->source,
  $hashed->{ambiguity} = $variation->ambig_code,
  $hashed->{synonyms} = $variation->get_all_synonyms,
  $hashed->{ancestral_allele} = $variation->ancestral_allele,
  $hashed->{var_class} = $variation->var_class,
  $hashed->{most_severe_consequence} = $variation->display_consequence,
  $hashed->{MAF} = $variation->minor_allele_frequency,
  $hashed->{ambiguity_code} = $variation->ambig_code,
  return $hashed;  
}



with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;
