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

package EnsEMBL::REST::Controller::Map;
use Moose;
use namespace::autoclean;
use Try::Tiny;
require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

BEGIN { extends 'Catalyst::Controller::REST'; }

sub translation_GET {  }

sub translation: Chained('/') Args(2) PathPart('map/translation') ActionClass('REST') {
  my ($self, $c, $id, $region) = @_;
  $c->stash()->{id} = $id;
  $c->request()->param('object_type', 'translation');
  my $translation = $c->model('Lookup')->find_object_by_stable_id($id);
  my $ref = ref($translation);
  $c->go('ReturnError', 'custom', ["Expected a Bio::EnsEMBL::Translation object but got a $ref object back. Check your ID"]) if $ref ne 'Bio::EnsEMBL::Translation';
  my $transcript = $translation->transcript();
  my $mappings = $self->_map_transcript_coords($c, $transcript, $region, 'pep2genomic');
  $self->status_ok( $c, entity => { mappings => $mappings } );
}

sub cdna_GET {  }

sub cdna: Chained('/') Args(2) PathPart('map/cdna') ActionClass('REST') {
  my ($self, $c, $id, $region) = @_;
  $c->stash()->{id} = $id;
  $c->request()->param('object_type', 'transcript');
  my $transcript = $c->model('Lookup')->find_object_by_stable_id($id);
  my $ref = ref($transcript);
  $c->go('ReturnError', 'custom', ["Expected a Bio::EnsEMBL::Transcript object but got a $ref object back. Check your ID"]) if $ref ne 'Bio::EnsEMBL::Transcript';
  
  #optional parameter to include original region coordinate mappings, cdna coordinates in this case
  my $include_original_region = $c->request()->param('include_original_region') || 0;
  my $mappings = $self->_map_transcript_coords($c, $transcript, $region, 'cdna2genomic', 'cdna', $include_original_region);
  
  $self->status_ok( $c, entity => { mappings => $mappings } );
}

sub cds_GET {  }

sub cds: Chained('/') Args(2) PathPart('map/cds') ActionClass('REST') {
  my ($self, $c, $id, $region) = @_;
  $c->stash()->{id} = $id;
  $c->request()->param('object_type', 'transcript');
  my $transcript = $c->model('Lookup')->find_object_by_stable_id($id);
  my $ref = ref($transcript);
  $c->go('ReturnError', 'custom', ["Expected a Bio::EnsEMBL::Transcript object but got a $ref object back. Check your ID"]) if $ref ne 'Bio::EnsEMBL::Transcript';
  
  #optional parameter to include original region coordinate mappings, cds coordinates in this case  
  my $include_original_region = $c->request()->param('include_original_region') || 0;
  my $mappings = $self->_map_transcript_coords($c, $transcript, $region, 'cds2genomic','cds', $include_original_region);

  $self->status_ok( $c, entity => { mappings => $mappings } );
}

sub _map_transcript_coords {
  my ($self, $c, $transcript, $region, $method,$type, $include_original_region) = @_;
  my ($start, $end) = $region =~ /^(\d+) (?:\.{2} | -) (\d+)$/xms;
  
  if(!$start) {
    $c->go('ReturnError', 'custom', ["Region did not correctly parse. Please check documentation"]);
  }
  $start ||= $end;
  my $mapped = [$transcript->get_TranscriptMapper()->$method($start, $end, $include_original_region)];
  return $self->map_mappings($c, $mapped, $transcript, $type, $include_original_region);
}

