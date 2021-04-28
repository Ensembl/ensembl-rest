=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
Copyright [2016-2020] EMBL-European Bioinformatics Institute

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

package EnsEMBL::REST::Model::Regulatory;

use Moose;
use Catalyst::Exception qw(throw);
use Try::Tiny;
use Bio::EnsEMBL::Utils::Scalar qw/wrap_array/;
use Bio::EnsEMBL::Funcgen::BindingMatrix::Converter;
use Bio::EnsEMBL::Funcgen::BindingMatrix::Constants qw ( :all );
use Scalar::Util qw/weaken/;
extends 'Catalyst::Model';

with 'Catalyst::Component::InstancePerContext';

has 'context' => (is => 'ro', weak_ref => 1);

sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  weaken($c);
  return $self->new({ context => $c, %$self, @args });
}

sub fetch_regulatory_feature {
  my ($self, $rf_id) = @_;

  my $c          = $self->context;
  my $species    = $c->stash->{species};

  my $rf_a = $c->model('Registry')->get_adaptor($species, 'funcgen', 'RegulatoryFeature');
  my $rf = $rf_a->fetch_by_stable_id($rf_id);
  if(! defined $rf) {
    Catalyst::Exception->throw("$rf_id not found for $species");
  }
  my $result = $rf->summary_as_hash();

  my $activity = $c->request->param('activity');
  if(defined $activity and $activity == 1) {
    my $data; 
    for my $ra(@{$rf->regulatory_activity}) {
      $data->{$ra->get_Epigenome->production_name} = $ra->activity;
    }
    $result->{activity} = $data;
  }

  return([$result]);

}

sub fetch_all_epigenomes {
  my ($self) = @_;

  my $c          = $self->context;
  my $species    = $c->stash->{species};

  my $reg_build_a = $c->model('Registry')->get_adaptor( $species, 'Funcgen', 'RegulatoryBuild');
  my $reg_build   = $reg_build_a->fetch_current_regulatory_build;
  my $epigenomes  = $reg_build->get_all_Epigenomes;

  my $result = [];
  for my $eg (@$epigenomes) {
    push(@$result, $eg->summary_as_hash() );
  }
  return($result);
}

sub list_all_microarrays{
  my ($self, $motif) = @_;
  
  my $c       = $self->context;
  my $species = $c->stash->{species};

  my $array_adaptor = $c->model('Registry')->get_adaptor( $species, 'Funcgen', 'Array');

  my $arrays = $array_adaptor->fetch_all;
  my $result = [];

  foreach my $array (@$arrays) {
    my $data = {};
    $data->{array}       = $array->name;
    $data->{type}        = $array->type;
    $data->{vendor}      = $array->vendor;
    $data->{description} = $array->description;
    $data->{format}      = $array->format;
    # Very Slow!
    #$data->{ProbeCount}  = $array->probe_count;
    push(@{$result}, $data);
  }

  return($result);

}


sub get_probeset_info {
  my ($self, $probeset_name) = @_;

  if(! defined $probeset_name){
   Catalyst::Exception->throw("No ProbeSet name given. Please specify one to retrieve from this service");
  }

  my $c               = $self->context;
  my $species         = $c->stash->{species};
  my $microarray_name = $c->stash->{microarray};

  my $ps_a = $c->model('Registry')->get_adaptor( $species, 'Funcgen', 'ProbeSet');
  my $ps   = $ps_a->fetch_by_array_probe_set_name($microarray_name, $probeset_name);
  
  my $probes = $ps->get_all_Probes();
  my @probe_names;
  for my $probe (@$probes) {
    push(@probe_names, $probe->name);
  }
  @probe_names = sort @probe_names;

  my $result = {};
  $result->{size}        = $ps->size;
  $result->{name}        = $ps->name;
  $result->{microarray}  = $microarray_name;
  $result->{probes}      = \@probe_names;

  my $flag_transcript = defined $c->request->param('transcript') ? $c->request->param('transcript') : 0;
  my $flag_gene       = defined $c->request->param('gene') ? $c->request->param('gene') : 0;

  # Transcript / Gene information
  if($flag_transcript == 1 || $flag_gene == 1){
    my $transript_mappings  = $ps->get_all_ProbeSetTranscriptMappings();
    $result->{transcripts} = $self->_lookup_transcript_gene($transript_mappings, $flag_gene);
  }

  return($result);
}


