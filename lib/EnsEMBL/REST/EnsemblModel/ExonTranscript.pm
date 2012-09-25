package EnsEMBL::REST::EnsemblModel::ExonTranscript;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::Utils::Proxy/;
use Bio::EnsEMBL::Utils::Scalar qw/split_array/;

my $SPLIT = 1000;

sub new {
  my ($class, $proxy_exon, $parent_id, $rank) = @_;
  my $self = $class->SUPER::new($proxy_exon);
  $self->{parent_id} = $parent_id;
  $self->{rank} = $rank;
  return $self;
}

sub build_all_from_Exons {
  my ($class, $exons) = @_;
  my @objs;
  my $split_exons = split_array($SPLIT, $exons);
  foreach my $exon_list (@{$split_exons}) {
    my $et_objs = $class->_build_from_Exon_list($exon_list);
    push(@objs, @{$et_objs});
  }
  return \@objs;
}

sub _build_from_Exon_list {
  my ($class, $exons) = @_;
  my @built;
  my $length = scalar(@{$exons});
  if(@{$exons}) {
    my $h = $exons->[0]->adaptor->dbc->sql_helper();
    
    my @in_placeholders = ('?') x $length;
    my $in = join(',', @in_placeholders);
    my $sql = <<SQL;
select et.exon_id, et.rank, t.stable_id 
from exon_transcript et 
join transcript t using (transcript_id) 
where et.exon_id IN (${in})
SQL
    my $callback = sub {
      my ($row, $value) = @_;
      my ($exon_id, $rank, $stable_id) = @{$row};
      my $result = [$rank, $stable_id];
      if ( defined $value ) {
        push( @{$value}, $result );
        return;
      }
      return [ $result ];
    };
    
    my $params = [map { $_->dbID() } @{$exons}];
    
    my $lookup = $h->execute_into_hash(-SQL => $sql, -PARAMS => $params, -CALLBACK => $callback);
    
    foreach my $exon (@{$exons}) {
      my $hits = $lookup->{$exon->dbID()};
      foreach my $hit (@{$hits}) {
        my ($rank, $stable_id) = @{$hit};
        my $obj = $class->new($exon, $stable_id, $rank);
        push(@built, $obj);
      }
    }
  }
  return \@built;
}

sub rank {
  my ($self, $rank) = @_;
  $self->{'rank'} = $rank if defined $rank;
  return $self->{'rank'};
}

sub parent_id {
  my ($self, $parent_id) = @_;
  $self->{'parent_id'} = $parent_id if defined $parent_id;
  return $self->{'parent_id'};
}

sub summary_as_hash {
  my ($self) = @_;
  my $proxy = $self->__proxy();
  my $exon_summary = $proxy->summary_as_hash();
  $exon_summary->{Parent} = $self->parent_id();
  $exon_summary->{rank} = $self->rank();
  return $exon_summary;
}

sub SO_term {
  my ($self) = @_;
  return 'SO:0000147';
}

sub __resolver {
  my ($invoker, $package, $method) = @_;
  return sub {
    my ($self, @args);
    return $self->$method(@args);
  };
}

sub distribute {
  my ($n, $array) = @_;

  my @parts;
  my $i = 0;
  foreach my $elem (@$array) {
      push @{ $parts[$i++ % $n] }, $elem;
  };
  return \@parts;
};

1;