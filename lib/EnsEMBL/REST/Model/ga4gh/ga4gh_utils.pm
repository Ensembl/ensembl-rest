=head1 LICENSE

Copyright [2016] EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

# shared configuration etc
package EnsEMBL::REST::Model::ga4gh::ga4gh_utils;


use Moose;
extends 'Catalyst::Model';

use Bio::EnsEMBL::IO::Parser::VCF4Tabix;
use Bio::EnsEMBL::Variation::DBSQL::VCFCollectionAdaptor;
use Bio::EnsEMBL::Utils::IO qw/gz_slurp/;

use Digest::MD5 qw(md5_hex);
use Scalar::Util qw/weaken/;
with 'Catalyst::Component::InstancePerContext';

has 'context' => (is => 'ro',  weak_ref => 1);


sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  weaken($c);
  return $self->new({ context => $c, %$self, @args });
}


sub fetch_VCFcollection_by_id{

  my $self         = shift;
  my $variantSetId = shift; ## may be null

  $ENV{ENSEMBL_VARIATION_VCF_ROOT_DIR} = $self->{geno_dir};

  ## read config
  my $vca =  Bio::EnsEMBL::Variation::DBSQL::VCFCollectionAdaptor->new( -config => $self->{ga_config});

  my $vcf_coll = $vca->fetch_by_id($variantSetId);

  return $vcf_coll;

}

sub fetch_all_VariationSets{

  my $self   = shift;

  $ENV{ENSEMBL_VARIATION_VCF_ROOT_DIR} = $self->{geno_dir};

  my $vca =  Bio::EnsEMBL::Variation::DBSQL::VCFCollectionAdaptor->new( -config => $self->{ga_config});

  my $vcf_coll = $vca->fetch_all();

  ## extract ids to sort for paging

  my %vc_ob;
  foreach my $vcf_collection( @{$vca->fetch_all} ) {
    $vc_ob{$vcf_collection->id()} = $vcf_collection;
  }
  return \%vc_ob;
}



sub read_sequence_config{

  my $self = shift;

  my $json_string = gz_slurp($self->{ga_reference_config});

  my $config = JSON->new->decode($json_string) ||
    Catalyst::Exception->throw(" ERROR: Failed to parse config file $self->{ga_reference_config}");

  ## add fasta file location for compliance test data
  $config->{fasta_dir} = $self->{fasta_dir} if exists $config->{referenceSets};

  return $config;
}


sub fetch_all_Datasets{

  my $self = shift;
 
  my $vca = Bio::EnsEMBL::Variation::DBSQL::VCFCollectionAdaptor->new( -config => $self->{ga_config} );

  my %collections;
  ## save all genotype sets
  foreach my $collection(@{$vca->fetch_all} ) { 
    ## calculate id from source name
    my $ga_id = md5_hex($collection->source_name());
    $collections{$ga_id}{name}  = $collection->source_name();
    $collections{$ga_id}{desc}  = $collection->source_name() . " genotypes";
  }

  ## add default ensembl set for gene annotation
  $collections{'Ensembl'}{name}  = 'Ensembl';
  $collections{'Ensembl'}{desc}  = 'Ensembl annotation';


  return \%collections;
}

## extract specific reference sequence from config data
sub get_sequence{

  my $self = shift;
  my $id   = shift;

  my $config = $self->read_sequence_config();
  return undef unless exists $config->{referenceSets};

  foreach my $referenceSet (@{$config->{referenceSets}}){

    foreach my $seq (@{$referenceSet->{sequences}}){
      $seq->{fastafile} = $config->{fasta_dir} ."/". $seq->{localFile} if defined $seq->{localFile};
      $seq->{assembly}  = $referenceSet->{id};
      $seq->{sourceURI} = $referenceSet->{sourceUri};
      return $seq if $seq->{md5} eq $id;
    } 
  }
  return undef;
}

## extract metadata from core & variation dbs
## to use in features & var ann endpoints
## create default set names for releases
sub get_meta{

  my $self   = shift;

  my $c = $self->context();

  my $species = 'homo_sapiens';
  my $core_ad = $c->model('Registry')->get_DBAdaptor($species, 'Core'  );
  my $var_ad  = $c->model('Registry')->get_DBAdaptor($species, 'variation');

  my %meta_data;

  ## extract required meta data from core db
  my $cmeta_ext_sth = $core_ad->dbc->db_handle->prepare(qq[ select meta_key, meta_value from meta]);
  $cmeta_ext_sth->execute();
  my $core_meta = $cmeta_ext_sth->fetchall_arrayref();

  foreach my $l(@{$core_meta}){
    next unless $l->[0] =~/assembly.name|assembly.accession|gencode.version|assembly.long_name|genebuild.last_geneset_update/;
    $meta_data{$l->[0]} = $l->[1];
  }

  ## extract required meta data from variation database
  my $meta_ext_sth = $var_ad->dbc->db_handle->prepare(qq[ select meta_key, meta_value from meta]);
  $meta_ext_sth->execute();
  my $var_meta = $meta_ext_sth->fetchall_arrayref();

  foreach my $l(@{$var_meta}){
    $meta_data{$l->[0]} = $l->[1] if defined $l->[1];
  }

  ## default sets
  $meta_data{datasetId}              = "Ensembl";
  $meta_data{featureSetId}           = 'Ensembl.' . $meta_data{schema_version} . '.'. $meta_data{"assembly.default"}; 
  $meta_data{variantAnnotationSetId} = 'Ensembl.' . $meta_data{schema_version} . '.'. $meta_data{"assembly.default"};
  $meta_data{referenceSetId}         = $meta_data{"assembly.name"};  

  return \%meta_data;

}

sub fetch_featureSet {

  my $self   = shift;

  my $species = 'homo_sapiens';
  my $core_ad = $self->context->model('Registry')->get_DBAdaptor($species, 'Core'  );

  my $featureSet;

  ## extract required meta data from core db
  my $cmeta_ext_sth = $core_ad->dbc->db_handle->prepare(qq[ select meta_key, meta_value from meta]);
  $cmeta_ext_sth->execute();
  my $core_meta = $cmeta_ext_sth->fetchall_arrayref();

  my %cmeta;
  foreach my $l(@{$core_meta}){
    $cmeta{$l->[0]} = $l->[1];
  }

  ## default set names/ids
  $featureSet->{datasetId}      = "Ensembl";
  $featureSet->{id}             = "Ensembl."  . $cmeta{"schema_version"} ."." . $cmeta{"assembly.default"};
  $featureSet->{name}           = "Ensembl_genebuild_" . $cmeta{"genebuild.id"};
  $featureSet->{referenceSetId} = $cmeta{"assembly.name"};  

  $featureSet->{sourceURI} = '';

  foreach my $c_attrib (qw[ assembly.name assembly.accession gencode.version assembly.long_name genebuild.last_geneset_update genebuild.havana_datafreeze_date]){
     $featureSet->{info}->{$c_attrib} = [$cmeta{$c_attrib}] if defined  $cmeta{$c_attrib};
  }

  return $featureSet;

}


1;
