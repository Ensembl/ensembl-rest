=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
Copyright [2016-2019] EMBL-European Bioinformatics Institute

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

package EnsEMBL::REST::Model::Phenotype;

use Moose;
use Try::Tiny;
use Catalyst::Exception qw(throw);
use Scalar::Util qw/weaken/;
use List::MoreUtils qw(uniq);
extends 'Catalyst::Model';

with 'Catalyst::Component::InstancePerContext';

has 'context' => (is => 'ro', weak_ref => 1);

sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  weaken($c);
  return $self->new({ context => $c, %$self, @args });
}

=head fetch_by_accession

fetch phenotype features by phenotype ontology accession
=cut
sub fetch_by_accession  {
  my ($self, $species, $accession) = @_;

  my $ont_ad   = $self->context->model('Registry')->get_adaptor( 'Multi', 'Ontology', 'OntologyTerm'); 
  my @phenotype_features = @{$self->fetch_features($species, $accession)};


  if( $self->context->request->param('include_children') ){

    my $parentterm = $ont_ad->fetch_by_accession($accession );
    my $childterms = $ont_ad->fetch_all_by_parent_term($parentterm);
    foreach my $childterm (@{$childterms}){
      @phenotype_features = (@phenotype_features, @{$self->fetch_features($species, $childterm->accession)}  );
    }
  }

  return \@phenotype_features;
}
=cut


=head fetch_by_term

extract phenotypes accessions by ontology term

=cut

sub fetch_by_term {

  my ($self, $species, $name) = @_;

  my @phenotype_features;

  my $ont_ad  = $self->context->model('Registry')->get_adaptor( 'Multi', 'Ontology', 'OntologyTerm');

  my $terms   = $ont_ad->fetch_all_by_name( $name );

  foreach my $term (@{$terms}){
    @phenotype_features = (@phenotype_features, @{$self->fetch_by_accession($species, $term->accession())} );
  }

  return \@phenotype_features;
}





=head fetch_features

extract phenotype features by phenotype accession
=cut

sub fetch_features{

  my $self      = shift;
  my $species   = shift;
  my $accession = shift;

  my $c = $self->context();

  my $phenfeat_ad = $c->model('Registry')->get_adaptor($species,'variation', 'phenotypefeature');

  my $include_pubmedid = $c->request->parameters->{include_pubmed_id};
  my $include_reviewstatus = $c->request->parameters->{include_review_status};

  my $pfs = $phenfeat_ad->fetch_all_by_phenotype_accession_type_source($accession, 'is', $self->context->request->param('source'));

  my @phenotype_features;
  foreach my $pf(@{$pfs}){
    my $feature_summary = $pf->summary_as_hash();

    my %summary_new = map { $_ => $feature_summary->{$_} } qw/description source location /;
    $summary_new{$pf->type} = $feature_summary->{$pf->type};
    $summary_new{mapped_to_accession} = $accession;

    my %attributes;
    $attributes{risk_allele} = $feature_summary->{attributes}{risk_allele}                if exists $feature_summary->{attributes}{risk_allele};
    $attributes{clinical_significance} = $feature_summary->{attributes}{clinvar_clin_sig} if exists $feature_summary->{attributes}{clinvar_clin_sig};
    $attributes{external_reference} = $feature_summary->{external_reference}              if exists $feature_summary->{external_reference};
    $attributes{external_id} = $feature_summary->{attributes}{external_id}                if exists $feature_summary->{attributes}{external_id};
    $attributes{p_value} = $feature_summary->{attributes}{p_value}                        if exists $feature_summary->{attributes}{p_value};
    $attributes{odds_ratio} = $feature_summary->{attributes}{odds_ratio}                  if exists $feature_summary->{attributes}{odds_ratio};
    $attributes{beta_coefficient} = $feature_summary->{attributes}{beta_coef}             if exists $feature_summary->{attributes}{beta_coef};
    $attributes{associated_gene} = $feature_summary->{attributes}{associated_gene}        if exists $feature_summary->{attributes}{associated_gene};
    $attributes{MIM} = $feature_summary->{attributes}{MIM}                                if exists $feature_summary->{attributes}{MIM};

    if ($include_pubmedid && exists $feature_summary->{attributes}{pubmed_id}) {
      my $pmids = $feature_summary->{attributes}{pubmed_id};
      $pmids =~ s/,/,PMID:/g;
      $pmids = "PMID:".$pmids;
      my @pubmed_ids = split(',',$pmids);
      $attributes{pubmed_ids} = \@pubmed_ids;
    }
    $attributes{review_status} = $feature_summary->{attributes}{review_status}       if $include_reviewstatus && exists $feature_summary->{attributes}{review_status};

    $summary_new{attributes} = \%attributes                                          if scalar keys %attributes;
    push @phenotype_features, \%summary_new;
  }

  return \@phenotype_features;
}

