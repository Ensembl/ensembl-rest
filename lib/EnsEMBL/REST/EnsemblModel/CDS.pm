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

package EnsEMBL::REST::EnsemblModel::CDS;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::Feature/;
use Bio::EnsEMBL::Utils::Scalar qw/assert_ref split_array/;

my $SPLIT = 1000;

sub new_from_Transcripts {
  my ($class, $transcripts) = @_;
  my @cds_features;
  my $split_transcripts = split_array($SPLIT, $transcripts);
  foreach my $split (@{$split_transcripts}) {
    my $results = $class->_new_from_Transcript_list($split);
    push(@cds_features, @{$results});
  }
  return \@cds_features;
}

sub _new_from_Transcript_list {
  my ($class, $transcripts) = @_;
  my @built;
  my $length = scalar(@{$transcripts});
  if(@{$transcripts}) {
    my $h = $transcripts->[0]->adaptor->dbc->sql_helper();
    
    my @in_placeholders = ('?') x $length;
    my $in = join(',', @in_placeholders);
    my $sql = <<SQL;
select t.transcript_id, t.stable_id 
from translation t  
where t.transcript_id IN (${in})
SQL
    my $callback = sub {
      my ($row, $value) = @_;
      my ($transcript_id, $stable_id) = @{$row};
      my $result = $stable_id;
      if ( defined $value ) {
        push( @{$value}, $result );
        return;
      }
      return [ $result ];
    };
    
    my $params = [map { $_->dbID() } @{$transcripts}];
    
    my $lookup = $h->execute_into_hash(-SQL => $sql, -PARAMS => $params, -CALLBACK => $callback);
    
    foreach my $transcript (@{$transcripts}) {
      my $hits = $lookup->{$transcript->dbID()};
      my $parent_id = $transcript->stable_id();
      my $source = $transcript->source();
      foreach my $stable_id (@{$hits}) {
        my $rank = 1;
        my $phase = 0;
        foreach my $exon (@{$transcript->get_all_translateable_Exons}) {
          $phase = $exon->phase();
          $phase = 0 if $phase < 0;
          $phase  =~ tr/12/21/;  # The GFF definition of phase
          my $obj = $class->new($stable_id, $parent_id, $exon, $phase, $source);
          push(@built, $obj);
        }
      }
    }
  }
  return \@built;
}

sub new {
  my ($class, $stable_id, $parent_id, $exon, $phase, $source) = @_;
  my $self = $class->SUPER::new_fast({
    translateable_exon => $exon,
    stable_id => $stable_id,
    parent_id => $parent_id,
    phase => $phase,
    source => $source,
  });
  return $self;
}

sub parent_id {
  my ($self, $parent_id) = @_;
  $self->{'parent_id'} = $parent_id if defined $parent_id;
  return $self->{'parent_id'};
}

sub source {
  my ($self, $source) = @_;
  $self->{'source'} = $source if defined $source;
  return $self->{'source'};
}

sub translateable_exon {
  my ($self, $translateable_exon) = @_;
  $self->{'translateable_exon'} = $translateable_exon if defined $translateable_exon;
  return $self->{'translateable_exon'};
}

sub seq_region_name {
  my ($self) = @_;
  return $self->translateable_exon()->seq_region_name();
}

sub seq_region_start {
  my ($self) = @_;
  return $self->translateable_exon()->seq_region_start();
}

sub strand {
  my ($self) = @_;
  return $self->translateable_exon()->strand();
}

sub seq_region_end {
  my ($self) = @_;
  return $self->translateable_exon()->seq_region_end();
}

sub assembly_name {
  my ($self) = @_;
  return $self->translateable_exon()->slice()->coord_system()->version();
}

sub stable_id {
  my ($self, $stable_id) = @_;
  $self->{'stable_id'} = $stable_id if defined $stable_id;
  return $self->{'stable_id'};
}

sub phase {
  my ($self, $phase)  = @_;
  $self->{'phase'} = $phase if defined $phase;
  return $self->{'phase'};
}

sub summary_as_hash {
  my ($self) = @_;
  my $summary = $self->SUPER::summary_as_hash();
  $summary->{Parent} = $self->parent_id;
  $summary->{id} = $self->stable_id();
  $summary->{phase} = $self->phase();
  $summary->{source} = $self->source();
  $summary->{assembly_name} = $self->assembly_name();
  return $summary;
}

sub SO_term {
  my ($self) = @_;
  return 'SO:0000316'; #CDS
}

1;
