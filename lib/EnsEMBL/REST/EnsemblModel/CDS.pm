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
      foreach my $stable_id (@{$hits}) {
        my $rank = 1;
        foreach my $exon (@{$transcript->get_all_translateable_Exons}) {
          my $obj = $class->new($stable_id, $parent_id, $exon, $rank++);
          push(@built, $obj);
        }
      }
    }
  }
  return \@built;
}

sub new {
  my ($class, $stable_id, $parent_id, $exon, $rank) = @_;
  my $self = $class->SUPER::new_fast({
    translateable_exon => $exon,
    stable_id => $stable_id,
    parent_id => $parent_id,
    rank => $rank,
  });
  return $self;
}

sub parent_id {
  my ($self, $parent_id) = @_;
  $self->{'parent_id'} = $parent_id if defined $parent_id;
  return $self->{'parent_id'};
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

sub rank {
  my ($self, $rank) = @_;
  $self->{'rank'} = $rank if defined $rank;
  return $self->{'rank'};
}

sub stable_id {
  my ($self, $stable_id) = @_;
  $self->{'stable_id'} = $stable_id if defined $stable_id;
  return $self->{'stable_id'};
}

sub summary_as_hash {
  my ($self) = @_;
  my $summary = $self->SUPER::summary_as_hash();
  $summary->{Parent} = $self->parent_id;
  $summary->{ID} = $self->stable_id();
  $summary->{phase} = 0;
  $summary->{rank} = $self->rank();
  return $summary;
}

sub SO_term {
  my ($self) = @_;
  return 'SO:0000316'; #CDS
}

1;