=head
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

package EnsEMBL::REST::Model::ga4gh::references;

use Moose;

extends 'Catalyst::Model';
use Catalyst::Exception;
use Scalar::Util qw/weaken/;

use Try::Tiny;
with 'Catalyst::Component::InstancePerContext';

has 'context' => (is => 'ro', weak_ref => 1);

use Bio::DB::Fasta;
use EnsEMBL::REST::Model::ga4gh::ga4gh_utils;



sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  weaken($c);
  return $self->new({ context => $c, %$self, @args });
}


## handle POST requests
sub fetch_references {
  
  my $self = shift;

  my $data = $self->context()->req->data();

  return ({ references    => [],
            nextPageToken => $data->{pageToken} }) if $data->{pageSize} < 1;

  my ($references, $nextPageToken) = $self->extract_data( $data );

  return ({ references    => $references, 
            nextPageToken => $nextPageToken});
}


### GET single reference by 'id'
sub getReference{

  my ($self, $get_id, $bases ) = @_;

  my $reference = $self->context->model('ga4gh::ga4gh_utils')->get_sequence($get_id);

  return undef unless defined $reference && ref($reference) eq 'HASH' ; 

  ## request for substring 
  if ( defined $bases){
    return $self->format_base_sequence($reference);
  }
  else{
    ## request for sequence info
    return $self->format_sequence($reference);
  }
}


## fetch a sequence set & handle filters/paging 
sub extract_data{

  my $self      = shift;
  my $post_data = shift;

  my @references;
  my $count = 0;
  my $nextPageToken;

  ## paging - set the default page token to 0 unless one is specified
  $post_data->{pageToken} = 0 unless defined $post_data->{pageToken} && $post_data->{pageToken} ne '';

  ## look up ensembl version for the ftp site attribute
  my $ens_version = $self->get_ensembl_version();

  ## read config and get look up from seq name to MD5
  my $refSeqSet = $self->get_sequenceset($post_data->{referenceSetId});

  ## return empty array if no sequences for this set (behaviour not fully specified)
  return ( [], $nextPageToken) unless defined $refSeqSet &&  ref($refSeqSet) eq 'HASH' ;

  ## loop through available sequences
  foreach (my $n = $post_data->{pageToken}; $n < scalar(@{$refSeqSet->{sequences}} ); $n++){

    my $refseq = $refSeqSet->{sequences}->[$n];

    ## filter by any supplied attributes 
    next if defined $post_data->{md5checksum} && $post_data->{md5checksum} ne '' 
                                              && $post_data->{md5checksum} ne $refseq->{md5};

    next if defined $post_data->{accession}   && $post_data->{accession}   ne ''
                                              && $post_data->{accession}   ne $refseq->{sourceAccessions}->[0]; 

    ## rough paging
    $count++;
    if ( $count > $post_data->{pageSize}){
      $nextPageToken = $n;
      last;
    }
    $refseq->{assembly} = $refSeqSet->{id};
    my $ref = $self->format_sequence($refseq, $ens_version); 
    push @references,  $ref;
  }

  return (\@references, $nextPageToken ) ;

}

sub format_sequence{

  my $self     = shift;
  my $seq      = shift;
  my $ens_ver  = shift;

  $ens_ver ||= $self->get_ensembl_version();

  my %ref;

  $ref{length}           = $seq->{length};
  $ref{id}               = $seq->{md5};   ### is this the best approach?
  $ref{name}             = $seq->{name};
  $ref{md5checksum}      = $seq->{md5};
  $ref{sourceAccessions} = $seq->{sourceAccessions}; 
  $ref{isPrimary}        = $seq->{isPrimary};

  $ref{ncbiTaxonId}      = 9606; 
  $ref{isDerived}        = 'true'; ##ambiguity codes have been changed to Ns
  $ref{sourceDivergence} = undef;


  ## define url - ensembl version not in config
  if( $ref{sourceAccessions} && $ref{sourceAccessions}->[0] =~ /GA4GH/){
     $ref{sourceURI} = "https://github.com/ga4gh/compliance/blob/master/test-data/";
  }
  else{
     $ens_ver = 75 if $seq->{assembly} =~/GRCh37/;
     $seq->{assembly} =~ s/\.p13// if $seq->{assembly} =~/GRCh37/;
     ## over-write stored ftp location with current for GRCh38 site
     $ref{sourceURI} = 'https://ftp.ensembl.org/pub/release-'. $ens_ver .'/fasta/homo_sapiens/dna/Homo_sapiens.'. $seq->{assembly};
      if($seq->{assembly} =~/GRCh37/) {
        $ref{sourceURI} .= '.75.dna.chromosome.' . $ref{name} . '.fa.gz';
      }
      else {
        $ref{sourceURI} .= '.dna.chromosome.' . $ref{name} . '.fa.gz';
      }
  }

  return \%ref;
}

