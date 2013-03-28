package EnsEMBL::REST::Controller::Lookup;
use Moose;
use namespace::autoclean;
use Try::Tiny;

BEGIN {extends 'Catalyst::Controller::REST'; }

require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

my $FORMAT_TYPES = { full => 1, condensed => 1 };

sub id : Chained('') Args(1) PathPart('lookup/id') {
  my ($self, $c, $id) = @_;

  # output format check
  my $format = $c->request->param('format') || 'condensed';
  $c->go('ReturnError', 'custom', [qq{The format '$format' is not an understood encoding}]) unless $FORMAT_TYPES->{$format};

  my ($species, $object_type, $db_type, $chr, $start, $end, $strand) = try {
    $c->model('Lookup')->find_object_location($id);
  }
  catch {
    $c->go('ReturnError', 'from_ensembl', [$_]);
  };
  $c->go('ReturnError', 'custom',  [qq{No valid lookup found for ID $id}]) unless $species;


  $self->status_ok( $c, entity => $format eq 'full' ?
		    { id          => $id,
		      species     => $species,
		      object_type => $object_type,
		      db_type     => $db_type,
		      chr         => $chr,
		      start       => $start,
		      end         => $end,
		      strand      => $strand,
		    } : {
		      id          => $id,
		      species     => $species,
		      object_type => $object_type,
		      db_type     => $db_type,
		    });
}

sub id_GET {}

__PACKAGE__->meta->make_immutable;

1;
