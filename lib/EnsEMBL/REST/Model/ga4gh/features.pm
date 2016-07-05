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

package EnsEMBL::REST::Model::ga4gh::features;

use Moose;
extends 'Catalyst::Model';

use Scalar::Util qw/weaken/;
use EnsEMBL::REST::Model::ga4gh::ga4gh_utils;
with 'Catalyst::Component::InstancePerContext';

has 'context' => (is => 'ro', weak_ref => 1);


## Returning only the features required for Var Ann initially
has 'allowed_features' => ( isa => 'HashRef', is => 'ro', lazy => 1, default => sub {
  return {
    map { $_ => 1 } qw/gene transcript cds exon protein /
  };
});

sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  weaken($c);
  return $self->new({ context => $c, %$self, @args });
}



=head2 searchFeatures
      post entry point
=cut
sub searchFeatures {

  my ($self, $data ) = @_; 

  ## check input types against supported types
  $data = $self->getTypes($data);

  ##silent fail if unsupported feature requested
  return { nextPageToken => undef,
           features =>  []}  
         if ! defined $data->{required_types} || $data->{pageSize} < 1; 


  $data->{featureSet} = $self->context->model('ga4gh::ga4gh_utils')->fetch_featureSet();

  ## check any supplied featureSet
  if($data->{featureSetId} && 
     $data->{featureSetId} ne $data->{featureSet}->{id} &&
     $data->{featureSetId} ne 'Ensembl'){

     return { nextPageToken => undef,
           features =>  []};
  }

  ## Paging
  $data->{start} = $data->{pageToken}  if defined $data->{pageToken};

  return $self->searchFeaturesParent($data) if defined $data->{parentId} && $data->{parentId} =~/\w+/;
  return $self->searchFeaturesSet($data)    if defined $data->{start};

}

=head2 searchFeaturesSet
      handle POST region by set queries
=cut
sub searchFeaturesSet {

  my ($self, $data ) = @_;

  ## get slice  
  my $sla = $self->context->model('Registry')->get_adaptor('homo_sapiens', 'core', 'slice');
 
  my $location   = $data->{referenceName} ."\:" . $data->{start} . "\-" . $data->{end};
  $data->{slice} = $sla->fetch_by_toplevel_location( $location );


  ## get features of required type 
  my @features;

  push @features, @{$self->extractTranscriptsBySegment( $data )}
    if exists $data->{required_types}->{transcript};

  push @features, @{$self->extractGenesBySegment( $data )}
    if exists $data->{required_types}->{gene}; 

  push @features, @{$self->extractExonsBySegment( $data )}
    if exists $data->{required_types}->{exons};


  ## sort & trim features
  my $sorted_features = sort_features(\@features);

  ## FIXME - if a page token was provided check for colocated features

  my ($return_features, $nextPageToken) = $self->reduce_size($sorted_features, $data->{pageSize});

  return ({ features      => $return_features, 
            nextPageToken => $nextPageToken});

}
=head2 extractTranscriptsBySegment
      returns one more Feature than required for paging
=cut
sub extractTranscriptsBySegment{

  my ($self, $data ) = @_;

  my @features;
  my $count = 0;

  my $tra = $self->context->model('Registry')->get_adaptor('homo_sapiens', 'Core', 'Transcript');
  my $transcripts = $tra->fetch_all_by_Slice( $data->{slice} ) ;

  foreach my $tr (@{$transcripts}){

    ## if pageSize +1 reached, return
    last if $count == $data->{pageSize} +1 ;
 
    my $gafeat = $self->formatTranscript($tr, $data);
    push @features,  $gafeat;

    $count++;

  }
  return \@features;
}

=head2 extractGenesBySegment
      returns one more Feature than required for paging
=cut
sub extractGenesBySegment{

  my ($self, $data ) = @_;
  
  my @features;
  my $count = 0;
  
  my $ga = $self->context->model('Registry')->get_adaptor('homo_sapiens', 'Core', 'Gene');
  my $genes = $ga->fetch_all_by_Slice( $data->{slice} ) ;

  foreach my $gene (@{$genes}){

    ## if pageSize +1 reached, return
    last if $count == $data->{pageSize} +1 ;
 
    my $gafeat = $self->formatGene($gene, $data);
    push @features,  $gafeat;
    ## keep count for pageSize
    $count++;

  }
  return \@features;  
}

=head2 extractExonsBySegment
      returns one more Feature than required for paging
=cut
sub extractExonsBySegment{

  my ($self, $data ) = @_;
 
  my @features;
  my $count = 0;
  
  my $ea = $self->context->model('Registry')->get_adaptor('homo_sapiens', 'Core', 'Exon');
  my $exons = $ea->fetch_all_by_Slice( $data->{slice} ) ;

  foreach my $exon (@{$exons}){

    ## if pageSize +1 reached, return
    last if $count == $data->{pageSize} +1 ;

    my $gafeat = $self->formatExon($exon, $data);
    push @features,  $gafeat;
    ## keep count for pageSize
    $count++;

  }
  return \@features;
}