sub get_ensembl_version{

  my $self  = shift;

  my $core_ad     = $self->context->model('Registry')->get_DBAdaptor($self->species(), 'core');
  my $core_meta   = $core_ad->get_MetaContainer();

  return $core_meta->schema_version();

}


## extract specific reference set from config data
sub get_sequenceset{

  my $self = shift;
  my $set  = shift;

  my $config = $self->context->model('ga4gh::ga4gh_utils')->read_sequence_config();
  return undef unless exists $config->{referenceSets};

  foreach my $referenceSet (@{$config->{referenceSets}}){
    return $referenceSet if $referenceSet->{id} eq $set;
  }
  return undef;
}

sub format_base_sequence{

  my $self      = shift;
  my $reference = shift;  

  my $c = $self->context();

  ## do paging..  ** PICK A SENSIBLE LIMIT
  ## start and end are optional
  my $nextPageToken;
  my $current_end   = $c->request->param('end') 
    if defined $c->request->param('end') && $c->request->param('end') =~/\d+/;


  ## Choose a start from the input info
  my $current_start;  
  
  if (defined $c->request->param('nextPageToken') && $c->request->param('nextPageToken') =~/\d+/){
    $current_start = $c->request->param('nextPageToken');
  }
  elsif (defined $c->request->param('start') && $c->request->param('start') =~/\d+/){
    $current_start = $c->request->param('start') +1; ## convert to zero based coordinates
  }
  else{
    $current_start = 1;
  }

  if( !defined $c->request->param('end') || 
      $c->request->param('end') !~/\d+/  ||
      $c->request->param('end') - $current_start > 1000){
     $nextPageToken             = $current_start + 1001;
     $current_end               = $current_start + 1000;

  }

  my $region = $reference->{name} . ":" . $current_start . "-" . $current_end ;

  my $sequence;
  if( $reference->{sourceAccessions}->[0] =~ /GA4GH/){
    ## compliance - read fasta file
    $sequence = $self->fetch_ga4gh_sequence($reference, $region);
  }
  else{
    ## take from slice
    $sequence  = $self->fetch_ensembl_sequence($reference, $region);
  }

  return { offset        => $current_start -1,
           sequence      => $sequence,
           nextPageToken => $nextPageToken
         };
}

sub fetch_ensembl_sequence{

  my $self      = shift;
  my $reference = shift;
  my $region    = shift;

  my $sla   = $self->context()->model('Registry')->get_adaptor( $self->species(), 'Core', 'Slice');
  my $slice = $sla->fetch_by_toplevel_location($region);

  Catalyst::Exception->throw("ERROR: no sequence available for region $region")
    unless defined $slice ;

  return $slice->seq();
}

sub fetch_ga4gh_sequence{

  my $self      = shift;
  my $reference = shift;
  my $region    = shift;

  my ($seq, $current_start, $current_end)   = split/\:|\-/, $region;

  my $db;
  try{ 
    $db = Bio::DB::Fasta->new( $reference->{fastafile} );
  }
  catch{
    Catalyst::Exception->throw("ERROR: finding sequence for region $region in compliance data")
  };

  return $db->seq( $reference->{name} , $current_start, $current_end );

} 

sub species{
  return 'homo_sapiens';
}

1;