=head fetch_features_by_region

extract phenotype features by region
=cut

sub fetch_features_by_region {

  my $self      = shift;
  my $species   = shift;
  my $slice     = shift;

  my $c = $self->context();

  my $phenfeat_ad = $c->model('Registry')->get_adaptor($species,'variation', 'phenotypefeature');

  my $pf_type = $c->request->parameters->{feature_type};
  my $only_phenotypes = $c->request->parameters->{only_phenotypes};
  my $include_submitter = $c->request->parameters->{include_submitter};
  my $include_pubmedid = $c->request->parameters->{include_pubmed_id};
  my $include_reviewstatus = $c->request->parameters->{include_review_status};

  my $pfs = $phenfeat_ad->fetch_all_by_Slice_with_ontology_accession($slice, $pf_type);

  my %record_data;
  my %phenotype_data;
  foreach my $pf(sort{ lc($a->phenotype_description()) cmp lc($b->phenotype_description()) } @{$pfs}){
    my $feature_summary = $pf->summary_as_hash();

    my $phe_id = $pf->phenotype_id;
    my %summary_new;
    if ($only_phenotypes){
      if (!$phenotype_data{$feature_summary->{id} }{$phe_id}) {
        $summary_new{description} = $feature_summary->{description};
        $phenotype_data{$feature_summary->{id} }{$phe_id} = 1;
      }
    } else{
      %summary_new = map { $_ => $feature_summary->{$_} } qw/description source location /;

      my %attributes;
      $attributes{risk_allele} = $feature_summary->{attributes}{risk_allele}                if exists $feature_summary->{attributes}{risk_allele};
      $attributes{clinical_significance} = $feature_summary->{attributes}{clinvar_clin_sig} if exists $feature_summary->{attributes}{clinvar_clin_sig};
      $attributes{external_reference} = $feature_summary->{external_reference}              if exists $feature_summary->{external_reference};
      $attributes{external_id} = $feature_summary->{attributes}{external_id}                if exists $feature_summary->{attributes}{external_id};
      $attributes{p_value} = $feature_summary->{attributes}{p_value}                        if exists $feature_summary->{attributes}{p_value};
      $attributes{odds_ratio} = $feature_summary->{attributes}{odds_ratio}                  if exists $feature_summary->{attributes}{odds_ratio};
      $attributes{beta_coefficient} = $feature_summary->{attributes}{beta_coef}             if exists $feature_summary->{attributes}{beta_coef};
      $attributes{associated_gene} = $feature_summary->{associated_gene}                    if exists $feature_summary->{associated_gene};
      $attributes{MIM} = $feature_summary->{attributes}{MIM}                                if exists $feature_summary->{attributes}{MIM};
      $attributes{submitter_names} = $feature_summary->{attributes}{submitter_names}        if $include_submitter && exists $feature_summary->{attributes}{submitter_names};
      $attributes{review_status} = $feature_summary->{attributes}{review_status}            if $include_reviewstatus && exists $feature_summary->{attributes}{review_status};

      if ($include_pubmedid && exists $feature_summary->{attributes}{pubmed_id}) {
        my $pmids = $feature_summary->{attributes}{pubmed_id};
        $pmids =~ s/,/,PMID:/g;
        $pmids = "PMID:".$pmids;
        my @pubmed_ids = split(',',$pmids);
        $attributes{pubmed_ids} = \@pubmed_ids;
      }
      $summary_new{attributes} = \%attributes                                          if scalar keys %attributes;
    }
    $summary_new{ontology_accessions} = $feature_summary->{ontology_accessions}        if exists $feature_summary->{ontology_accessions};

    push @{$record_data{$feature_summary->{$pf->type}}}, \%summary_new;
  }

  my @phenotype_features;
  foreach my $id (keys(%record_data)) {
    my $entry = { 'id' => $id, 'phenotype_associations' => $record_data{$id}};
    push @phenotype_features, $entry;
  }

  return \@phenotype_features;
}


