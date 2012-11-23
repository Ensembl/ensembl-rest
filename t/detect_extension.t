use strict;
use warnings;

use Test::More;
use Plack::Middleware::DetectExtension;

maps('txt', 'text/plain');
maps('xml', 'text/xml');
maps('json', 'application/json');
maps('jsonp', 'text/javascript');
maps('yaml', 'text/x-yaml');
maps('seqxml', 'text/x-seqxml+xml');
maps('orthoxml', 'text/x-orthoxml+xml');
maps('phyloxml', 'text/x-phyloxml+xml');
maps('nh', 'text/x-nh');
maps('fasta', 'text/x-fasta');
maps('gff3', 'text/x-gff3');
maps('sereal', 'application/x-sereal');
maps('msgpack', 'application/x-msgpack');

empty($_) for qw/gff/;

sub maps {
  my ($ext, $type) = @_;
  my $de = Plack::Middleware::DetectExtension->new();
  is(
    $de->process_path_info('/my/file.'.$ext), 
    $type, 
    "Extension '${ext}' maps to '${type}'"
  );
}

sub empty {
  my ($ext) = @_;
  my $de = Plack::Middleware::DetectExtension->new();
  ok(! $de->process_path_info('/my/file.'.$ext), "Extension '${ext}' maps to nothing");
} 

done_testing();