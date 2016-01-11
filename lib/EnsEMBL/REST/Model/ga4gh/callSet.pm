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

package EnsEMBL::REST::Model::ga4gh::callSet;

use Moose;
extends 'Catalyst::Model';
use Data::Dumper;
use Scalar::Util qw/weaken/;
use Bio::EnsEMBL::Variation::DBSQL::VCFCollectionAdaptor;

with 'Catalyst::Component::InstancePerContext';

has 'context' => (is => 'ro');


sub build_per_context_instance {
  my ($self, $c, @args) = @_;

  weaken($c);
  return $self->new({ context => $c, %$self, @args });
}

sub fetch_ga_callSet {

  my ($self, $data ) = @_;

#  print Dumper $data;

  ## format set ids if filtering by set required
  if(defined $data->{variantSetIds}->[0]){

    my %req_variantset;
    foreach my $set ( @{$data->{variantSetIds}} ){
      $req_variantset{$set} = 1; 
    }
    $data->{req_variantsets} = \%req_variantset;
  } 

  ## extract required sets
  return $self->fetch_callSets($data);

}


sub fetch_callSets{

  my $self = shift;
  my $data = shift;

  ## ind_id to start taken from page token - start from 0 if none supplied [!!put ids back]
  $data->{pageToken} = 0  if (! defined $data->{pageToken} || $data->{pageToken} eq "");
  my $next_ind_id   =  $data->{pageToken} ;

  my @callsets;
  my $n = 1;
  my $newPageToken; ## save id of next individual to start with


  $Bio::EnsEMBL::Variation::DBSQL::VCFCollectionAdaptor::CONFIG_FILE = $self->{ga_config};
  my $vca = Bio::EnsEMBL::Variation::DBSQL::VCFCollectionAdaptor->new();

  my $count_ind = 0;## for paging [!!put ids back]
  foreach my $dataSet ( @{$vca->fetch_all} ){

    ## loop over variantSets
    foreach my $varSetId( sort(keys %{$dataSet->{sets}}) ){
      ## limit by data set if required
      next if defined  $data->{req_variantsets} &&  ! defined $data->{req_variantsets}->{$varSetId}; 
    }

    ## loop over callSets
    $dataSet->{sample_populations} = $dataSet->{_raw_populations};
    foreach my $callset_id( sort( keys %{$dataSet->{sample_populations}} ) ){

      next if defined $data->{name} && $callset_id !~ /$data->{name}/; 
     
      last if defined  $newPageToken ;
 
      ## limit by variant set if required
      next if defined $data->{req_variantsets} && ! defined $data->{req_variantsets}->{ $dataSet->{sample_populations}->{$callset_id}->[0] } ;
 
      ## paging
      $count_ind++;
      ## skip ind already reported
      next if $count_ind <$next_ind_id;
      $newPageToken = $count_ind + 1  if (defined  $data->{pageSize}  &&  $data->{pageSize} =~/\w+/ && $n == $data->{pageSize});

      
      ## save info
      my $callset;
      $callset->{sampleId}       = $callset_id;
      $callset->{id}             = $callset_id;
      $callset->{name}           = $callset_id;
      $callset->{variantSetIds}  = [$dataSet->{sample_populations}->{$callset_id}->[0]]; 
      $callset->{info}           = {"assembly_version" => [ $dataSet->assembly]};
      $callset->{created}        = $dataSet->created();
      $callset->{updated}        = $dataSet->updated();

      push @callsets, $callset;
      $n++;

    }
  }

 
  my $return_data = { "callSets"  => \@callsets};
  $return_data->{"pageToken"} = $newPageToken if defined $newPageToken ;

  return $return_data; 
  
}



1;
