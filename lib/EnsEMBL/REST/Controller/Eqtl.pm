=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::REST::Controller::Eqtl;

use Moose;
use namespace::autoclean;
use Try::Tiny;
use Bio::EnsEMBL::Utils::Scalar qw/check_ref/;
require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

=pod

/eqtl/Blood/ENSG01234567891

application/json

=cut

BEGIN {
  extends 'Catalyst::Controller::REST';
#  with 'CatalystX::LeakChecker';
}

# Potentially register as cell_type

has 'tissues' => (
    is      => 'ro',
    builder => '_available_tissues',
    );

has 'species' => (
    is      => 'ro',
    builder => '_available_species',
    );

has 'allowed_values' => (
    is      => 'ro',
    builder => '_allowed_values',
    lazy =>1
    );

use Data::Dumper;

sub species_id_GET {}
sub species_variant_GET {}

# /eqtl/gtxstable_idd/:species/:id?tissue=*;statistic=*;variant_name=*
sub species_id: Chained('/') : PathPart('eqtl/id') : Args(2) ActionClass('REST') {
  my ($self, $c, $species, $stable_id) = @_;


  $c->stash(species => $species);
  $c->stash(stable_id => $stable_id);

  $c->stash->{tissue}    = $c->req->param('tissue');
  $c->stash->{variant_name}   = $c->req->param('variant_name');
  $c->stash->{statistic} = $c->req->param('statistic');

  my $validate = {};
  $validate->{species} = $species;
  if(defined $c->stash->{tissue}){
    $validate->{tissue}  = $c->stash->{tissue};
  }

  _validate($self, $c, $validate);


  my $eqtl = $c->model('Eqtl')->fetch_eqtl();
  $self->status_ok($c, entity=>$eqtl);
}

# /eqtl/variant_name/:species/:variant?tissue=*;statistic=*;id=*
sub species_variant: Chained('/') : PathPart('eqtl/variant_name') : Args(2) ActionClass('REST') {
  my ($self, $c, $species, $variant_name) = @_;

  $c->stash(species => $species);
  $c->stash(variant_name => $variant_name);

  $c->stash->{tissue}    = $c->req->param('tissue');
  $c->stash->{stable_id}   = $c->req->param('stable_id');
  $c->stash->{statistic} = $c->req->param('statistic');

  my $validate = {};
  $validate->{species} = $species;
  $validate->{tissue}  = $c->stash->{tissue};
#  if(defined $c->stash->{tissue}){
#    $validate->{tissue}  = $c->stash->{tissue};
#  }
  _validate($self, $c, $validate);

  my $eqtl = $c->model('Eqtl')->fetch_eqtl();
  $self->status_ok($c, entity=>$eqtl);
}

sub _validate {
  my ($self, $c, $validate) = @_;

  if(!exists $self->allowed_values->{species}->{$validate->{species}}){
    my $species = join("\n", @{$self->species});
    $c->go('ReturnError', 'custom', ["Species unrecognized. Available species: $species"]);
  }

  if(defined $validate->{tissue}) {
    if(!exists $self->allowed_values->{tissue}->{$validate->{tissue}}){
      my $tissues = join("\n", @{$self->tissues});
      $c->go('ReturnError', 'custom', ["Tissue unrecognized. Available tissues: $tissues"]);
    }
  }
}

sub _available_tissues {
  my ($self) = @_;
  my $a = [qw(
    Adipose_Subcutaneous
    Artery_Aorta
    Artery_Tibial
    Cells_Transformed_fibroblasts
    Esophagus_Mucosa
    Esophagus_Muscularis
    Heart_Left_Ventricle
    Lung
    Muscle_Skeletal
    Nerve_Tibial
    Skin_Sun_Exposed_Lower_leg
    Stomach
    Thyroid
    Whole_Blood
      )];
  return $a;
}

sub _available_species {
  my ($self) = @_;
  my $a = [qw(
      homo_sapiens
      human
      )];
}

sub _allowed_values {
  my ($self) = @_;
  my $allowed_values = {
    tissue    => { map { $_, 1} @{$self->tissues}  },
    species   => { map { $_, 1} @{$self->species}  },
  };
  return $allowed_values;
}

##  if( defined $c->stash->{stable_id}){
##    if(!defined $c->stash->{tissue}) {
##      $c->go('ReturnError', 'custom', ["You also have to define a tissue"]);
##    }
##  }
#
##  if(!defined $c->stash->{stable_id}){
##    if(!defined $c->stash->{snp}){
##      $c->go('ReturnError', 'custom', ["You have to either define a stable_id or a snp"]);
##    }
##  }
##
#

__PACKAGE__->meta->make_immutable;

1;