sub get_probe_info {
  my ($self, $probe_name) = @_;

  if(! defined $probe_name){
   Catalyst::Exception->throw("No probe name given. Please specify one to retrieve from this service");
  }

  my $c               = $self->context;
  my $species         = $c->stash->{species};
  my $microarray_name = $c->stash->{microarray};
  
  my $probe_adaptor = $c->model('Registry')->get_adaptor( $species, 'Funcgen', 'Probe');
  my $probe         = $probe_adaptor->fetch_by_array_probe_probeset_name( $microarray_name, $probe_name );

  if(! defined $probe) {
    Catalyst::Exception->throw("Probe: '$probe_name' Array: '$microarray_name'  not found. Check spelling");
  }

  my $features = {};
  $features->{microarray} = $microarray_name ;
  $features->{name}       = $probe_name ;
  $features->{length}     = $probe->length;
  $features->{sequence}   = $probe->sequence;

# Useful? Discuss. Decide  
#  $features->{probe_set}  = $probe_set if(defined $probe_set);

  my $flag_transcript = defined $c->request->param('transcript') ? $c->request->param('transcript') : 0;
  my $flag_gene       = defined $c->request->param('gene') ? $c->request->param('gene') : 0;

  # Linked transcripts
  if($flag_transcript == 1 || $flag_gene == 1){
    my $transript_mappings   = $probe->get_all_ProbeTranscriptMappings;
    $features->{transcripts} = $self->_lookup_transcript_gene($transript_mappings, $flag_gene);
  }

  return($features);
}

# Add transcript and gene information for probe/probeset

sub _lookup_transcript_gene {
  my ($self, $transript_mappings, $flag_gene) = @_;

  my $c               = $self->context;
  my $species         = $c->stash->{species};

    my $transcripts = [];
    for my $tm (@$transript_mappings) {
      my $hash = {};
      $hash->{stable_id}    = $tm->stable_id;
      $hash->{description}  = $tm->description;
      # Add gene information
      if($flag_gene == 1){
        my $type = 'Transcript';
        my $transcript =  $c->model('Lookup')->find_object($tm->stable_id, $species, 'Transcript', 'Core');
        $hash->{gene}->{stable_id}     = $transcript->get_Gene()->stable_id;
        $hash->{gene}->{external_name} = $transcript->get_Gene()->external_name;
      }
      push(@$transcripts, $hash)
    }

    return($transcripts);

}



sub get_microarray_info {
  my ($self,  $vendor) = @_;
  
  my $c       = $self->context;
  my $species = $c->stash->{species};  
  my $name    = $c->stash->{microarray};

  my $array_a = $c->model('Registry')->get_adaptor( $species, 'Funcgen', 'Array');
  my $array   = $array_a->fetch_by_name_vendor($name, $vendor);
  if(! defined $array) {
    Catalyst::Exception->throw("Array '$name' from '$vendor' not found. Please check spelling.");
  }
  
  my $result = {};
  $result->{name}   = $array->name;
  $result->{format} = $array->format;
  $result->{type}   = $array->type;
  $result->{class}  = $array->class;

  return($result);

}

sub get_binding_matrix {
    my ( $self, $binding_matrix_stable_id ) = @_;

    my $c       = $self->context();
    my $species = $c->stash->{species};
    my $binding_matrix_adaptor =
      $c->model('Registry')
      ->get_adaptor( $species, 'Funcgen', 'BindingMatrix' );
    my $binding_matrix =
      $binding_matrix_adaptor->fetch_by_stable_id($binding_matrix_stable_id);

    if ( !defined $binding_matrix ) {
        Catalyst::Exception->throw( 'Binding Matrix '
              . $binding_matrix_stable_id
              . ' not found. Please check spelling.' );
    }

    if ( defined $c->request->param('unit') ) {
        my $unit = $c->request->param('unit');
        $unit = ucfirst(lc($unit));
        my $valid_units = VALID_UNITS;
        if ( !grep $_ eq $unit, @{$valid_units} ) {
            Catalyst::Exception->throw( $unit
                  . ' is not a valid BindingMatrix unit. List of valid units: '
                  . join( ",", @{$valid_units} ) );
        }

        try {
            my $converter =
                Bio::EnsEMBL::Funcgen::BindingMatrix::Converter->new();

            if ($unit eq PROBABILITIES) {
                $binding_matrix =
                    $converter
                        ->from_frequencies_to_probabilities($binding_matrix);
            }

            if ($unit eq BITS) {
                $binding_matrix =
                    $converter->from_frequencies_to_bits($binding_matrix);
            }

            if ($unit eq WEIGHTS) {
                $binding_matrix =
                    $converter->from_frequencies_to_weights($binding_matrix);
            }
        }
        catch {
            Catalyst::Exception->throw(
                'Not possible to get the binding matrix with '
                    . $unit
                    . '. Please try a different unit');
        };
    }

    return $binding_matrix->summary_as_hash();
}

with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;
