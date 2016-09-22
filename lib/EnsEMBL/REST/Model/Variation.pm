=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
Copyright [2016] EMBL-European Bioinformatics Institute

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
use Catalyst::Exception qw(throw);
use Scalar::Util qw/weaken/;
extends 'Catalyst::Model';

with 'Catalyst::Component::InstancePerContext';

has 'context' => (is => 'ro', weak_ref => 1);

sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  weaken($c);
  return $self->new({ context => $c, %$self, @args });
}

sub fetch_variation {
  my ($self, $variation_id) = @_;

  my $c = $self->context();
  my $species = $c->stash->{species};

  Catalyst::Exception->throw("No variation given. Please specify a variation to retrieve from this service") if ! $variation_id;

  my $vfa = $c->model('Registry')->get_adaptor($species, 'Variation', 'Variation');
  $vfa->db->include_failed_variations(1);
  
  # use VCF if requested in config
  my $var_params = $c->config->{'Model::Variation'};
  if($var_params && $var_params->{use_vcf}) {
    $vfa->db->use_vcf($var_params->{use_vcf});
    $Bio::EnsEMBL::Variation::DBSQL::VCFCollectionAdaptor::CONFIG_FILE = $var_params->{vcf_config};
  }
  
  my $variation = $vfa->fetch_by_name($variation_id);
  if (!$variation) {
    Catalyst::Exception->throw("$variation_id not found for $species");
  }
  return $self->to_hash($variation);
}

sub fetch_variation_multiple {
  my ($self, $variation_ids) = @_;

  my $c = $self->context();
  my $species = $c->stash->{species};

  my $va = $c->model('Registry')->get_adaptor($species, 'Variation', 'Variation');
  $va->db->include_failed_variations(1);
  
  # use VCF if requested in config
  my $var_params = $c->config->{'Model::Variation'};
  if($var_params && $var_params->{use_vcf}) {
    $va->db->use_vcf($var_params->{use_vcf});
    $Bio::EnsEMBL::Variation::DBSQL::VCFCollectionAdaptor::CONFIG_FILE = $var_params->{vcf_config};
  }

  my %return = map {$_->name => $self->to_hash($_)} @{$va->fetch_all_by_name_list($variation_ids || [])};

  return \%return;  
}


sub to_hash {
  my ($self, $variation) = @_;
  my $c = $self->context();
  my $variation_hash;

  $variation_hash->{name} = $variation->name;
  $variation_hash->{source} = $variation->source_description;
  $variation_hash->{ambiguity} = $variation->ambig_code;
  $variation_hash->{synonyms} = $variation->get_all_synonyms;
  $variation_hash->{failed} = $variation->failed_description if $variation->is_failed;
  $variation_hash->{ancestral_allele} = $variation->ancestral_allele;
  $variation_hash->{var_class} = $variation->var_class;
  $variation_hash->{most_severe_consequence} = $variation->display_consequence;
  $variation_hash->{MAF} = $variation->minor_allele_frequency;
  $variation_hash->{minor_allele} = $variation->minor_allele;
  $variation_hash->{evidence} = $variation->get_all_evidence_values;
  $variation_hash->{clinical_significance} = $variation->get_all_clinical_significance_states() if @{$variation->get_all_clinical_significance_states()};
  $variation_hash->{mappings} = $self->get_variationFeature_info($variation);
  $variation_hash->{populations} = $self->get_allele_info($variation) if $c->request->param('pops');
  $variation_hash->{genotypes} = $self->get_sampleGenotype_info($variation) if $c->request->param('genotypes');
  $variation_hash->{phenotypes} = $self->get_phenotype_info($variation) if $c->request->param('phenotypes');
  $variation_hash->{population_genotypes} = $self->get_populationGenotype_info($variation) if $c->request->param('population_genotypes');

  return $variation_hash;
}

