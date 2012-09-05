package EnsEMBL::REST::View::JSONRole;

use Moose::Role;
use namespace::autoclean;

use JSON;

has 'json' => (is => 'ro', isa => 'JSON', default => sub {
  my ($self) = @_;
  my $json = JSON->new();
  $json->pretty(1);
  return $json;
});

1;