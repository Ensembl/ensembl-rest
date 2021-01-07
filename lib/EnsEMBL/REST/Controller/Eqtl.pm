=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2021] EMBL-European Bioinformatics Institute

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
#
use feature qw(say);
use Data::Dumper;

=pod

/eqtl/Blood/ENSG01234567891

application/json

=cut

BEGIN {
  extends 'Catalyst::Controller::REST';
}

sub species_id_GET {}
sub species_variant_GET {}
sub tissue_GET {}


sub tissue: Chained('/') : PathPart('eqtl/tissue') : Args(1) ActionClass('REST') {
  my ($self, $c, $species) = @_;

  my $u_param->{species}  = $species;

  try {
    $self->status_ok($c, entity => $c->model('Eqtl')->fetch_all_tissues($u_param));
  }
  catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  }
}

# /eqtl/gtxstable_id/:species/:id?tissue=*;statistic=*;variant_name=*
sub species_id: Chained('/') : PathPart('eqtl/id') : Args(2) ActionClass('REST') {
  my ($self, $c, $species, $stable_id) = @_;

  $self->_check_req_params($c);

  my $u_param = {};
  $u_param->{species}      = $species;
  $u_param->{stable_id}    = $stable_id;
  $u_param->{tissue}       = $c->req->param('tissue');
  $u_param->{variant_name} = $c->req->param('variant_name');
  $u_param->{statistic}    = $c->req->param('statistic');
  $u_param->{web}    = $c->req->param('web');


  try {
    $self->status_ok($c, entity => $c->model('Eqtl')->fetch_eqtl($u_param));
  }
  catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  }
}
# /eqtl/variant_name/:species/:variant?tissue=*;statistic=*;id=*
sub species_variant: Chained('/') : PathPart('eqtl/variant_name') : Args(2) ActionClass('REST') {
  my ($self, $c, $species, $variant_name) = @_;

  $self->_check_req_params($c);

  my $u_param = {};
  $u_param->{species}      = $species;
  $u_param->{variant_name} = $variant_name;
  $u_param->{tissue}       = $c->req->param('tissue');
  $u_param->{stable_id}    = $c->req->param('stable_id');
  $u_param->{statistic}    = $c->req->param('statistic');
  $u_param->{web}    = $c->req->param('web');

  try {
    $self->status_ok($c, entity => $c->model('Eqtl')->fetch_eqtl($u_param));
  }
  catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  }
}

=head2 _check_req_params

  Arg [1]    : Context Object
  Example    : $self->_check_req_params($context)
  Description: Parameters passed once are scalar, muliple once are ARRAY.
               The method checks for ARRAY and HASH Refs.
  Returntype : None
  Exceptions : Throws if ARRAY or HASH are found.
  Caller     : general
  Status     : Stable

=cut

sub _check_req_params {
  my ($self, $c) = @_;

  my $params = $c->req->params;

  for my $p (sort keys %{$params}) {
    if(ref $params->{$p} eq 'ARRAY') {
      $c->go('ReturnError', 'custom', ["Duplicated parameter '$p' supplied"]);
    }
    if(ref $params->{$p} eq 'HASH') {
      $c->go('ReturnError', 'from_ensembl', ["Hash in req_param not implemented"]);
    }
  }
}

__PACKAGE__->meta->make_immutable;

1;
