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

package EnsEMBL::REST::Controller::TranscriptHaplotypes;
use Moose;
use namespace::autoclean;
use Try::Tiny;
require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

BEGIN {extends 'Catalyst::Controller::REST';}
with 'EnsEMBL::REST::Role::PostLimiter';

sub species: Chained('/') PathPart('transcript_haplotypes') CaptureArgs(1) {
  my ( $self, $c, $species) = @_;
  $c->stash(species => $species);
}

sub id: Chained('species') PathPart('') ActionClass('REST') {}

sub id_GET {
  my ($self, $c, $id) = @_;

  my $species = $c->stash->{species};

  my $ta = $c->model('Registry')->get_adaptor( $species, 'Core', 'Transcript');
  my $t = $ta->fetch_by_stable_id($id);

  $c->go( 'ReturnError', 'custom', [qq{Unable to fetch transcript with ID $id}] ) unless $t;
  $c->go( 'ReturnError', 'custom', [qq{Unable to get haplotypes for a non-coding transcript}] ) unless $t->translation;

  my $var_params = $c->config->{'Model::Variation'};
  unless($var_params && $var_params->{use_vcf}) {
    $c->go( 'ReturnError', 'no_content', [qq{Unable to fetch haplotypes without VCF configuration}] );
  }

  my $thca = $c->model('Registry')->get_adaptor( $species, 'Variation', 'TranscriptHaplotype');

  my $vdb = $thca->db;

  if($var_params->{vcf_config}) {
    $vdb->vcf_config_file($var_params->{vcf_config});
    $vdb->vcf_root_dir($var_params->{dir}) if defined $var_params->{dir};
  }
  
  my $thc;

  try {
    $thc = $thc = $thca->get_TranscriptHaplotypeContainer_by_Transcript($t);

    foreach my $key(qw(samples sequence aligned_sequences)) {
      my $api_key = $key eq 'sequence' ? 'seq' : $key;
      $thc->_dont_export($api_key) unless $c->request->param($key);
    }

  } catch {
    $c->go('ReturnError', 'from_ensembl', []) if $_ =~ /STACK/;    
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };

  $self->status_ok($c, entity => $thc->TO_JSON);
}

__PACKAGE__->meta->make_immutable;
1;
