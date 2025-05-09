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

package EnsEMBL::REST::Controller::VariantRecoder;
use Moose;
use namespace::autoclean;
use Data::Dumper;
use Bio::EnsEMBL::VEP::VariantRecoder;

use Try::Tiny;

require EnsEMBL::REST;

EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);
BEGIN { 
  extends 'Catalyst::Controller::REST';
}

# This list describes user overridable variables for this endpoint. It protects other more fundamental variables
has valid_user_params => ( 
  is => 'ro', 
  isa => 'HashRef', 
  traits => ['Hash'], 
  handles => { valid_user_param => 'exists' },
  default => sub { return { map {$_ => 1} (qw/
    gencode_basic

    failed
    minimal
    fields

    vcf_string
    var_synonyms

    ga4gh_vrs
    /) }
  }
);

with 'EnsEMBL::REST::Role::PostLimiter';

# /variant_recoder/:species
sub species : Chained('/') PathPart('variant_recoder') CaptureArgs(1) {
  my ( $self, $c, $species ) = @_;
  my $reg = $c->model('Registry');
  $c->stash->{species} = $reg->get_alias($species);

  my ($csa, $css);
  try {
    $csa = $reg->get_adaptor($species, 'core', 'coordsystem');
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  try {
    $css = $csa->fetch_all;
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };

  $c->stash->{assembly} = $css->[0]->version;
  $c->stash->{has_variation} = $c->model('Registry')->get_adaptor( $species, 'Variation', 'Variation');
  $c->log->debug('Working with species '.$species);
}


# /variant_recoder/:species/:id
sub id: Chained('species') PathPart('') ActionClass('REST') {}

sub id_GET {
  my ( $self, $c, $rs_id ) = @_;
  
  unless ($rs_id) {$c->go('ReturnError', 'custom', ["variant ID is a required parameter for this endpoint"])}

  my $user_config = $c->request->parameters;
  my $config = $self->_include_user_params($c,$user_config);

  $self->get_results($c, $config, $rs_id);
}

sub id_POST {
  my ($self, $c) = @_;
  
  my $post_data = $c->req->data;
  my $config = $self->_include_user_params($c, $post_data);

  my $input_data = $post_data->{ids} || $post_data->{data} || $post_data->{data};

  unless ($input_data) {
    $c->go( 'ReturnError', 'custom', [ ' Cannot find "ids" key in your POST. Please check the format of your message against the documentation' ] );
  }

  $self->assert_post_size($c, $input_data);
  $self->get_results($c, $config, join("\n", @$input_data));
}

sub get_results {
  my ($self, $c, $config, $input_data) = @_;

  my ($vr, $results);

  try {
    $vr = Bio::EnsEMBL::VEP::VariantRecoder->new($config);
    $vr->registry($c->model('Registry')->_registry());
    $vr->{plugins} = $config->{plugins} || [];
    $results = $vr->recode($input_data);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };

  # catch and report errors/warnings
  my $warnings = $vr->warnings();
  $c->go('ReturnError', 'custom', [map {$_->{msg}} @$warnings]) if !@$results && @$warnings;

  $c->stash->{results} = $results;

  $self->status_ok( $c, entity => $results );
}

sub _include_user_params {
  my ($self,$c,$user_config) = @_;

  # copy in params from URL
  # first copy *everything* to %tmp_vr_params from URL ($c->request->params) and POST body ($user_config)
  # data body ($user_config) takes precedence over URL, so add those second and don't worry about overwrite
  my %tmp_vr_params;
  map { $tmp_vr_params{$_} = $c->request()->param($_)} keys %{$c->request->params()};
  map { $tmp_vr_params{$_} = $user_config->{$_}} keys %{$user_config};

  # only copy allowed keys to %vr_params as we don't want users to be able to meddle
  my %vr_params = ( species => $c->stash->{species} );
  $vr_params{$_} = $tmp_vr_params{$_} for grep { $self->valid_user_param($_) } keys %tmp_vr_params;

  return \%vr_params;
}


__PACKAGE__->meta->make_immutable;

