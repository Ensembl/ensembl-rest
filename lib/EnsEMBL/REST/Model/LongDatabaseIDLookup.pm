package EnsEMBL::REST::Model::LongDatabaseIDLookup;

use Moose;
use namespace::autoclean;

extends 'EnsEMBL::REST::Model::DatabaseIDLookup';

sub build_long_lookup {
  return 1;
}

1;