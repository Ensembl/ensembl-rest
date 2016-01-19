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
use Digest::MD5 qw(md5_hex);
with 'Catalyst::Component::InstancePerContext';
use Data::Dumper;
has 'context' => (is => 'ro');


sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  return $self->new({ context => $c, %$self, @args });
}


sub fetch_VCFcollection_by_id{

  my $self         = shift;
  my $variantSetId = shift; ## may be null
  $ENV{ENSEMBL_VARIATION_VCF_ROOT_DIR} = $self->{geno_dir};

  ## read config
  $Bio::EnsEMBL::Variation::DBSQL::VCFCollectionAdaptor::CONFIG_FILE = $self->{ga_config};
  my $vca =  Bio::EnsEMBL::Variation::DBSQL::VCFCollectionAdaptor->new();

  my $vcf_coll = $vca->fetch_by_id($variantSetId);

  return $vcf_coll;

}

sub fetch_all_VariationSets{

  my $self   = shift;

  $ENV{ENSEMBL_VARIATION_VCF_ROOT_DIR} = $self->{geno_dir};

  $Bio::EnsEMBL::Variation::DBSQL::VCFCollectionAdaptor::CONFIG_FILE = $self->{ga_config};
  my $vca =  Bio::EnsEMBL::Variation::DBSQL::VCFCollectionAdaptor->new();

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
    $self->context()->go( 'ReturnError', 'custom', ["ERROR: Could not read from config file $self->{ga_reference_config}"]);
  local $/ = undef;
  my $json_string = <IN>;
  close IN;

  my $config = JSON->new->decode($json_string) ||
    $self->context()->go( 'ReturnError', 'custom', ["ERROR: Failed to parse config file $self->{ga_reference_config}"]);

  $self->context()->go( 'ReturnError', 'custom', [ " No data available " ] )
    unless $config->{referenceSets} && scalar @{$config->{referenceSets}};

  ## add fasta file location for compliance suite
  $config->{fasta_dir} = $self->{fasta_dir};

  return $config;
}


sub fetch_all_Datasets{

  my $self = shift;

  $Bio::EnsEMBL::Variation::DBSQL::VCFCollectionAdaptor::CONFIG_FILE = $self->{ga_config};
  my $vca = Bio::EnsEMBL::Variation::DBSQL::VCFCollectionAdaptor->new();

  my %collections;
  foreach my $collection(@{$vca->fetch_all} ) { 
    ## calculate id from source name
    my $ga_id = md5_hex($collection->source_name());
    $collections{$ga_id} = $collection->source_name();
  }

  return \%collections;
}


1;
