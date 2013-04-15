package EnsEMBL::REST::View::GFF3;
use Moose;
use namespace::autoclean;
use Bio::EnsEMBL::Utils::IO::GFFSerializer;
use IO::String;

extends 'Catalyst::View';

sub build_gff_serializer {
  my ($self, $c, $output_fh) = @_;
  my $ontology_adaptor = $c->model('Registry')->get_ontology_term_adaptor();  
  my $serializer = Bio::EnsEMBL::Utils::IO::GFFSerializer->new($ontology_adaptor, $output_fh);
  return $serializer;
} 

sub process {
  my ($self, $c, $stash_key) = @_;
  $stash_key ||= 'rest';
  my $output_fh = IO::String->new();
  my $gff = $self->build_gff_serializer($c, $output_fh);
  my $features = $c->stash()->{$stash_key};
  my $slice = $c->stash()->{slice};
  $gff->print_main_header([$slice]);
  while(my $f = shift @{$features}) {
    $gff->print_feature($f);
  }
  $c->res->body(${$output_fh->string_ref()});
  $c->res->headers->header('Content-Type' => 'text/plain');
  return 1;
}

with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;
