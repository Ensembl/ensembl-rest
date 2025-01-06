# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
# Copyright [2016-2025] EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use warnings;

use Test::More;
use Plack::Middleware::DetectExtension;

my $de = Plack::Middleware::DetectExtension->new();
$de->app(sub {});

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
maps('bed', 'text/x-bed');

empty($_) for qw/gff/;

{
  my $env = { CONTENT_TYPE => 'text/plain', PATH_INFO => '/path.xml', QUERY_STRING => q{} };
  my $env_copy = {%{$env}};
  $de->call($env);
  is_deeply($env_copy, $env, 'Detect extension cannot modify the path as CONTENT_TYPE is set');
}
{
  my $env = { PATH_INFO => '/path.xml', QUERY_STRING => q{content-type=txt/plain} };
  my $env_copy = {%{$env}};
  $de->call($env);
  is_deeply($env_copy, $env, 'Detect extension cannot modify the path as a URL parameter content-type= is set');
}
{
  my $actual_env = { PATH_INFO => '/path.xml', QUERY_STRING => q{} };
  my $expected_env = {PATH_INFO => '/path', CONTENT_TYPE => 'text/xml', QUERY_STRING => q{}};
  $de->call($actual_env);
  is_deeply($actual_env, $expected_env, 'URL should be modified accordingly since we told it to be an XML file');
}

sub maps {
  my ($ext, $type) = @_;
  my ($content_type, $path) = $de->process_path_info('/my/file.'.$ext);
  is(
    $content_type, 
    $type, 
    "Extension '${ext}' maps to '${type}'"
  );
  is($path, '/my/file', "Code correctly removes path extension .${ext} once detected");
}

sub empty {
  my ($ext) = @_;
  my $de = Plack::Middleware::DetectExtension->new();
  ok(! $de->process_path_info('/my/file.'.$ext), "Extension '${ext}' maps to nothing");
} 

done_testing();
