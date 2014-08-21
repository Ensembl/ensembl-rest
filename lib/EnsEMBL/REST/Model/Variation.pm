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
  my $c = $self->context();
  my $variation_hash;

  $variation_hash->{name} = $variation->name,
  $variation_hash->{source} = $variation->source_description,
  $variation_hash->{ambiguity} = $variation->ambig_code,
  $variation_hash->{synonyms} = $variation->get_all_synonyms,
  $variation_hash->{ancestral_allele} = $variation->ancestral_allele,
  $variation_hash->{var_class} = $variation->var_class,
  $variation_hash->{most_severe_consequence} = $variation->display_consequence,
  $variation_hash->{MAF} = $variation->minor_allele_frequency,
  $variation_hash->{evidence} = $variation->get_all_evidence_values();
  $variation_hash->{clinical_significance} = $variation->get_all_clinical_significance_states() if @{$variation->get_all_clinical_significance_states()};
  $variation_hash->{mappings} = $self->VariationFeature($variation);
  $variation_hash->{populations} = $self->Alleles($variation) if $c->request->param('pops');
  $variation_hash->{genotypes} = $self->Genotypes($variation) if $c->request->param('genotypes');
  $variation_hash->{phenotypes} = $self->Phenotypes($variation) if $c->request->param('phenotypes');

  return $variation_hash;
}

sub VariationFeature {
  my ($self, $variation) = @_;

  my @mappings;
  my $vfs = $variation->get_all_VariationFeatures();
  foreach my $vf (@$vfs) {
    push (@mappings, $self->vf_as_hash($vf));
  }
  return \@mappings;
}

sub vf_as_hash {
  my ($self, $vf) = @_;

  my $variation_feature;
  $variation_feature->{location} = $vf->seq_region_name . ":" . $vf->seq_region_start . "-" . $vf->seq_region_end;
  $variation_feature->{strand} = $vf->seq_region_strand;
  $variation_feature->{start} = $vf->seq_region_start;
  $variation_feature->{end} = $vf->seq_region_end;
  $variation_feature->{seq_region_name} = $vf->seq_region_name;
  $variation_feature->{coord_system} = $vf->coord_system_name;
  $variation_feature->{assembly_name} = $vf->slice->coord_system->version;
  $variation_feature->{allele_string} = $vf->allele_string;

  return $variation_feature;
}

sub Genotypes {
  my ($self, $variation) = @_;

  my @genotypes;
  my $genotypes = $variation->get_all_IndividualGenotypes;
  foreach my $gen (@$genotypes) {
    push (@genotypes, $self->gen_as_hash($gen));
  }
  return \@genotypes;
}

sub gen_as_hash {
  my ($self, $gen) = @_;

  my $gen_hash;
  $gen_hash->{genotype} = $gen->genotype_string();
  $gen_hash->{individual} = $gen->individual->name();
  $gen_hash->{gender} = $gen->individual->gender();
  $gen_hash->{submission_id} = $gen->subsnp() if $gen->subsnp;

  return $gen_hash;
}

sub Phenotypes {
  my ($self, $variation) = @_;

  my @phenotypes;
  my $phenotypes = $variation->get_all_PhenotypeFeatures;
  foreach my $phen (@$phenotypes) {
    push (@phenotypes, $self->phen_as_hash($phen));
  }
  return \@phenotypes;
}

sub phen_as_hash {
  my ($self, $phen) = @_;

  my $phen_hash;
  $phen_hash->{trait} = $phen->phenotype->description;
  $phen_hash->{source} = $phen->source;
  $phen_hash->{study} = $phen->study->external_reference if $phen->study;
  $phen_hash->{genes} = $phen->associated_gene;
  $phen_hash->{variants} = $phen->variation_names;
  $phen_hash->{risk_allele} = $phen->risk_allele if $phen->risk_allele;
  $phen_hash->{pvalue} = $phen->p_value if $phen->p_value;
  $phen_hash->{beta_coefficient} = $phen->beta_coefficient if $phen->beta_coefficient;

  my $associated_studies = $phen->associated_studies;
  foreach my $study (@$associated_studies) {
    push (@{$phen_hash->{evidence}}, $study->name);
  }

  return $phen_hash;
}

sub Alleles {
  my ($self, $variation) = @_;

  my @populations;
  my $alleles = $variation->get_all_Alleles();
  foreach my $allele (@$alleles) {
    if ($allele->frequency) {
      push (@populations, $self->pops_as_hash($allele));
    }
  }

  return \@populations;
}

sub pops_as_hash {
  my ($self, $allele) = @_;

  my $population;
  $population->{frequency} = $allele->frequency();
  $population->{population} = $allele->population->name();
  $population->{allele_count} = $allele->count();
  $population->{allele} = $allele->allele();
  $population->{submission_id} = $allele->subsnp() if $allele->subsnp();

  return $population;
}


with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;
