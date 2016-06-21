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

package EnsEMBL::REST::Model::ga4gh::featureSets;

use Moose;
extends 'Catalyst::Model';
use Catalyst::Exception;
use Data::Dumper;

use Scalar::Util qw/weaken/;

use EnsEMBL::REST::Model::ga4gh::ga4gh_utils;
with 'Catalyst::Component::InstancePerContext';

has 'context' => (is => 'ro');

## referenceSetId is currently the metadata assembly.name 

sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  weaken($c);
  return $self->new({ context => $c, %$self, @args });
}

## POST entry point
sub searchFeatureSets {
  
  my $self   = shift;
  my $data   = shift;


#  if( $data->{datasetId} eq  ){
  
    ## hack to take from compliance files
#    my $featureSet =  $self->fetch_compliance_set(  $data->{datasetId} );
#    return { featureSets   => [$featureSet],
#             nextPageToken => undef  };
#  }
  if ($data->{datasetId} eq 'Ensembl' ){
    my $featureSets =  $self->fetch_database_set($data);
    return { featureSets   => [$featureSets],
             nextPageToken => undef
           }; 
  }
  else{
    return [];
  }
}

## limited to current ensembl release initially
## set id is genebuild id (or refseq release id?)
sub fetch_database_set {

  my $self   = shift;
  my $data   = shift;

  my $c = $self->context();

  my $species = 'homo_sapiens';
  my $core_ad = $c->model('Registry')->get_DBAdaptor($species, 'Core'  );

  my $featureSet;

  ## extract required meta data from core db
  my $cmeta_ext_sth = $core_ad->dbc->db_handle->prepare(qq[ select meta_key, meta_value from meta]);
  $cmeta_ext_sth->execute();
  my $core_meta = $cmeta_ext_sth->fetchall_arrayref();

  my %cmeta;
  foreach my $l(@{$core_meta}){
    $cmeta{$l->[0]} = $l->[1];
  }
  ## derive dataset for this ensembl release
  $featureSet->{datasetId} = "Ensembl";

  ## derive featureset id for this genebuild
  $featureSet->{id} = "Ensembl."  . $cmeta{"schema_version"};

  ## apply filter for post search
  return  [] if defined $data->{datasetId} && $data->{datasetId} ne $featureSet->{datasetId};

  ## apply filter for get search
  return  [] if defined $data->{id} && $data->{id} ne $featureSet->{id};



  $featureSet->{name}           = "Ensembl_genebuild_" . $cmeta{"genebuild.id"};
  $featureSet->{referenceSetId} = $cmeta{"assembly.name"};  
  $featureSet->{sourceURI} = '';
 

  foreach my $c_attrib (qw[ assembly.name assembly.accession gencode.version assembly.long_name genebuild.last_geneset_update genebuild.havana_datafreeze_date]){
     $featureSet->{info}->{$c_attrib} = [$cmeta{$c_attrib}] if defined  $cmeta{$c_attrib};
  }

  return $featureSet;

}

## GET entry point
sub getFeatureSet{

  my ($self, $id ) = @_; 

  ## hack for compliance suite
#  if ($id =~/compliance/){
#    return $self->fetch_compliance_set($id);
#  }
#  else{
    my $data;
    $data->{id} = $id;
    return $self->fetch_database_set($data);
#  }
}

## read json config for available GFF
sub fetch_compliance_set{

}


1;
