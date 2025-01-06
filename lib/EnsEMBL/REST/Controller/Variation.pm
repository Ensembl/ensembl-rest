=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
Copyright [2016-2025] EMBL-European Bioinformatics Institute

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

package EnsEMBL::REST::Controller::Variation;

use Moose;
use namespace::autoclean;
use Try::Tiny;
use Bio::EnsEMBL::Utils::Scalar qw/check_ref/;
require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);
=pod

/variation/species/rs1333049

application/json

=cut

BEGIN {extends 'Catalyst::Controller::REST'; }
with 'EnsEMBL::REST::Role::PostLimiter';


sub species: Chained('/') PathPart('variation') CaptureArgs(1) {
  my ( $self, $c, $species) = @_;
  $c->stash(species => $species);
}

sub id: Chained('species') PathPart('') ActionClass('REST') {}

sub id_GET {
  my ($self, $c, $id) = @_;
  my $variation;
  try {
    $variation = $c->model('Variation')->fetch_variation($id);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  $self->status_ok($c, entity => $variation);
}

sub id_POST {
  my ($self, $c) = @_;
  my %variations;
  my $data = $c->request->data;
  unless (exists $data->{ids}) { $c->go('ReturnError','custom', [qq/You POST data does not contain a list keyed by 'ids'/])}
  my $id_list;
  if (exists $data->{ids}) { $id_list = $data->{ids} };
  $self->assert_post_size($c,$id_list);
  try {
    %variations = %{$c->model('Variation')->fetch_variation_multiple($id_list)};
  } catch {$c->log->debug('Problems:'.$_)};
  $self->status_ok($c, entity => \%variations);
}

# /variation/:species/pmid/:pmid
sub pmid : Chained('species') PathPart('pmid') ActionClass('REST') {
  my ($self, $c, $pmid) = @_;
}

sub pmid_GET {
  my ($self, $c, $pmid) = @_;

  unless ($pmid) {$c->go('ReturnError', 'custom', ["PMID is a required parameter for this endpoint"])}

  if ($pmid !~ /^\d+$/i) {
    my $error_msg = qq{PMID must be an integer [got: $pmid]};
    $c->go( 'ReturnError', 'custom', [$error_msg] );
  } 

  my $variants = [];
  try {
    $variants = $c->model('Variation')->fetch_variants_pmid($pmid);

  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  $self->status_ok($c, entity => $variants);
}

# /variation/:species/pmcid/:pmcid
sub pmcid : Chained('species') PathPart('pmcid') ActionClass('REST') {
  my ($self, $c, $pmcid) = @_;
}

sub pmcid_GET {
  my ($self, $c, $pmcid) = @_;

  unless ($pmcid) {$c->go('ReturnError', 'custom', ["PMCID is a required parameter for this endpoint"])}

  my $variants = [];
  try {
    $variants = $c->model('Variation')->fetch_variants_pmcid($pmcid);

  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  $self->status_ok($c, entity => $variants);
}


__PACKAGE__->meta->make_immutable;

1;
