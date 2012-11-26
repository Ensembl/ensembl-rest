package EnsEMBL::REST::Model::Feature;

use Moose;
extends 'Catalyst::Model';

use EnsEMBL::REST::EnsemblModel::ExonTranscript;
use EnsEMBL::REST::EnsemblModel::CDS;

has 'allowed_features' => ( isa => 'HashRef', is => 'ro', lazy => 1, default => sub {
  return {
    map { $_ => 1 } qw/gene transcript cds exon repeat simple misc variation somatic_variation structural_variation somatic_structural_variation constrained regulatory/
  };
});

sub fetch_features {
  my ($self, $c) = @_;
  
  my $is_gff3 = $self->is_content_type($c, 'text/x-gff3');
  
  my $allowed_features = $self->allowed_features();
  my $feature = $c->request->parameters->{feature};
  $c->go('ReturnError', 'custom', ["No feature given. Please specify a feature to retrieve from this service"]) if ! $feature;
  my @features = (ref($feature) eq 'ARRAY') ? @{$feature} : ($feature);
  
  my $slice = $c->stash()->{slice};
  my @final_features;
  foreach my $feature_type (@features) {
    $feature_type = lc($feature_type);
    next if $feature_type eq 'none';
    my $allowed = $allowed_features->{$feature_type};
    $c->go('ReturnError', 'custom', ["The feature type $feature_type is not understood"]) if ! $allowed;
    my $objects = $self->$feature_type($c, $slice);
    if($is_gff3) {
      push(@final_features, @{$objects});
    }
    else {
      push(@final_features, @{$self->to_hash($objects, $feature_type)});
    }
  }
  
  return \@final_features;
}

#Have to do this to force JSON encoding to encode numerics as numerics
my @KNOWN_NUMERICS = qw( start end strand );

sub to_hash {
  my ($self, $features, $feature_type) = @_;
  my @hashed;
  foreach my $feature (@{$features}) {
    my $hash = $feature->summary_as_hash();
    foreach my $key (@KNOWN_NUMERICS) {
      my $v = $hash->{$key};
      $hash->{$key} = ($v*1) if defined $v;
    }
    $hash->{feature_type} = $feature_type;
    push(@hashed, $hash);
  }
  return \@hashed;
}

sub gene {
  my ($self, $c, $slice) = @_;
  return $slice->get_all_Genes($self->_get_logic_dbtype($c));
}

sub transcript {
  my ($self, $c, $slice, $load_exons) = @_;
  return $slice->get_all_Transcripts($load_exons, $self->_get_logic_dbtype($c));
}

sub cds {
  my ($self, $c, $slice, $load_exons) = @_;
  my $transcripts = $self->transcript($c, $slice, 0);
  return EnsEMBL::REST::EnsemblModel::CDS->new_from_Transcripts($transcripts);
}

sub exon {
  my ($self, $c, $slice) = @_;
  my $exons = $slice->get_all_Exons();
  return EnsEMBL::REST::EnsemblModel::ExonTranscript->build_all_from_Exons($exons);
}

sub repeat {
  my ($self, $c, $slice) = @_;
  return $slice->get_all_RepeatFeatures();
}

sub variation {
  my ($self, $c, $slice) = @_;
  return $slice->get_all_VariationFeatures($self->_get_SO_terms($c));
}

sub structural_variation {
  my ($self, $c, $slice) = @_;
  my @so_terms = $self->_get_SO_terms($c);
  my ($source, $include_evidence, $somatic) = (undef)x3;
  my $sv_class = (@so_terms) ? $so_terms[0] : ();
  return $slice->get_all_StructuralVariationFeatures($source, $include_evidence, $somatic, $sv_class);
}

sub somatic_variation {
  my ($self, $c, $slice) = @_;
  return $slice->get_all_somatic_VariationFeatures($self->_get_SO_terms($c));
}

sub somatic_structural_variation {
  my ($self, $c, $slice) = @_;
  my @so_terms = $self->_get_SO_terms($c);
  my ($source, $include_evidence, $somatic) = (undef)x3;
  my ($sv_class) = @so_terms;
  return $slice->get_all_somatic_StructuralVariationFeatures($source, $include_evidence, $somatic, $sv_class);
}

sub constrained {
  my ($self, $c, $slice) = @_;
  my $species_set = $c->request->parameters->{species_set} || 'mammals';
  my $compara_name = $c->model('Registry')->get_compara_name_for_species($c->stash()->{species});
  my $mlssa = $c->model('Registry')->get_adaptor($compara_name, 'compara', 'MethodLinkSpeciesSet');
  $c->go('ReturnError', 'custom', ["No adaptor found for compara Multi and adaptor MethodLinkSpeciesSet"]) if ! $mlssa;
  my $method_list = $mlssa->fetch_by_method_link_type_species_set_name('GERP_CONSTRAINED_ELEMENT', $species_set);
  my $cea = $c->model('Registry')->get_adaptor($compara_name, 'compara', 'ConstrainedElement');
  $c->go('ReturnError', 'custom', ["No adaptor found for compara Multi and adaptor ConstrainedElement"]) if ! $cea;
  return $cea->fetch_all_by_MethodLinkSpeciesSet_Slice($method_list, $slice);
}

sub regulatory {
  my ($self, $c, $slice) = @_;
  my $species = $c->stash->{species};
  my $rfa = $c->model('Registry')->get_adaptor( $species, 'funcgen', 'regulatoryfeature');
  $c->go('ReturnError', 'custom', ["No adaptor found for species $species, object regulatoryfeature and db funcgen"]) if ! $rfa;
  return $rfa->fetch_all_by_Slice($slice);
}

sub simple {
  my ($self, $c, $slice) = @_;
  my ($logic_name, $db_type) = $self->_get_logic_dbtype($c);
  return $slice->get_all_SimpleFeatures($logic_name, undef, $db_type);
}

sub misc {
  my ($self, $c, $slice) = @_;
  my $db_type = $c->request->parameters->{db_type};
  my $misc_set = $c->request->parameters->{misc_set} || undef;
  return $slice->get_all_MiscFeatures($misc_set, $db_type);
}

sub _get_SO_terms {
  my ($self, $c) = @_;
  my $so_term = $c->request->parameters->{so_term};
  my $terms = (! defined $so_term)  ? [] 
                                    : (ref($so_term) eq 'ARRAY') 
                                    ? $so_term 
                                    : [$so_term];
  my @final_terms;
  foreach my $term (@{$terms}) {
    if($term =~ /^SO\:/) {
      my $ontology_term = $c->model('Lookup')->ontology_accession_to_OntologyTerm($c, $term);
      if(!$ontology_term) {
        $c->go('ReturnError', 'custom', ["The SO accession '${term}' could not be found in our ontology database"]);
      }
      push(@final_terms, $ontology_term->name());
    }
    else {
      push(@final_terms, $term);
    }
  }
  return \@final_terms;
}

sub _get_logic_dbtype {
  my ($self, $c) = @_;
  my $logic_name = $c->request->parameters->{logic_name};
  my $db_type = $c->request->parameters->{db_type};
  return ($logic_name, $db_type);
}

with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;