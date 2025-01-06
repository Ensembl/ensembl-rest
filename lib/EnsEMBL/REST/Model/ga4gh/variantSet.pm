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

package EnsEMBL::REST::Model::ga4gh::variantSet;

use Moose;
extends 'Catalyst::Model';

use Scalar::Util qw/weaken/;
use Bio::EnsEMBL::Variation::DBSQL::VCFCollectionAdaptor;
use Bio::EnsEMBL::IO::Parser::VCF4Tabix;
use EnsEMBL::REST::Model::ga4gh::ga4gh_utils;

use Digest::MD5 qw(md5_hex);

with 'Catalyst::Component::InstancePerContext';

has 'context' => (is => 'ro', weak_ref => 1);


sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  weaken($c);
  return $self->new({ context => $c, %$self, @args });

}

=head fetch_variantSets

  POST request entry point

=cut

sub fetch_variantSets {

  my ($self, $data ) = @_;

 return ({ "variantSets"   => [],
           "nextPageToken" => $data->{pageToken}
          }) if $data->{pageSize} < 1;


  ## extract required variant sets
  my ($variantSets, $newPageToken ) = $self->fetch_sets($data);

  return ( { variantSets   => $variantSets,
             nextPageToken => $newPageToken});

}

=head fetch_sets

Read config, apply filtering and format records

=cut

sub fetch_sets{

  my $self = shift;
  my $data = shift;


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

    ## set next token and stop storing if page size reached if pageSize defined (ie POST request)
    if (defined $data->{pageSize} &&  $n == $data->{pageSize}){
      $newPageToken = $varset_id;
      last;
    }


    ## extract required info
    my $variantSet;

    ## get info descriptions from one of the VCF files    
    my $meta = $self->get_info($vc_ob->{$varset_id});

    ## store
    $variantSet->{id}             = $varset_id;
    $variantSet->{datasetId}      = $datasetId; 
    $variantSet->{metadata}       = \@{$meta};
    $variantSet->{referenceSetId} = $vc_ob->{$varset_id}->assembly();
    $variantSet->{name}           = $vc_ob->{$varset_id}->source_name() . ":" . $vc_ob->{$varset_id}->assembly();
    push @varsets, $variantSet;
    $n++;
   
  }
  
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

  ## default current set for variant annotations
  return $self->getEnsemblSet($id) if $id =~ /Ensembl/;

  ## extract required variant set 
  my ($variantSets, $newPageToken ) = $self->fetch_sets( {req_variantset => $id} );

  return undef unless scalar(@$variantSets) > 0;

  return $variantSets->[0];
}

sub getEnsemblSet{

  my $self = shift;
  my $id   = shift;

  my $species = 'homo_sapiens';
  my $core_ad = $self->context->model('Registry')->get_DBAdaptor($species, 'Core'  );

  ## extract required meta data from core db
  my $cmeta_ext_sth = $core_ad->dbc->db_handle->prepare(qq[ select meta_key, meta_value from meta]);
  $cmeta_ext_sth->execute();
  my $core_meta = $cmeta_ext_sth->fetchall_arrayref();

  my %cmeta;
  foreach my $l(@{$core_meta}){
    $cmeta{$l->[0]} = $l->[1];
  }

  my $current_set = 'Ensembl.' . $cmeta{schema_version} . '.'. $cmeta{"assembly.default"};
  return undef unless $id eq $current_set;

  return  { id             => $current_set,
            datasetId      => 'Ensembl',
            metadata       => [],
            referenceSetId => $cmeta{"assembly.default"},
            name           => $current_set
          };

}
sub sort_num{
  $a<=>$b;
}

1;
