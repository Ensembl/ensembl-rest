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

package EnsEMBL::REST::Model::ga4gh::referenceSets;


use Moose;
extends 'Catalyst::Model';
use Catalyst::Exception;
use Scalar::Util qw/weaken/;
use Try::Tiny;

use EnsEMBL::REST::Model::ga4gh::ga4gh_utils;

with 'Catalyst::Component::InstancePerContext';

has 'context' => (is => 'ro', weak_ref => 1);
use EnsEMBL::REST::Model::ga4gh::ga4gh_utils;


sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  weaken($c);
  return $self->new({ context => $c, %$self, @args });
}

## POST entry point
sub searchReferenceSet {
  
  my $self = shift;
  my $data = shift; 

  return ({ referenceSets => [],
            nextPageToken => $data->{pageToken} }) if $data->{pageSize} < 1; ;


  my ( $referenceSets, $nextPageToken)  =  $self->fetchData( $data );

  return ({ referenceSets => $referenceSets,
            nextPageToken => $nextPageToken });

}

## GET entry point
sub getReferenceSet {

  my $self = shift;
  my $id   = shift;

  my ($referenceSets, $nextPageToken) =  $self->fetchData( { id => $id} );
 
  return undef unless defined $referenceSets &&  scalar($referenceSets) >0 ;

  return $referenceSets->[0];

}


## send both post & get here as few sets to check
sub fetchData{

  my $self  = shift;
  my $data  = shift;


  ## read config
  my $config;
  try {
    $config = $self->context->model('ga4gh::ga4gh_utils')->read_sequence_config();
  }
  catch{
    Catalyst::Exception->throw(" Problem reading ga_references config " );
  };

  my $nextPageToken;

  ## return empty array if no sets available by this id (behaviour not fully specified)
  return ( [], $nextPageToken) unless defined $config ;

  my $referenceSets =  $config->{referenceSets};

  my @referenceSets;

  $data->{pageToken} = 0 unless defined $data->{pageToken} && $data->{pageToken} ne ''; 

  my $count = 0;
  foreach( my $n = $data->{pageToken}; $n <  scalar @{$referenceSets}; $n++ ) {

    my $refset_hash = $referenceSets->[$n];

    ## filter if an attrib supplied
    next if defined $data->{id}          &&  $data->{id}          ne '' 
                                         &&  $data->{id}          ne $refset_hash->{id}; ##  GET

    next if defined $data->{md5checksum} &&  $data->{md5checksum} ne ''
                                         &&  $data->{md5checksum} ne $refset_hash->{md5};

    my $filter_accession;
    if (defined $data->{accession}){
      $filter_accession = 1 if $data->{accession}   ne '';
      foreach my $ac(@{$refset_hash->{sourceAccessions}}){
        undef $filter_accession if $ac eq $data->{accession};
      }
    } 
    next if defined $filter_accession ;

    next if defined $data->{assemblyId}  &&  $data->{assemblyId}  ne ''
                                         &&  $data->{assemblyId}  ne $refset_hash->{id};


    ## paging - only return requested page size for POST requests
    if (defined $data->{pageSize} && $count == $data->{pageSize}){
      $nextPageToken = $n;
      last;
    }

    ## format
    my $referenceSet;
    $referenceSet->{id}           = $refset_hash->{id};
    $referenceSet->{name}         = $refset_hash->{name};
    $referenceSet->{md5checksum}  = $refset_hash->{md5};
    $referenceSet->{ncbiTaxonId}  = $refset_hash->{ncbiTaxonId};
    $referenceSet->{description}  = "Homo sapiens " . $refset_hash->{id};
    $referenceSet->{assemblyId}   = $refset_hash->{id};
    $referenceSet->{sourceURI}    = $refset_hash->{sourceURI}; 
    $referenceSet->{sourceAccessions} = $refset_hash->{sourceAccessions} ;
    $referenceSet->{isDerived}    = $refset_hash->{isDerived};

    push @referenceSets, $referenceSet;

    $count++;
  
  }

  return ( \@referenceSets, $nextPageToken );

}

1;