=head2 searchFeaturesParent
      POST search by parent id 
      supports genes & transcipts 
=cut
sub searchFeaturesParent{

  my $self = shift;
  my $data = shift;

  return $self->getTranscriptChildren($data) if $data->{parentId} =~/ENST/;
  return $self->getGeneChildren($data)       if $data->{parentId} =~/ENSG/;

}
=head2 getTranscriptChildren
      return translations and exons as required
=cut
sub getTranscriptChildren{

  my $self = shift;
  my $data = shift;
 
  my $tra = $self->context->model('Registry')->get_adaptor('homo_sapiens', 'core', 'transcript');
  my ($stable_id, $version) = split /\./, $data->{parentId}; 
  my $tr = $tra->fetch_by_stable_id_version( $stable_id, $version );

  Catalyst::Exception->throw("  Cannot find transcript feature for id " . $data->{parentId}  )
    unless defined $tr ;

  my @features;

  if( exists $data->{required_types}->{exon} ){
    my $ea   = $self->context->model('Registry')->get_adaptor('homo_sapiens', 'core', 'exon');
    my $exons = $ea->fetch_all_by_Transcript( $tr);
    foreach my $exon(@{$exons}){
      push @features, $self->formatExon($exon, $data);
    }
  }

  if( exists $data->{required_types}->{protein} ){
    my $ta   = $self->context->model('Registry')->get_adaptor('homo_sapiens', 'core', 'translation');
    my $translation = $ta->fetch_by_Transcript( $tr );
    push @features, $self->formatProtein($translation, $data) if defined $translation;
  }

  if( exists $data->{required_types}->{cds} ){

    my $cdsfs = $tr->get_all_CDS();
    foreach my $cdsf (@{$cdsfs}){
      push @features,  $self->formatCDS($cdsf, $data); 
    }
   }

  my $sorted_features = sort_features(\@features);

  ## reduce number of entries returned if greater than requested page size
  my ($return_features, $nextPageToken) = $self->reduce_size($sorted_features, $data->{pageSize});

  return ({ features      => $return_features, 
            nextPageToken => $nextPageToken});  

}
=head2 getGeneChildren
      return transcripts
=cut
sub getGeneChildren{

  my $self = shift;
  my $data = shift;

  ## only supporting transcripts as children of genes, so return if they are not required
  return ({ features      => [],
            nextPageToken => undef})
    unless exists $data->{required_types}->{transcript};


  my $ga   = $self->context->model('Registry')->get_adaptor('homo_sapiens', 'core', 'gene');
  my ($stable_id, $version) = split /\./, $data->{parentId};
  my $gene = $ga->fetch_by_stable_id_version( $stable_id, $version );

  Catalyst::Exception->throw(" Cannot find gene feature for id " . $data->{parentId})
    unless defined $gene ;

  my @features;

  my $tra = $self->context->model('Registry')->get_adaptor('homo_sapiens', 'core', 'transcript');
  my $trs = $tra->fetch_all_by_Gene( $gene, $data );
  foreach my $tr(@{$trs}){
    push @features, $self->formatTranscript($tr, $data);
  }

  my $sorted_features = sort_features(\@features);

  ## reduce number of entries returned if greater than requested page size
  my ($return_features, $nextPageToken) = $self->reduce_size($sorted_features, $data->{pageSize});

  return ({ features      => $return_features,
            nextPageToken => $nextPageToken});

}

=head2 getFeature
    GET endpoint
=cut
sub getFeature{

  my $self = shift;
  my $id   = shift;
  
  my $data;
  $data->{featureSet} = $self->context->model('ga4gh::ga4gh_utils')->fetch_featureSet();

  return $self->getTranscript($id, $data) if $id =~/ENST\d+\.\d+/;
  return $self->getGene($id, $data)       if $id =~/ENSG/;
  return $self->getProtein($id, $data)    if $id =~/ENSP/;
  return $self->getExon($id, $data)       if $id =~/ENSE/;

  return {};  ## not the id of a supported feature
}

#### look up features by id


sub getTranscript{

  my $self = shift;
  my $id   = shift;
  my $data = shift;

  my $tra = $self->context->model('Registry')->get_adaptor('homo_sapiens', 'Core', 'Transcript');
  my ($stable_id, $version) = split /\./, $id;

  my $tr = $tra->fetch_by_stable_id_version( $stable_id, $version );

  Catalyst::Exception->throw("  Cannot find transcript feature for id " . $id  )
    unless defined $tr ;

  return $self->formatTranscript($tr, $data);

}

