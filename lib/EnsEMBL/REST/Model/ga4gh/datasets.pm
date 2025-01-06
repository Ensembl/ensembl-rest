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

package EnsEMBL::REST::Model::ga4gh::datasets;

use Moose;
extends 'Catalyst::Model';

use Bio::EnsEMBL::IO::Parser::VCF4Tabix;
use Bio::EnsEMBL::Variation::DBSQL::VCFCollectionAdaptor;
use EnsEMBL::REST::Model::ga4gh::ga4gh_utils;

use Digest::MD5 qw(md5_hex);
use Catalyst::Exception;
use Scalar::Util qw/weaken/;

with 'Catalyst::Component::InstancePerContext';

has 'context' => (is => 'ro',  weak_ref => 1);
use EnsEMBL::REST::Model::ga4gh::ga4gh_utils;

sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  weaken($c);
  return $self->new({ context => $c, %$self, @args });
}

sub fetch_datasets{
  my ($self, $data ) = @_;

  my @datasets;

  ## paging
  my $count = 0;
  my $nextPageToken;      
  my $start = 1;
  $start = 0 if defined $data->{pageToken} && $data->{pageToken} ne ''; 

  # get hash of md5 => description for dataasets
  my $datasets = $self->context->model('ga4gh::ga4gh_utils')->fetch_all_Datasets();

  foreach my $id( sort keys %{$datasets}){

    $start = 1 if (defined $data->{pageToken} &&  $data->{pageToken} eq $id);

    ## skip datasets returned in last batch
    next if $start == 0 ;

    ## store start of next batch before exiting this one
    if ($count == $data->{pageSize}){
      $nextPageToken = $id;
      last; 
    }

     ## save and increment
     my $dataset = { id => $id, 
                     name => $datasets->{$id}->{name},
                     description => $datasets->{$id}->{desc} 
                   };
     push @datasets, $dataset;
     $count++;
  }
  Catalyst::Exception->throw(" No datasets are available")
     unless scalar(@datasets) >0 ;

  return { datasets => \@datasets, nextPageToken => $nextPageToken};

}



sub getDataset{

  my ($self, $id ) = @_; 

  my $collections = $self->context->model('ga4gh::ga4gh_utils')->fetch_all_Datasets();

  return undef unless defined $collections->{$id};

  return {id => $id, name => $collections->{$id}->{name}, description => $collections->{$id}->{desc} }; 

}


with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;
 
