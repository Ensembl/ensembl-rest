package EnsEMBL::REST::Model::Feature;

use Moose;
extends 'Catalyst::Model';

use EnsEMBL::REST::EnsemblModel::ExonTranscript;

has 'allowed_types' => ( isa => 'HashRef', is => 'ro', lazy => 1, default => sub {
  return {
    map { $_ => 1 } qw/gene transcript exon variation somatic_variation structural_variation somatic_structural_variation constrained regulatory/
  };
});

sub fetch_features {
  my ($self, $c) = @_;
  
  my $is_gff3 = $self->is_content_type($c, 'text/gff3');
  
  my $allowed_types = $self->allowed_types();
  my $type = $c->request->parameters->{type};
  $c->go('ReturnError', 'custom', ["No type given"]) if ! $type;
  my @types = (ref($type) eq 'ARRAY') ? @{$type} : ($type);
  
  my $slice = $c->stash()->{slice};
  my @final_features;
  foreach my $type (@types) {
    my $allowed = $allowed_types->{$type};
    $c->go('ReturnError', 'custom', ["The type $type is not understood"]) if ! $allowed;
    my $features = $self->$type($c, $slice);
    if($is_gff3) {
      push(@final_features, @{$features});
    }
    else {
      push(@final_features, @{$self->to_hash($features, $type)});
    }
  }
  
  return \@final_features;
}

sub to_hash {
  my ($self, $features, $type) = @_;
  my @hashed;
  foreach my $feature (@{$features}) {
    my $hash = $feature->summary_as_hash();
    $hash->{feature_type} = $type;
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

sub exon {
  my ($self, $c, $slice) = @_;
  my $transcripts = $self->transcript($c, $slice, 1);
  return [map { EnsEMBL::REST::EnsemblModel::ExonTranscript->build_all_from_Transcript($_) } @{$transcripts}];
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