sub getExon{

  my $self = shift;
  my $id   = shift;
  my $data = shift;

  my $ea   = $self->context->model('Registry')->get_adaptor('homo_sapiens', 'core', 'exon');
  my ($stable_id, $version) = split /\./, $id;
  my $exon = $ea->fetch_by_stable_id_version( $stable_id, $version );

  Catalyst::Exception->throw(" Cannot find exon feature for id " . $id)
    unless defined $exon ;

  return $self->formatExon($exon, $data) ;

}

sub getGene{

  my $self = shift;
  my $id   = shift;
  my $data = shift;

  my $ga   = $self->context->model('Registry')->get_adaptor('homo_sapiens', 'Core', 'Gene');
  my ($stable_id, $version) = split /\./, $id;
  my $gene = $ga->fetch_by_stable_id_version( $stable_id, $version );


  Catalyst::Exception->throw(" Cannot find gene feature for id " . $id)
    unless defined $gene ;

  return $self->formatGene($gene, $data) ;

}

sub getProtein{

  my ($self, $id, $data) = @_;

  my $ta   = $self->context->model('Registry')->get_adaptor('homo_sapiens', 'Core', 'translation');
  my ($stable_id, $version) = split/\./, $id;
  my $translation = $ta->fetch_by_stable_id_version( $stable_id, $version );

  Catalyst::Exception->throw(" Cannot find gene feature for id " . $id)
    unless defined $translation ;

  return $self->formatProtein($translation, $data) ;

}

########### look up common values

=head2 fetchSO
      look up onology information for type
      return GA4GH OntologyTerm
=cut
sub fetchSO{

  my $self = shift;
  my $type = shift;

  ## a default in case of database unavailability 
  my $default = { id            => undef,
                  term          => $type,
                  sourceName    => undef,
                  sourceVersion => undef
                  };

  my $onta = $self->context->model('Registry')->get_adaptor('Multi', 'Ontology', 'OntologyTerm');
  return $default  unless defined $onta;

  my $ont  = $onta->fetch_all_by_name($type); 
  return $default  unless defined $ont;


  return ( { id            => $ont->[0]->accession(),
             term          => $ont->[0]->name(), 
             sourceName    => $ont->[0]->ontology(),
             sourceVersion => undef 
            });
}

=head2 getTypes
      compare requested types, if any to supported types
      seek SO terms for required types
=cut
sub getTypes{

  my $self = shift;
  my $data = shift;

  my $allowed_features = $self->allowed_features();

  ## check if requested feature type is supported
  if (exists $data->{featureTypes}->[0] ){

    foreach my $term (@{$data->{featureTypes}}){
      $data->{required_types}->{$term} = 1 if exists $allowed_features->{$term};
    }
 
    ## exit if only unsupported features are requested
    return undef unless scalar keys(%{$data->{required_types}}) >0  ;
  }
  else{
    ## return all features
    foreach my $type (keys %{$allowed_features} ){
      $data->{required_types}->{$type} = 1;
    }
  }


  ## look up SO terms once if extracting many via search
  foreach my $type (keys %{$data->{required_types}}){
    $data->{ontol}->{$type} = $self->fetchSO($type);
  }

  return $data;
}

###### format

=head2 formatTranscript
       turn ensembl transcript into GA4GH feature
=cut
sub formatTranscript{

  my $self = shift;
  my $tr   = shift;
  my $data = shift;

  ## format generic feature information
  my $feature = $self->formatFeature($tr, $data, 'transcript');

  ## add relatives
  $feature->{parentId}  = $tr->get_Gene()->stable_id_version(); 

  my $ea   = $self->context->model('Registry')->get_adaptor('homo_sapiens', 'core', 'exon');
  my $exons = $ea->fetch_all_by_Transcript($tr);
  foreach my $exon(@{$exons}){
    push @{$feature->{childIds}}, $exon->stable_id_version();
  }

  if (defined $tr->translation()){
    ## add protein feature
    push @{$feature->{childIds}}, $tr->translation()->stable_id_version();
  }

  return $feature;
}

=head2 formatExon
      turn ensembl exon into GA4GH feature
=cut
sub formatExon{

  my $self = shift;
  my $exon = shift;
  my $data = shift;

  my $feature = $self->formatFeature($exon, $data, 'exon');

  ## set parent ids!!

  return $feature;

}
=head2 formatGene
      turn ensembl gene into GA4GH feature
=cut
sub formatGene{

  my $self = shift;
  my $gene = shift;
  my $data = shift;

  my $feature = $self->formatFeature($gene, $data, 'gene');

  ## set child ids to transcripts
  my $childIds;
  my $transcripts = $gene->get_all_Transcripts();
  foreach my $transcript (@{$transcripts}){
    push @{$childIds}, $transcript->stable_id_version()
  }
  $feature->{childIds} = $childIds;

  return $feature;

}