## Create a slice object based on the location string provided
## do not proceed if anything went wrong on the way
sub mapped_region_data : Chained("/") PathPart("map") ActionClass('REST') {
  my ( $self, $c, $species, $old_assembly, $region, $target_assembly) = @_;
  $c->stash->{species} = $species;
  try {
    $c->stash->{slice_adaptor} = $c->model('Registry')->get_adaptor( $species, 'Core', 'Slice' );
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  $c->log->info($region);
  try {
    my ($old_sr_name, $old_start, $old_end, $old_strand) = $c->model('Lookup')->decode_region($region);
    my $coord_system = $c->request()->param('coord_system') || 'chromosome';
    my $old_slice = $c->stash->{slice_adaptor}->fetch_by_region($coord_system, $old_sr_name, $old_start, $old_end, $old_strand, $old_assembly);
    if (!defined $old_slice) {
      $c->go('ReturnError', 'custom', [qq{'No slice found for $old_sr_name on coord_system $coord_system and assembly $old_assembly'}]);
    }
    $c->stash->{old_slice} = $old_slice;
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  $c->stash->{target_assembly} = $target_assembly;
}

sub mapped_region_data_GET {
  my ( $self, $c ) = @_;
  $c->forward('map_data');
  $self->status_ok( $c, entity => { mappings => $c->stash->{mapped_data} } );
}

sub map_data : Private {
  my ( $self, $c ) = @_;
  my $old_slice   = $c->stash->{old_slice};
  my $old_cs_name = $old_slice->coord_system_name();
  my $old_sr_name = $old_slice->seq_region_name();
  my $old_start   = $old_slice->start();
  my $old_end     = $old_slice->end();
  my $old_strand  = $old_slice->strand()*1;
  my $old_version = $old_slice->coord_system()->version();

  my $target_coord_system = $c->request()->param('target_coord_system') || 'chromosome';

  my @decoded_segments;
  try {
    my $projection = $old_slice->project($target_coord_system, $c->stash->{target_assembly});

    foreach my $segment ( @{$projection} ) {
      my $mapped_slice = $segment->to_Slice;
      my $mapped_data = {
        original => {
          coord_system => $old_cs_name,
          assembly => $old_version,
          seq_region_name => $old_sr_name,
          start => ($old_start + $segment->from_start() - 1) * 1,
          end => ($old_start + $segment->from_end() - 1) * 1,
          strand => $old_strand,
        },
        mapped => {
          coord_system => $mapped_slice->coord_system->name,
          assembly => $mapped_slice->coord_system->version,
          seq_region_name => $mapped_slice->seq_region_name(),
          start => $mapped_slice->start() * 1,
          end => $mapped_slice->end() * 1,
          strand => $mapped_slice->strand(),
        },
      };
      push(@decoded_segments, $mapped_data);
    }
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  
  $c->stash(mapped_data => \@decoded_segments);
}

sub map_mappings {
  my ($self, $c, $mapped, $transcript,$type,$include_original_region) = @_;
  
  my @r;
  my $seq_region_name = $transcript->seq_region_name();
  my $coord_system = $transcript->coord_system_name();
  my $assembly_name = $transcript->slice->coord_system->version();
  
  foreach my $m (@{$mapped}) {
    if($include_original_region){
      my $paired_mapping = map_mappings_include_original_region($m, $seq_region_name, $coord_system, $assembly_name, $type);
      push(@r, $paired_mapping);
    }else{
      my $m_mapped_mappings = _get_mapped_coords($m, $seq_region_name, $coord_system, $assembly_name);
      push(@r,$m_mapped_mappings);
    }
   	
  }
  return \@r;
  
}

sub map_mappings_include_original_region{
	
  my ($m, $seq_region_name, $coord_system, $assembly_name, $type) = @_;
	
  my $m_mapped = $m->{'mapped'};
  my $m_ori = $m->{'original'};
  	
  my $m_mapped_mappings = {};
  my $m_ori_mappings = {};
	
  if($m->{'mapped'}){
    $m_mapped_mappings = _get_mapped_coords($m->{'mapped'}, $seq_region_name, $coord_system, $assembly_name);
  }
	
  #seq_region_name and assembly_name is not applicable for the original region and type (eg: cds or cdna) is assigned to the coordinate_system
  if($m->{'original'}){
  	$coord_system = $type;
	$m_ori_mappings = _get_mapped_coords($m->{'original'}, undef, $coord_system, undef);
   }
	
  my $paired_mappings = { 'original' => $m_ori_mappings, 'mapped' => $m_mapped_mappings };
  return $paired_mappings;

}


sub _get_mapped_coords {
  my ($m, $seq_region_name, $coord_system, $assembly_name) = @_;
  my $strand = 0;
  my $gap = 0;
  if($m->isa('Bio::EnsEMBL::Mapper::Gap')) {
    $gap = 1;
  }
  else {
    $strand = $m->strand();
  }
  my $mapped_coords =  {
    start => $m->start() * 1,
    end => $m->end() * 1,
    strand => $strand,
    rank => $m->rank(),
    gap => $gap,
    };
    
  $mapped_coords->{'seq_region_name'} = $seq_region_name if defined($seq_region_name);
  $mapped_coords->{'coord_system'} = $coord_system if defined($coord_system);
  $mapped_coords->{'assembly_name'} = $assembly_name if defined($assembly_name);
  return $mapped_coords; 
}


__PACKAGE__->meta->make_immutable;

1;
