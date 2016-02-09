=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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
use Bio::EnsEMBL::Utils::IO qw/work_with_file/;

use Digest::MD5 qw(md5_hex);
use Scalar::Util qw/weaken/;
with 'Catalyst::Component::InstancePerContext';
use Data::Dumper;
has 'context' => (is => 'ro');


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
  open IN, $self->{ga_reference_config} ||
    Catalyst::Exception->throw(" ERROR: Could not read from config file $self->{ga_reference_config}");

  local $/ = undef;
  my $json_string = <IN>;
  close IN;

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
  foreach my $collection(@{$vca->fetch_all} ) { 
    ## calculate id from source name
    my $ga_id = md5_hex($collection->source_name());
    $collections{$ga_id} = $collection->source_name();
  }

  return \%collections;
}


1;
