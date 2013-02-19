package EnsEMBL::REST::Model::LucyIDLookup;

use Moose;
use namespace::autoclean;
eval { require Lucy::Search::IndexSearcher };
my $LUCY_NOT_OK = $@;

extends 'Catalyst::Model';

has 'location' => (isa => 'Str', is => 'ro', default => 'THISPATHDOESNOTEXIST');
has 'searcher' => (isa => 'Lucy::Search::IndexSearcher', is => 'ro', lazy => 1, builder => 'build_searcher');

sub build_searcher {
  my ($self) = @_;
  if($LUCY_NOT_OK) {
    croak('Apache Lucy is not available. You cannot use this module as an ID lookup unless it is available');
  }
  my $searcher = Lucy::Search::IndexSearcher->new( 
      index => $self->location(), 
  );
  return $searcher;
}

sub find_object_location {
  my ($self, $id, $object_type, $db_type, $species) = @_;
  my @queries;
  push(@queries, Lucy::Search::TermQuery->new(field => 'stable_id', term => $id)) if $id;
  push(@queries, Lucy::Search::TermQuery->new(field => 'object_type', term => $object_type)) if $object_type;
  push(@queries, Lucy::Search::TermQuery->new(field => 'group', term => $db_type)) if $db_type;
  push(@queries, Lucy::Search::TermQuery->new(field => 'species', term => $species)) if $species;
  my $query = (scalar(@queries) == 1) ? $queries[0] : Lucy::Search::ANDQuery->new(children => \@queries);
  my $hits = $self->searcher()->hits(query => $query);
  my @captures;
  while ( my $hit_doc = $hits->next ) {
    @captures = map { $hit_doc->{$_} } qw/species object_type group/;
    last;
  }
  return @captures;
}

1;