sub get_variationFeature_info {
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

sub get_sampleGenotype_info {
  my ($self, $variation) = @_;

  my @genotypes;
  my $genotypes = $variation->get_all_SampleGenotypes;
  foreach my $gen (@$genotypes) {
    push (@genotypes, $self->gen_as_hash($gen));
  }
  return \@genotypes;
}

sub gen_as_hash {
  my ($self, $gen) = @_;

  my $gen_hash;
  $gen_hash->{genotype} = $gen->genotype_string();
  $gen_hash->{sample} = $gen->sample->name();
  $gen_hash->{gender} = $gen->sample->individual->gender();
  $gen_hash->{submission_id} = $gen->subsnp() if $gen->subsnp;

  return $gen_hash;
}

sub get_phenotype_info {
  my ($self, $variation) = @_;

  my @phenotypes;
  my $phenotypes = $variation->get_all_PhenotypeFeatures;

  my %seen = ();

  foreach my $phen (@$phenotypes) {
    my $hash = $self->phen_as_hash($phen);
    
    # generate a key from the values to uniquify
    my $key = join("", sort values %$hash);

    push (@phenotypes, $hash) unless $seen{$key};
    $seen{$key} = 1;
  }

  return \@phenotypes;
}

sub get_gene_phenotype_info {
  my ($self, $id) = @_;
  
  my $c = $self->context();
  my $species = $c->stash->{species};

  my @phenotypes;  
  my $pfa = $c->model('Registry')->get_adaptor($species, 'variation', 'phenotypefeature');
  my @pfs = @{$pfa->fetch_all_by_object_id($id, 'Gene')};

  my %seen = ();

  foreach my $phen (@pfs) {
    my $hash = $self->phen_as_hash($phen);
    my $key = join("", sort values %$hash);
    push (@phenotypes, $hash) unless $seen{$key};
    $seen{$key} = 1;
  }

  return \@phenotypes;
}

sub phen_as_hash {
  my ($self, $phen) = @_;

  my $phen_hash;
  $phen_hash->{trait} = $phen->phenotype->description;
  $phen_hash->{source} = $phen->source->name;
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

sub get_allele_info {
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

## Genotype frequencies in available populations
sub get_populationGenotype_info {
  my ($self, $variation) = @_;

  my @formatted_pop_gen;
  my $pop_gen = $variation->get_all_PopulationGenotypes();
  foreach my $pg (@$pop_gen) {
    push (@formatted_pop_gen, $self->popgen_as_hash($pg));
  }

  return \@formatted_pop_gen;
}
 
sub popgen_as_hash {
  my ($self, $pg) = @_;
 
  my $pop_gen;

  $pop_gen->{population} = $pg->population()->name() ;
  $pop_gen->{genotype}   = $pg->genotype_string() ;
  $pop_gen->{frequency}  = $pg->frequency() ;
  $pop_gen->{count}      = $pg->count();
  $pop_gen->{subsnp_id}  = $pg->subsnp() if defined $pg->subsnp();

  return $pop_gen;
}

sub fetch_variation_source_infos {
  my ($self,$src_filter) = @_;

  my $c = $self->context();
  my $species = $c->stash->{species};

  my $srca = $c->model('Registry')->get_adaptor($species, 'Variation', 'Source');

  my $sources;  
  if (defined $src_filter) {
    my $src = $srca->fetch_by_name($src_filter);
    if (!$src) {
      Catalyst::Exception->throw("Variation source '$src_filter' not found for $species");
    }
    else {
      $sources = [$src];
    }
  }
  else {
    $sources = $srca->fetch_all();
    if (!$sources) {
      Catalyst::Exception->throw("Variation sources not found for $species");
    }
  }

  my @sources_list;
  foreach my $source (@{$sources}) {
    push @sources_list, $self->source_as_hash($source); 
  }
  return \@sources_list;
}

sub source_as_hash {
  my ($self, $src) = @_;

  my $source;

  $source->{name}           = $src->name() ;
  $source->{version}        = $src->formatted_version() if defined $src->version;
  $source->{description}    = $src->description() ;
  $source->{url}            = $src->url();
  $source->{type}           = $src->type() if defined $src->type();
  $source->{somatic_status} = $src->somatic_status() if defined $src->somatic_status;
  $source->{data_types}     = $src->get_all_data_types() if @{$src->get_all_data_types()};

  return $source;
}

sub fetch_population_infos {
  my ($self, $filter) = @_;

  my $c = $self->context();
  my $species = $c->stash->{species};

  my $pa = $c->model('Registry')->get_adaptor($species, 'Variation', 'Population');
  
  my $populations;
  if (defined $filter) {
    if ($filter eq 'LD') {
      $populations = $pa->fetch_all_LD_Populations(); 
    } else {
      Catalyst::Exception->throw("Unknown filter option '$filter'");
    }
  } else {
    $populations = $pa->fetch_all();
  }
  if (!$populations) {
    Catalyst::Exception->throw("Couldn't fetch populations.");
  } 

  my @populations_list = ();
  foreach my $population (@$populations) {
    push @populations_list, {name => $population->name, description => $population->description, size => $population->size};
  }

  return \@populations_list;
}

with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;
