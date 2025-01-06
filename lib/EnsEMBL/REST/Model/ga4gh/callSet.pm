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

package EnsEMBL::REST::Model::ga4gh::callSet;

use Moose;
extends 'Catalyst::Model';


use Scalar::Util qw/weaken/;
use Bio::EnsEMBL::Variation::DBSQL::VCFCollectionAdaptor;
use EnsEMBL::REST::Model::ga4gh::ga4gh_utils;


with 'Catalyst::Component::InstancePerContext';

has 'context' => (is => 'ro', weak_ref => 1);


sub build_per_context_instance {
  my ($self, $c, @args) = @_;

  weaken($c);
  return $self->new({ context => $c, %$self, @args });
}


=head2 fetch_callSets

  POST request entry point

  ga4gh/callsets/search -d 

{ "variantSetId": 1,
 "name": '' ,
 "pageToken":  null,
 "pageSize": 10
}

=cut

sub fetch_callSets {

  my ($self, $data ) = @_;

  ## handle zero or negative page sizes   
  return ({ callSets      => [],
            nextPageToken => $data->{pageToken}})  if $data->{pageSize} < 1;


  my ($callsets, $nextPageToken ) = $self->fetch_batch($data);

  return undef unless defined $callsets;

  return ( { callSets  => $callsets, 
             nextPageToken => $nextPageToken }); 

}

=head2 fetch_batch

Read config, apply filtering and format records
Handle paging and return nextPageToken if required

=cut

## switched sample list look-up to VCF file rather than config - will be slower

sub fetch_batch{

  my $self = shift;
  my $data = shift;

  ## the position in the callset array to start from is either the pageToken or 0 if none supplied 
  $data->{pageToken} = 0  if (! defined $data->{pageToken} || $data->{pageToken} eq "");

  my @callsets;
  my $nextPageToken; ## save position of next callset to start with
  my $count_ind = 0; ## for batch size & paging

  my $vcf_collection = $self->context->model('ga4gh::ga4gh_utils')->fetch_VCFcollection_by_id($data->{variantSetId});

  ## non -documented behaviour in compliance suite
  ## return 404 if searching within non-existant set.
  ## also triggers GET 404
  return undef unless defined $vcf_collection; 

  $vcf_collection->use_db(0);

  ## extract callSets
  my $samples = $vcf_collection->get_all_Samples(); ## returned sorted

  ## return empty array if non available
  return (\@callsets, $nextPageToken) unless defined $samples;

  ## loop over callSets
  for (my $n = $data->{pageToken}; $n < scalar(@{$samples}); $n++) {  

    ## stop if there are enough saved for the required batch size
    last if defined  $nextPageToken ;

    my $sample_name = $samples->[$n]->name();
    my $sample_id   = $data->{variantSetId} . ":" . $sample_name;

    ## filter by name if required
    next if defined $data->{name} && $data->{name} =~/\w+/ && $sample_name !~ /$data->{name}/; 

    ## filter by id from GET request
    next if defined $data->{req_callset} && $data->{req_callset} =~ /\w+/ && $sample_id !~ /$data->{req_callset}/;
 

    ## for POST: if requested batch size reached set new page token
    $count_ind++;
    $nextPageToken = $n + 1  if (defined $data->{pageSize} && $count_ind == $data->{pageSize} &&
                                 $n +1 < scalar(@{$samples}) ); ## is there anything left?

    ## save info
    my $callset;
    $callset->{sampleId}       = $sample_name;
    $callset->{id}             = $sample_id;
    $callset->{name}           = $sample_name;
    $callset->{variantSetIds}  = [$vcf_collection->id()]; 
    $callset->{info}           = {"assembly_version" => [ $vcf_collection->assembly() ],
                                  "variantSetName"   => [ $vcf_collection->source_name()] };
    $callset->{created}        = $vcf_collection->created();
    $callset->{updated}        = $vcf_collection->updated();
    push @callsets, $callset;

  }

  return (\@callsets, $nextPageToken);
}


=head2 getCallSet

  GET entry point - get a CallSet by ID.
  ga4gh/callset/{id}

=cut

sub get_callSet{

  my ($self, $id ) = @_; 

  my $c = $self->context();

  my ( $variantSetId, $callSetName) = split /\:/, $id;
  my $data = { req_callset => $callSetName,
               variantSetId => $variantSetId
             };

  ## extract required call set 
  my ($callSets, $newPageToken ) = $self->fetch_batch($data);

  return undef unless defined $callSets;
 
  return $callSets->[0];

}

sub sort_num{
  $a<=>$b;
}
1;
