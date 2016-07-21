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

package EnsEMBL::REST::Model::Phenotype;
use Data::Dumper;
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
warn "getting children\n";
    my $parentterm = $ont_ad->fetch_by_accession($accession );
    my $childterms = $ont_ad->fetch_all_by_parent_term($parentterm);
    foreach my $childterm (@{$childterms}){
      @phenotype_features = (@phenotype_features, @{$self->fetch_features($species, $childterm->accession)}  );
    }
  }

#print "\nReturning: " ; print Dumper @phenotype_features;

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
warn "Seeking term " . $term->accession() ." for $name\n";
    @phenotype_features = (@phenotype_features, @{$self->fetch_by_accession($species, $term->accession())} );
  }

  warn "returning " . scalar @phenotype_features . " phenotype_features\n";
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

  my $pfs = $phenfeat_ad->fetch_all_by_phenotype_accession_source($accession, $self->context->request->param('source'));

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
  warn "returning " . scalar @phenotype_features . " phenotype_features for $accession\n";
  return \@phenotype_features;
}

1;
