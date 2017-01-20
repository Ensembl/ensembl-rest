=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
Copyright [2016-2017] EMBL-European Bioinformatics Institute

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

package EnsEMBL::REST::Model::DatabaseIDLookup;

use Moose;
use Scalar::Util qw/weaken/;
use namespace::autoclean;

extends 'Catalyst::Model';
with 'Catalyst::Component::InstancePerContext';

has 'long_lookup' => (isa => 'Bool', is => 'ro', builder => 'build_long_lookup');
has 'context' => (is => 'ro', weak_ref => 1);

sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  weaken($c);
  return $self->new({ context => $c, %$self, @args });
}

sub build_long_lookup {
  return 0;
}

sub find_object_location {
  my ($self, $id, $object_type, $db_type, $species, $use_archive) = @_;
  my $reg = $self->context->model('Registry');
  
  my @captures;
  my $force_long_lookup = $self->long_lookup();
  
  if($object_type && $object_type eq 'predictiontranscript') {
    @captures = $self->find_prediction_transcript($id, $object_type, $db_type, $species);
  }
  else {
    $self->context->log->debug(sprintf('Looking for %s with %s and %s in %s', $id, ($object_type || q{?}), ($db_type || q{?}), ($species || q{?})));
    @captures = $reg->get_species_and_object_type($id, $object_type, $species, $db_type, $force_long_lookup, $use_archive);
  }
  
  return @captures;
}

sub find_prediction_transcript {
  my ($self, $id, $object_type, $db_type, $species) = @_;
  my $reg = $self->context->model('Registry');
  $db_type = 'core' if !$db_type;
  my $pred_trans_adaptor = $reg->get_adaptor($species, $db_type, $object_type);
  my $obj = $pred_trans_adaptor->fetch_by_stable_id($id);
  return ($species, $object_type, $db_type);
}

1;
