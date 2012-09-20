package EnsEMBL::REST::Controller::Assembly;

use Moose;
use namespace::autoclean;
use Try::Tiny;
require EnsEMBL::REST;
EnsEMBL::REST->turn_on_jsonp(__PACKAGE__);


BEGIN {extends 'Catalyst::Controller::REST'; }

sub species: Chained('/') PathPart('assembly/info') CaptureArgs(1) {
  my ( $self, $c, $species) = @_;
  $c->stash(species => $species);
}

sub info_GET {}

sub info: Chained('species') PathPart('') Args(0) ActionClass('REST') {
  my ($self, $c) = @_;
  my $assembly_info = try {
    my $aia = $c->model('Registry')->get_adaptor($c->stash()->{species},'Core','Assembly'); 
    $aia->fetch_info();
  }
  catch {
      $c->go( 'ReturnError', 'from_ensembl', [$_] );
  };
  $self->status_ok( $c, entity => $assembly_info);
}

sub seq_region_GET {}

sub seq_region: Chained('species') PathPart('') Args(1) ActionClass('REST') {
  my ( $self, $c, $name) = @_;
  my $slice = $c->model('Lookup')->find_slice($c, $name);
  $self->status_ok( $c, entity => { 
    length => $slice->length(),
    coordinate_system => $slice->coord_system()->name(),
    assembly_exception_type => $slice->assembly_exception_type(),
    is_chromosome => $slice->is_chromosome(),
  });
}

__PACKAGE__->meta->make_immutable;

1;