=head fetch_features_by_gene

extract phenotype features by gene identifier or gene symbol
=cut

sub fetch_features_by_gene {
  my $self      = shift;
  my $species   = shift;
  my $gene      = shift;

  my $c = $self->context();

  my $gene_ad;
  try{
    $gene_ad = $c->model('Registry')->get_adaptor($species,'core', 'gene');
  };
  unless (defined $gene_ad ) {Catalyst::Exception->throw("Species $species not found.");}

  my $phenfeat_ad = $c->model('Registry')->get_adaptor($species,'variation', 'phenotypefeature');
  my $slice_ad = $c->model('Registry')->get_adaptor($species, "core", "slice");

  my $include_assoc = $c->request->parameters->{include_associated};
  my $include_overlap = $c->request->parameters->{include_overlap};
  my $include_submitter = $c->request->parameters->{include_submitter};
  my $include_pubmedid = $c->request->parameters->{include_pubmed_id};
  my $include_reviewstatus = $c->request->parameters->{include_review_status};

  my $genes = $gene_ad->fetch_all_by_external_name($gene);

  if (scalar @{$genes} == 0){
    Catalyst::Exception->throw("Gene $gene not found.");
  }

  my @phenotype_features;
  while (my $g = shift@{$genes}){
    my @pfs = @{$phenfeat_ad->fetch_all_by_Gene($g)};
    if ($include_assoc && $g->external_name) {
      my @pfs_assoc = @{$phenfeat_ad-> fetch_all_by_associated_gene($g->external_name())};
      push @pfs, @pfs_assoc;
    }
    if ($include_overlap){
      my $gene_specific_slice = $slice_ad->fetch_by_gene_stable_id($g->stable_id());
      my @pfs_overlap = @{$phenfeat_ad->fetch_all_by_Slice($gene_specific_slice)};
      push @pfs, @pfs_overlap;
    }
    @pfs = uniq @pfs;

    while (my $pf = shift @pfs){
      my $feature_summary = $pf->summary_as_hash();

      my %summary_new = map { $_ => $feature_summary->{$_} } qw/description source location /;
      $summary_new{$pf->type} = $feature_summary->{$pf->type};

      my %attributes;
      $attributes{risk_allele} = $feature_summary->{attributes}{risk_allele}                if exists $feature_summary->{attributes}{risk_allele};
      $attributes{clinical_significance} = $feature_summary->{attributes}{clinvar_clin_sig} if exists $feature_summary->{attributes}{clinvar_clin_sig};
      $attributes{external_reference} = $feature_summary->{external_reference}              if exists $feature_summary->{external_reference};
      $attributes{external_id} = $feature_summary->{attributes}{external_id}                if exists $feature_summary->{attributes}{external_id};
      $attributes{p_value} = $feature_summary->{attributes}{p_value}                        if exists $feature_summary->{attributes}{p_value};
      $attributes{odds_ratio} = $feature_summary->{attributes}{odds_ratio}                  if exists $feature_summary->{attributes}{odds_ratio};
      $attributes{beta_coefficient} = $feature_summary->{attributes}{beta_coef}             if exists $feature_summary->{attributes}{beta_coef};
      $attributes{associated_gene} = $feature_summary->{associated_gene}                    if exists $feature_summary->{associated_gene};
      $attributes{MIM} = $feature_summary->{attributes}{MIM}                                if exists $feature_summary->{attributes}{MIM};
      $attributes{submitter_names} = $feature_summary->{attributes}{submitter_names}        if $include_submitter && exists $feature_summary->{attributes}{submitter_names};
      $attributes{review_status} = $feature_summary->{attributes}{review_status}            if $include_reviewstatus && exists $feature_summary->{attributes}{review_status};

      if ($include_pubmedid && exists $feature_summary->{attributes}{pubmed_id}) {
        my $pmids = $feature_summary->{attributes}{pubmed_id};
        $pmids =~ s/,/,PMID:/g;
        $pmids = "PMID:".$pmids;
        my @pubmed_ids = split(',',$pmids);
        $attributes{pubmed_ids} = \@pubmed_ids;
      }
      $summary_new{attributes} = \%attributes                                          if scalar keys %attributes;

      $summary_new{ontology_accessions} = $feature_summary->{ontology_accessions}      if exists $feature_summary->{ontology_accessions};

      push @phenotype_features, \%summary_new;
    }
  }
  return \@phenotype_features;
}


1;
