=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::REST::Model::ga4gh::variantSet;

use Moose;
extends 'Catalyst::Model';
use Data::Dumper;
use Bio::EnsEMBL::Variation::DBSQL::VCFCollectionAdaptor;
use Bio::EnsEMBL::IO::Parser::VCF4Tabix;
use EnsEMBL::REST::Model::ga4gh::ga4gh_utils;

use Digest::MD5 qw(md5_hex);

with 'Catalyst::Component::InstancePerContext';

has 'context' => (is => 'ro');


sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  return $self->new({ context => $c, %$self, @args });

}

=head fetch_variantSets

  POST request entry point

=cut

sub fetch_variantSets {

  my ($self, $data ) = @_;

  ## extract required variant sets
  my ($variantSets, $newPageToken ) = $self->fetch_sets($data);

  my $ret = { variantSets => $variantSets};
  $ret->{pageToken} = $newPageToken  if defined $newPageToken ;

  return $ret;
}

=head fetch_sets

Read config, apply filtering and format records

=cut

sub fetch_sets{

  my $self = shift;
  my $data = shift;

  ## varset id to start from is the page token - start from 0 if none supplied
#  my $next_set_id = 0;
#  $next_set_id    = $data->{pageToken} if ( defined $data->{pageToken} && $data->{pageToken} ne "");


  ## get hash of VariationSetId => VCF collection
  my $vc_ob = $self->context->model('ga4gh::ga4gh_utils')->fetch_all_VariationSets();

  ## create response with correct number of variantSets
  my @varsets;
  my $n = 0;
  my $newPageToken; ## save id of next variantSet to start with
  my $start = 1; 
  $start = 0 if defined $data->{pageToken} && $data->{pageToken} ne '';

  foreach my $varset_id(sort sort_num(keys %{$vc_ob} )) {

   my $datasetId = md5_hex($vc_ob->{$varset_id}->source_name());

    ## limit by variant set if required (for GET)
    next if defined  $data->{req_variantset} && $data->{req_variantset} ne '' 
      && $varset_id ne $data->{req_variantset};

    ## paging - skip if already returned
    $start = 1 if $start == 0 && $varset_id eq $data->{pageToken};
    next if $start ==0;

    ## limit by data set if required
    next if defined $data->{datasetId} && $data->{datasetId} ne ''
      &&  $datasetId ne $data->{datasetId} ; 

    ## set next token and stop storing if page size reached
    if (defined $data->{pageSize} &&  $n == $data->{pageSize}){
      $newPageToken = $varset_id if defined $data->{pageSize} && $n == $data->{pageSize};
      last;
    }


    ## extract required info
    my $variantSet;

    ## get info descriptions from one of the VCF files    
    my $meta = $self->get_info($vc_ob->{$varset_id});

    ### Most of this has been promoted to named fields now
    ## add summary of essential info for meta for the data set from the config
#    foreach my $key ( "source_url"){
#      my %meta;
#      $meta{key}   = $key;
#      $meta{value} = $vc_ob{$varset_id}->$key;
#      push @{$meta}, \%meta;
#    }

    ## store
    $variantSet->{id}             = $varset_id;
    $variantSet->{datasetId}      = $datasetId; 
    $variantSet->{metadata}       = \@{$meta};
    $variantSet->{referenceSetId} = $vc_ob->{$varset_id}->assembly();
    $variantSet->{name}           = $vc_ob->{$varset_id}->source_name();
    push @varsets, $variantSet;
    $n++;
   
  }

  ## check there is something to return
  $self->context()->go( 'ReturnError', 'custom', [ " Failed to find any variantSets for this query"]) if $n ==0;
 
  my $ret = { variantSets => \@varsets};
  $ret->{pageToken} = $newPageToken  if defined $newPageToken ;
 
  return (\@varsets, $newPageToken );
  
}

=head2 get_info

 get info descriptions from one of the VCF files   
 to report as meta data

=cut

sub get_info{

  my $self      = shift;
  my $vcf_coll  = shift;

  ## get a chromosome to read meta data (compliance set covers only few chroms) 
  my $chr = $vcf_coll->list_chromosomes()->[0];

  my $vcf_file  = $vcf_coll->filename_template();
  $vcf_file =~ s/\#\#\#CHR\#\#\#/$chr/;

  my $parser = Bio::EnsEMBL::IO::Parser::VCF4Tabix->open( $vcf_file ) || die "Failed to get parser : $!\n";

  my @meta;

  ## metadata for info & format 
  foreach my $type ("INFO", "FORMAT"){

    my $data = $parser->get_metadata_by_pragma($type);

    foreach my $d(@{$data}){
      my $out;
      $out->{key} = $type;
      foreach my $k (keys %$d){
        $out->{"\L$k"} = $d->{$k};
      }
      ##required info hash
      $out->{info} = {};

      push @meta, $out;
    }
  }
 
  return \@meta;
}




=head2 getVariantSet

  Gets a VariantSet by ID.
  GET /variantsset/{id}

=cut

sub getVariantSet{

  my ($self, $id ) = @_; 

  my $c = $self->context();

  my $data = {req_variantset => $id};

  ## extract required variant set 
  my ($variantSets, $newPageToken ) = $self->fetch_sets($data);

  ## would exit earlier if no data
  return $variantSets->[0];
}

sub sort_num{
  $a<=>$b;
}

1;
