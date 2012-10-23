package EnsEMBL::REST::Model::Feature;

use Moose;
extends 'Catalyst::Model';

use EnsEMBL::REST::EnsemblModel::ExonTranscript;
use EnsEMBL::REST::EnsemblModel::CDS;
use EnsEMBL::REST::EnsemblModel::ProjectedProteinFeature;
use Bio::EnsEMBL::Utils::Scalar qw/wrap_array/;

has 'allowed_features' => ( isa => 'HashRef', is => 'ro', lazy => 1, default => sub {
  return {
    map { $_ => 1 } qw/gene transcript cds exon variation somatic_variation structural_variation somatic_structural_variation constrained regulatory/
  };
});

sub fetch_features {
  my ($self, $c) = @_;
  my $slice = $c->stash()->{slice};
  my $object = $c->stash()->{object};
  
  my $allowed_features = $self->allowed_features();
  my $feature_types = $c->request->parameters->{feature};
  $c->go('ReturnError', 'custom', ["No feature given"]) if ! $feature_types;
  $feature_types = wrap_array($feature_types);
  
  if($slice) {
    return $self->fetch_features_by_Slice($c, $slice, $feature_types);
  }
  return $self->fetch_features_by_Object($c, $object, $feature_types);
}

sub fetch_features_by_Slice {
  my ($self, $c, $slice, $feature_types, $callback_mapper) = @_;
  warn $slice->name();
  my $is_gff3 = $self->is_content_type($c, 'text/x-gff3');
  
  my $allowed_features = $self->allowed_features();
  
  my @final_features;
  foreach my $feature_type (@{$feature_types}) {
    $feature_type = lc($feature_type);
    my $allowed = $allowed_features->{$feature_type};
    $c->go('ReturnError', 'custom', ["The feature type $feature_type is not understood"]) if ! $allowed;
    my $objects = $self->$feature_type($c, $slice);
    $objects = $callback_mapper->($objects) if $callback_mapper;
    if($is_gff3) {
      push(@final_features, @{$objects});
    }
    else {
      push(@final_features, @{$self->to_hash($objects, $feature_type)});
    }
  }
  
  return \@final_features;
}

sub fetch_features_by_Object {
  my ($self, $c, $object, $feature_types) = @_;
  
  if($object->isa('Bio::EnsEMBL::Translation')) {
    my $transcript = $object->transcript();
    my $start = 1;
    my $end = $object->length();
    my @coords = $transcript->pep2genomic($start, $end);
    my @features;
    my $slice = $transcript->slice();
    foreach my $coord (@coords) {
      next if $coord->isa('Bio::EnsEMBL::Mapper::Gap');
      my $sub_slice = $slice->sub_Slice($coord->start(), $coord->end(), $coord->strand());
      my $sub_features = $self->fetch_features_by_Slice($c, $sub_slice, $feature_types, sub {
        my ($objects) = @_;
        return EnsEMBL::REST::EnsemblModel::ProjectedProteinFeature->new_from_Features($objects);
      });
      push(@features, @{$sub_features});
    }
    return \@features;
  }
  
  #If it was not a translation then just return everything at that feature Slice
  return $self->fetch_features_by_Slice($c, $object->feature_Slice(), $feature_types);
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
  my $sv_class = (@so_terms) ? $so_terms[0] : ();
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

sub _get_SO_terms {
  my ($self, $c) = @_;
  my $so_term = $c->request->parameters->{so_term};
  my $terms = (! defined $so_term)  ? [] 
                                    : (ref($so_term) eq 'ARRAY') 
                                    ? $so_term 
                                    : [$so_term];
  return $terms;
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