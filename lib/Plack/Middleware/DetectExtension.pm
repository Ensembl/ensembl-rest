#Look for extensions in URLs and decode these to accepted MIME types
#making for a more natural URL e.g. /sequence/id/MYID.fasta or /sequence/id/MYID.json 

#To generate the regex used then invoke this command:
#perl -MRegexp::Assemble -e 'my $ra = Regexp::Assemble->new; $ra->add($_) for qw/json xml yaml jsonp fasta seqxml orthoxml nh nhx phyloxml gff3 txt/; print $ra->re, "\n"'

package Plack::Middleware::DetectExtension;
use strict;
use warnings;
use parent qw(Plack::Middleware);
use Plack::Util qw//;
use Plack::Util::Accessor qw/lookup/;
our $EXT_REGEX = qr/(?^:(?:(?:(?:(?:orth|phyl)o|seq)?x|ya)ml|jsonp?|fasta|gff3|nhx?|txt))/;
our %LOOKUP = (
  #Basic exts
  json => 'application/json',
  xml => 'text/xml',
  yaml => 'text/x-yaml',
  jsonp => 'text/javascript',
  txt => 'text/plain',
  
  #Seq exts
  fasta => 'text/x-fasta',
  seqxml => 'text/x-seqxml+xml',
  
  #Feature exts
  gff3 => 'text/x-gff3',
  
  #Orthologs exts
  orthoxml => 'text/x-orthoxml+xml',
  
  #Tree exts
  nh => 'text/x-nh',
  nhx => 'text/x-nhx',
  phyloxml => 'text/x-phyloxml+xml',
);

sub get_lookup {
  my ($self) = @_;
  return \%LOOKUP;
}

sub regex {
  my ($self) = @_;
  return $EXT_REGEX;
}

sub call {
  my ($self, $env) = @_;
  
  #Only process if content-type header was not set and if not in the query params then sniff away
  if(!$env->{CONTENT_TYPE} && $env->{QUERY_STRING} !~ /content-type=/i) {
    my $lookup = $self->get_lookup();
    my $regex = $self->regex();
    #Search for an ext in the PATH_INFO
    $env->{PATH_INFO} =~ s/\.($regex)$//;
    my $ext = $1;
    if($ext) {
      my $content_type = $lookup->{$ext};
      $env->{CONTENT_TYPE} = $content_type;
      #We do *not* process REQUEST_URI: Plack spec says we shouldn't 
    }
  }
  
  $self->app->($env);
};

1;