=head2 formatFeature
      formatting generic to transcript, exon, gene
=cut
sub formatFeature{

  my $self = shift;
  my $feat = shift;
  my $data = shift;
  my $type = shift;

  my $strand;
  $feat->seq_region_strand() eq 1 ? $strand = 'POS_STRAND'
                                  : $strand = 'NEG_STRAND';


  my $gaFeature  = { id            => $feat->stable_id_version(),
                     parentId      => undef,
                     childIds      => [],
                     featureSetId  => $data->{featureSet}->{id},
                     referenceName => $feat->seq_region_name(),
                     start         => $feat->seq_region_start() - 1,
                     end           => $feat->seq_region_end(),
                     strand        => $strand
                    };

  ## look up ontology info if non cached
  $data->{ontol}->{$type} = $self->fetchSO($type)
    unless exists $data->{ontol}->{$type};

  $gaFeature->{featureType} = $data->{ontol}->{$type};

  ## what is interesting here?
  $gaFeature->{attributes} = { version => [ $feat->version()      ],
                               created => [ $feat->created_date() ],
                               updated => [ $feat->modified_date()]
                             };

  unless ($type =~/exon/){
    ## add attributes
    my $attribs = $feat->get_all_Attributes();
    foreach my $attrib(@{$attribs}){
      next if $attrib->name() =~ /Author email address|Hidden Remark/;
      my $attrib_type = $attrib->name();## need to be lower case
      $gaFeature->{attributes}->{"\L$attrib_type"} = [ $attrib->value ];
    }

    $gaFeature->{attributes}->{external_name} = [ $feat->external_name() ]
      if defined $feat->external_name();

    $gaFeature->{attributes}->{biotype} = [ $feat->biotype() ]
      if defined  $feat->biotype();

    $gaFeature->{attributes}->{source} = [ $feat->source() ];
  }

  return $gaFeature;
}

=head2 formatProtein
      turn ensembl translation into GA4GH feature (NOT a great fit)
=cut
sub formatProtein{

  my $self = shift;
  my $feat = shift;
  my $data = shift;

  my $gaFeature  = { id            => $feat->stable_id(),
                     parentId      => $feat->transcript()->stable_id(),
                     childIds      => [],
                     featureSetId  => $data->{featureSet}->{id},
                     referenceName => undef,
                     start         => $feat->genomic_start() - 1,
                     end           => $feat->genomic_end(),
                     strand        => undef
                    };


  ## look up ontology info if non cached
  $data->{ontol}->{'polypeptide'} = $self->fetchSO('polypeptide')
    unless exists $data->{ontol}->{'polypeptide'};

  $gaFeature->{featureType} = $data->{ontol}->{'polypeptide'};



  $gaFeature->{attributes} = { version => [ $feat->version() ],
                               created => [ $feat->created_date() ],
                               updated => [ $feat->modified_date()]
                             };

  return $gaFeature;
}


sub formatCDS{

  my $self = shift;
  my $feat = shift;
  my $data = shift;

  my $gaFeature  = { id            => $feat->transcript()->stable_id_version() . "." . $feat->seq_region_start(),
                     parentId      => $feat->transcript()->stable_id_version(),
                     childIds      => [$feat->transcript()->translation()->stable_id_version()],
                     featureSetId  => $data->{featureSet}->{id},
                     referenceName => undef,
                     start         => $feat->seq_region_start() - 1,
                     end           => $feat->seq_region_end(),
                     strand        => undef
                    };


  ## look up ontology info if non cached
  $data->{ontol}->{'CDS_region'} = $self->fetchSO('CDS_region')
    unless exists $data->{ontol}->{'CDS_region'};

  $gaFeature->{featureType} = $data->{ontol}->{'CDS_region'};


  return $gaFeature;
}


=head2 sort_features
      features must be sorted by start position
=cut 
sub sort_features{

  my $feat = shift;

  my @sorted = sort {  $a->{start} <=> $b->{start} } @{$feat};

  return \@sorted;
}

=head2 reduce_size
  reduce number of entries returned if greater than requested page size 
=cut 
sub reduce_size{

  my $self     = shift;
  my $features = shift;
  my $pageSize = shift;

  my $nextPageToken;
  my @return_features;

  if(scalar(@{$features}) > $pageSize){
    @return_features = splice(@{$features}, 0, $pageSize);
    ## duplication problem if features may have the same start coordinate
    $nextPageToken = $features->[0]->{start}; 
  }
  else{
    @return_features = @{$features};
  }

  return(\@return_features, $nextPageToken);
}

1;
