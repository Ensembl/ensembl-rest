=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2018] EMBL-European Bioinformatics Institute

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

package EnsEMBL::REST::Controller::Regulatory;

use Moose;
use namespace::autoclean;
use Try::Tiny;
use Bio::EnsEMBL::Utils::Scalar qw/check_ref/;
require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

=pod

/regulatory/species/ENSR00001348195

application/json

=cut

BEGIN {extends 'Catalyst::Controller::REST'; }

#protect against missing variables

sub species: Chained('/') PathPart('regulatory/species') CaptureArgs(1) {
  my ( $self, $c, $species) = @_;

  unless (defined $species) { $c->go('ReturnError','custom',[qq{Species must be provided as part of the URL.}])}
  $c->stash(species => $species);
}

#this is a temp subroutine, almost identical to the 'species' one.
#It's used in order to ommit the 'regulatory' term from the endpoint string
#without disrupting the other endpoints that contain it.
sub species2: Chained('/') PathPart('species') CaptureArgs(1) {
  my ( $self, $c, $species) = @_;

  unless (defined $species) { $c->go('ReturnError','custom',[qq{Species must be provided as part of the URL.}])}
  $c->stash(species => $species);
}


# /regulatory/species/:species/id/:id
sub id: Chained('species') PathPart('id') Args(1) ActionClass('REST') {
  my ( $self, $c, $id) = @_;

  if(! defined $id){
    $c->go('ReturnError','custom',[qq{Ensembl Stable ID  must be provided as part of the URL.}]);
  }
  if($id !~ /ENSR\d{11}/){
    $c->go('ReturnError','custom',[qq{Ensembl Regulation Stable IDs  have the format ENSR12345678901.}])
  }
}

sub id_GET {
  my ($self, $c, $id) = @_;
  my $regf;

  try {
    $regf = $c->model('Regulatory')->fetch_regulatory_feature($id);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  $self->status_ok($c, entity => $regf);

}

# /regulatory/species/:species/epigenome/
sub epigenome: Chained('species') PathPart('epigenome') ActionClass('REST') { }

sub epigenome_GET {
  my ($self, $c) = @_;

  my $epigenomes;
  try {
    $epigenomes = $c->model('Regulatory')->fetch_all_epigenomes();
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  $self->status_ok($c, entity => $epigenomes);
}

# /species/:species/binding_matrix/:binding_matrix_stable_id/
sub binding_matrix : Chained('species2') PathPart('binding_matrix') Args(1) {
    my ( $self, $c, $binding_matrix_stable_id ) = @_;

    unless ( defined $binding_matrix_stable_id ) {
        $c->go( 'ReturnError', 'custom',
            [qq{Binding Matrix stable id must be provided as part of the URL.}] );
    }

    # $c->stash( binding_matrix_name => $binding_matrix_name );

    my $binding_matrix;
    try {
        $binding_matrix =
          $c->model('Regulatory')->get_binding_matrix($binding_matrix_stable_id);
    }
    catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  $self->status_ok($c, entity => $binding_matrix);
}

# /regulatory/species/:species/microarray
sub microarray_list: Chained('species') PathPart('microarray') ActionClass('REST') { }
sub microarray_list_GET {
  my ($self, $c) = @_;

    my $microarrays;
    try {
      $microarrays = $c->model('Regulatory')->list_all_microarrays();
    }catch {
      $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
      $c->go('ReturnError', 'custom', [qq{$_}]);
    };
    $self->status_ok($c, entity => $microarrays);
}

# stash array name
sub microarray :Chained('species') PathPart('microarray') CaptureArgs(1) ActionClass('REST') {
  my ($self, $c, $microarray) = @_;
  if(! defined $microarray){
    $c->go('ReturnError', 'custom', [qq{Microarray name must be provided as part of the URL.}]);
  }
}
sub microarray_GET {
  my ($self, $c, $microarray) = @_;
  $c->stash(microarray => $microarray);
}

# /regulatory/species/:species/microarray/:microarray/vendor/:vendor
sub microarray_single: Chained('microarray') PathPart('vendor') Args(1) ActionClass('REST') {
  my ($self, $c, $vendor) = @_;
  if(! defined $vendor){
    $c->go('ReturnError', 'custom', [qq{Vendor name must be provided as part of the URL.}]);
  }
}
sub microarray_single_GET {
  my ($self, $c, $vendor) = @_;

  my $info;
  try {
    $info = $c->model('Regulatory')->get_microarray_info($vendor);
  }catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };

  $self->status_ok($c, entity => $info);


}

# /regulatory/species/:species/microarray/:microarray/probe/:probe
# /regulatory/species/homo_sapiens/microarray/HC-G110/vendor/affy/
sub microarray_probe: Chained('microarray') PathPart('probe') Args(1) ActionClass('REST') {
  my ($self, $c, $probe_name) = @_;
  if(! defined $probe_name){
    $c->go('ReturnError', 'custom', [qq{Probe name must be provided as part of the URL.}]);
  }
}

sub microarray_probe_GET {
  my ($self, $c, $probe_name) = @_;

  my $probe_info;

  try {
    $probe_info = $c->model('Regulatory')->get_probe_info($probe_name);
  }catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };

  $self->status_ok($c, entity => $probe_info);
}



# /regulatory/species/:species/microarray/:microarray/probe_set/:probe_set
# /regulatory/species/homo_sapiens/microarray/HC-G110/vendor/affy/
sub microarray_probe_set: Chained('microarray') PathPart('probe_set') Args(1) ActionClass('REST') {
  my ($self, $c, $probe_set) = @_;
  if(! defined $probe_set){
    $c->go('ReturnError', 'custom', [qq{ProbeSet name must be provided as part of the URL.}]);
  }
}

sub microarray_probe_set_GET {
  my ($self, $c, $probeset) = @_;

  my $probeset_info;
  try {
    $probeset_info = $c->model('Regulatory')->get_probeset_info($probeset);
  }catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };

  $self->status_ok($c, entity => $probeset_info);
}


__PACKAGE__->meta->make_immutable;

1;
