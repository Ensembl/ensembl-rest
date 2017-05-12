=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
Copyright [2016-2017] EMBL-European Bioinformatics Institute

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

  my $phenfeat_ad = $self->context->model('Registry')->get_adaptor($species,'variation', 'phenotypefeature');

  my $pfs = $phenfeat_ad->fetch_all_by_phenotype_accession_type_source($accession, 'is', $self->context->request->param('source'));

  my @phenotype_features;
  foreach my $pf(@{$pfs}){

    my $record =  { description         => $pf->phenotype_description(),
                    mapped_to_accession => $accession,
                    $pf->type()         => $pf->object_id,
                    location            => $pf->seq_region_name() . ":" . $pf->seq_region_start() . "-" . $pf->seq_region_end() ,
                    source              => $pf->source_name(),
                  };

    $record->{attributes}->{risk_allele}           = $pf->risk_allele()           if $pf->risk_allele(); 
    $record->{attributes}->{clinical_significance} = $pf->clinical_significance() if $pf->clinical_significance();
    $record->{attributes}->{external_reference}    = $pf->external_reference()    if $pf->external_reference(); ## from study - eg OMIM
    $record->{attributes}->{external_id}           = $pf->external_id()           if $pf->external_id();        ## from attrib eg ClinVar
    $record->{attributes}->{p_value}               = $pf->p_value()               if $pf->p_value();
    $record->{attributes}->{odds_ratio}            = $pf->odds_ratio()            if $pf->odds_ratio();
    $record->{attributes}->{beta_coefficient}      = $pf->beta_coefficient()      if $pf->beta_coefficient();
    $record->{attributes}->{associated_gene}       = $pf->associated_gene()       if $pf->associated_gene();


    push @phenotype_features, $record;                             
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

  my $pfs = $phenfeat_ad->fetch_all_by_Slice_with_ontology_accession($slice, $pf_type);

  my %record_data;
  my %phenotype_data;

  foreach my $pf(sort{ lc($a->phenotype_description()) cmp lc($b->phenotype_description()) } @{$pfs}){

    my $object_id = $pf->object_id(); 
    my $phe_id    = $pf->phenotype_id();
    my $phe_desc  = $pf->phenotype_description();
    my $ontology_accessions = $pf->get_all_ontology_accessions();

    $record_data{$object_id} = [] if (!$record_data{$object_id});
    my $pf_info;

    if ($only_phenotypes) {
      if (!$phenotype_data{$object_id}{$phe_id}) {
        $pf_info->{description} = $phe_desc;
        $phenotype_data{$object_id}{$phe_id} = 1;
      }     
    }
    else {
      $pf_info = {
                   description => $phe_desc,
                   location    => $pf->seq_region_name() . ":" . $pf->seq_region_start() . "-" . $pf->seq_region_end() ,
                   source      => $pf->source_name(), 
		 };

      $pf_info->{attributes}->{risk_allele}           = $pf->risk_allele()           if $pf->risk_allele();
      $pf_info->{attributes}->{clinical_significance} = $pf->clinical_significance() if $pf->clinical_significance();
      $pf_info->{attributes}->{external_reference}    = $pf->external_reference()    if $pf->external_reference(); ## from study - eg OMIM
      $pf_info->{attributes}->{external_id}           = $pf->external_id()           if $pf->external_id();        ## from attrib eg ClinVar
      $pf_info->{attributes}->{p_value}               = $pf->p_value()               if $pf->p_value();
      $pf_info->{attributes}->{odds_ratio}            = $pf->odds_ratio()            if $pf->odds_ratio();
      $pf_info->{attributes}->{beta_coefficient}      = $pf->beta_coefficient()      if $pf->beta_coefficient();
      $pf_info->{attributes}->{associated_gene}       = $pf->associated_gene()       if $pf->associated_gene();
    }
    
    if ($pf_info) {
      $pf_info->{ontology_accessions} = $ontology_accessions if (scalar(@$ontology_accessions));

      push(@{$record_data{$object_id}}, $pf_info);
    }
  }

  my @phenotype_features;
  foreach my $id (keys(%record_data)) {
    my $entry = { 'id' => $id, 'phenotype_associations' => $record_data{$id}};
    push @phenotype_features, $entry;
  }

  return \@phenotype_features;
}

1;
