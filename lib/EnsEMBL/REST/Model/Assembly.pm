package EnsEMBL::REST::Model::Assembly;

use Moose;
extends 'Catalyst::Model';
with 'Catalyst::Component::InstancePerContext';

has 'context' => (is => 'ro');

sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  return $self->new({ context => $c, %$self, @args });
}

sub fetch_info {
  my ($self) = @_;
  
  my $c = $self->context();
  my $species = $c->stash->{species};

  my $gc = $c->model('Registry')->get_adaptor($species, 'core', 'GenomeContainer');
  my $csa = $c->model('Registry')->get_adaptor($species, 'core', 'CoordSystem');
  my %assembly_info;
  $assembly_info{top_level_region} = $self->get_slice_info($gc, 'toplevel');
  $assembly_info{karyotype} = $self->get_slice_names($gc, 'karyotype');
  $assembly_info{assembly_name} = $gc->get_assembly_name;
  $assembly_info{assembly_date} = $gc->get_assembly_date;
  $assembly_info{genebuild_start_date} = $gc->get_genebuild_start_date;
  $assembly_info{genebuild_method} = $gc->get_genebuild_method;
  $assembly_info{genebuild_initial_release_date} = $gc->get_genebuild_initial_release_date;
  $assembly_info{genebuild_last_geneset_update} = $gc->get_genebuild_last_geneset_update;
  $assembly_info{coord_system_versions} = $csa->get_all_versions();
  $assembly_info{default_coord_system_version} = $gc->get_version();

  return \%assembly_info;
}

sub get_slice_info {
  my ($self, $gc, $type) = @_;
  
  my $method = "get_" . $type;
  my $slices = $gc->$method;
  my @toplevels;
  my $toplevels;
  
  foreach my $slice (@$slices) {
    push @toplevels, $self->features_as_hash($slice);
  }
  return \@toplevels;
}

sub features_as_hash {
  my ($self, $slice) = @_;
  my $features;
  $features->{coord_system} = $slice->coord_system_name();
  $features->{name} = $slice->seq_region_name();
  $features->{length} = $slice->length();
  return $features;
}


sub get_slice_names {
  my ($self, $gc, $type) = @_;

  my $method = "get_" . $type;
  my $slices = $gc->$method;
  my $names = [ map { $_->seq_region_name() } @{$slices} ];
  return $names;
}

__PACKAGE__->meta->make_immutable;

1;
