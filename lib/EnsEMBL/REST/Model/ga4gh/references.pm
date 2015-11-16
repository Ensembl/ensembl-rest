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

package EnsEMBL::REST::Model::ga4gh::references;

use Moose;

extends 'Catalyst::Model';
use Data::Dumper;
with 'Catalyst::Component::InstancePerContext';

has 'context' => (is => 'ro');

use EnsEMBL::REST::Model::ga4gh::ga4gh_utils;


our $species = 'homo_sapiens';

sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  return $self->new({ context => $c, %$self, @args });
}


## handle POST requests
sub fetch_references {
  
  my $self = shift;

  my ($references, $nextPageToken) = $self->extract_data( $self->context()->req->data() );

  return ({ references    => $references, 
            nextPageToken => $nextPageToken});
}


### GET single reference by 'id'
sub getReference{

  my ($self, $get_id ) = @_;

  my ($reference, $assemblId) = $self->get_sequence($get_id);

  $self->context()->go( 'ReturnError', 'custom', ["ERROR: no data for $get_id"])
    unless defined $reference &&  ref($reference) eq 'HASH' ; 

  return $self->format_sequence($reference, $assemblId);
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
    if (defined $post_data->{pageSize} &&  $post_data->{pageSize} ne '' && $count > $post_data->{pageSize}){
      $nextPageToken = $n;
      last;
    }

    my $ref = $self->format_sequence($refseq, $refSeqSet->{id}, $ens_version); 
    push @references,  $ref;
  }

  return (\@references, $nextPageToken ) ;

}

sub format_sequence{

  my $self     = shift;
  my $seq      = shift;
  my $assembly = shift;
  my $ens_ver  = shift;

  my %ref;

  $ref{length}           = $seq->{length};
  $ref{id}               = $seq->{md5};   ### is this the best approach?
  $ref{name}             = $seq->{name};
  $ref{md5checksum}      = $seq->{md5};
  $ref{sourceAccessions} = $seq->{sourceAccessions}; 
  $ref{isPrimary}        = $seq->{isPrimary};

  $ref{ncbiTaxonId}      = 9609; 
  $ref{isDerived}        = 'true'; ##ambiguity codes have been changed to Ns
  $ref{sourceDivergence} = '';


  ## define url - ensembl version not in config
  if( $assembly =~ /compliance/){
     $ref{sourceURI} = "https://github.com/ga4gh/compliance/blob/master/test-data/";
  }
  else{
    $ens_ver  = 75         if $assembly =~/GRCh37/; 
    $assembly =~ s/\.p13// if $assembly =~/GRCh37/;

    $ref{sourceURI} =  'ftp://ftp.ensembl.org/pub/release-'. $ens_ver .'/fasta/homo_sapiens/dna/Homo_sapiens.'. $assembly.'.dna.chromosome.' . $ref{name} . '.fa.gz'; 
  }

  return \%ref;
}

sub get_ensembl_version{

  my $self  = shift;

  my $core_ad     = $self->context->model('Registry')->get_DBAdaptor($species, 'core');
  my $core_meta   = $core_ad->get_MetaContainer();

  return $core_meta->schema_version();

}

## extract specific reference sequence from config data
sub get_sequence{

  my $self = shift;
  my $id   = shift;

  my $config = $self->context->model('ga4gh::ga4gh_utils')->read_sequence_config();


  foreach my $referenceSet (@{$config->{referenceSets}}){
    foreach my $seq (@{$referenceSet->{sequences}}){
      return ($seq, $referenceSet->{id}) if $seq->{md5} eq $id;
    } 
  }
  return undef;
}

## extract specific reference set from config data
sub get_sequenceset{

  my $self = shift;
  my $set  = shift;

  my $config = $self->context->model('ga4gh::ga4gh_utils')->read_sequence_config();

  foreach my $referenceSet (@{$config->{referenceSets}}){
    return $referenceSet if $referenceSet->{id} eq $set;
  }
  return undef;
}

1;
