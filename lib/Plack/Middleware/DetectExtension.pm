=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
Copyright [2016-2017] EMBL-European Bioinformatics Institute

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

#Look for extensions in URLs and decode these to accepted MIME types
#making for a more natural URL e.g. /sequence/id/MYID.fasta or /sequence/id/MYID.json 

#To generate the regex used then invoke this command:
#perl -MRegexp::Assemble -e 'my $ra = Regexp::Assemble->new; $ra->add($_) for qw/json xml yaml jsonp fasta seqxml orthoxml nh nhx phyloxml gff3 txt bed/; print $ra->re, "\n"'

package Plack::Middleware::DetectExtension;
use strict;
use warnings;
use parent qw(Plack::Middleware);
use Plack::Util qw//;
use Plack::Util::Accessor qw/lookup/;
our $EXT_REGEX = qr/(?-xism:(?:(?:(?:(?:(?:orth|phyl)o)?x|ya)m|se(?:qxm|rea))l|msgpack|jsonp?|fasta|gff3|nhx?|bed|txt))/;
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
  bed => 'text/x-bed',
  
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
    my ($content_type, $new_path) = $self->process_path_info($env->{PATH_INFO});
    if($content_type) {
      $env->{CONTENT_TYPE} = $content_type;
      $env->{PATH_INFO} = $new_path;
    }
  }
  $self->app->($env);
}

sub process_path_info {
  my ($self, $path_info) = @_;
  my $lookup = $self->get_lookup();
  my $regex = $self->regex();
  #Search for an ext in the PATH_INFO
  $path_info =~ s/\.($regex)$//;
  my $ext = $1;
  if($ext) {
    my $content_type = $lookup->{$ext};
    return ($content_type, $path_info);
  }
  return;
}

1;
