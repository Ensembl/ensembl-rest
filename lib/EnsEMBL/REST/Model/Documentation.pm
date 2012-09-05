package EnsEMBL::REST::Model::Documentation;
use Moose;
use namespace::autoclean;
use Data::Dumper;
use Bio::EnsEMBL::Utils::Scalar qw/wrap_array/;
use Config::General;
use EnsEMBL::REST;
use File::Find;
use File::Spec;
use Hash::Merge qw/merge/;
use Log::Log4perl;
use JSON;
use YAML qw//;

extends 'Catalyst::Model';

has '_merged_config' => ( is => 'rw', isa => 'HashRef');

has 'log' => ( is => 'ro', isa => 'Log::Log4perl::Logger', lazy => 1, default => sub {
  return Log::Log4perl->get_logger(__PACKAGE__);
});

sub merged_config {
  my ($self, $c) = @_;
  my $merged_cfg = $self->_merged_config();
  return $merged_cfg if $merged_cfg;
  
  my $cfg = EnsEMBL::REST->config()->{Documentation};
  my $paths = wrap_array($cfg->{paths});
  my $log = $self->log();

  $merged_cfg = {};
  foreach my $path (@{$paths}) {
    my $conf = $self->_find_conf($c, $path);
    foreach my $conf_file (@{$conf}) {
      $log->debug('Processing '.$conf_file) if $log->is_debug();
      my $conf = Config::General->new(-ConfigFile => $conf_file);
      my $conf_hash = {$conf->getall()}->{endpoints};
      while(my ($k, $v) = each %{$conf_hash}) {
        $conf_hash->{$k}->{key} = $k;
      }
      $merged_cfg = merge($conf_hash, $merged_cfg);
    }
  }
  $self->_merged_config($merged_cfg);
  return $merged_cfg;
}

sub enrich {
    my ( $self, $endpoint, $c ) = @_;

    my $json = JSON->new();
    $json->pretty(1);
    my $log = $self->log;
    
    #Add JSONP if available
    if(EnsEMBL::REST->config->{jsonp}) {
      
      #Add it as an output
      my $outputs = $endpoint->{output};
      $outputs = [$outputs] unless ref($outputs);
      if(! grep { lc($_) eq 'jsonp'} @{$outputs}) {
        push(@{$outputs}, 'jsonp');
      }
      $endpoint->{output} = $outputs;
      
      #Now add it as a parameter if missing
      if(! exists $endpoint->{params}->{callback}) {
        $endpoint->{params}->{callback} = {
          type => 'String', 
          description => 'Name of the callback to be returned by the requested JSONP. Required ONLY when using JSONP', 
          required => 0,
          example => [qw/randomlygeneratedname/]
        };
      }
    }

    #Build each output example
    foreach my $id ( keys %{ $endpoint->{examples} } ) {
        my $eg = $endpoint->{examples}->{$id};
        next if $eg->{enriched};

        $eg->{id}  = $id; 
        my $path    = $eg->{path};
        my $capture = $eg->{capture} || [];
        my $params  = $eg->{params} || {};
        $params->{'content-type'} = $eg->{content};
        $c->request->params($params) if $params;
        $capture = [$capture] unless ref($capture) eq 'ARRAY';
        $eg->{uri} = $path . ( join '/', @{$capture} );
        my $subreq_res = $c->subreq_res( $eg->{uri}, {}, $params );
        $eg->{response} = $subreq_res->body;
        die join "\n", @{ $c->error } if @{ $c->error };

	      my $param_string = join ';' , map {"$_=$params->{$_}"} keys %$params;
	      $eg->{true_root_uri} = $eg->{uri};
	      $eg->{uri} = $eg->{uri} .'?'. $param_string;
        #     if($c->stash()->{rest}) {
        if ( $eg->{content} eq 'application/json' ) {
            $eg->{response} = $json->encode( decode_json( $eg->{response} ) );
        }

        $self->_perl_example($eg, $c);
        $self->_python_example($eg, $c);
        $self->_ruby_example($eg, $c);
        $self->_curl_example($eg, $c);
        $self->_wget_example($eg, $c);
        
        $eg->{enriched} = 1;
    }

    return;
}

sub get_groups {
    my ($self, $c) = @_;
    my $conf = $self->merged_config($c);
    my %groups;
    while ( my ( $k, $v ) = each %{$conf} ) {
        $groups{ $v->{group} } = [] unless $groups{ $v->{group} };
        push( @{ $groups{ $v->{group} } }, $v );
    }
    while ( my ( $k, $v ) = each %groups ) {
        my $endpoints = $groups{$k};
        my @sorted_endpoints = map { $_->{key} } sort { $a->{endpoint} cmp $b->{endpoint} } @{$endpoints};
        $groups{$k} = \@sorted_endpoints;
    }
    return \%groups;
}

sub _find_conf {
  my ($self, $c, $path) = @_;
  my $log = $self->log();
  $log->debug('Looking for CFGs in the directory '.$path) if $log->is_debug();

  #If path is not absolute then
  if(! File::Spec->file_name_is_absolute($path)) {
    $path = $c->path_to($path);
    $log->debug('Path is now '.$path.' as given path was not absolute') if $log->is_debug();
  }
  my @conf;
  find(sub {
    $self->log->debug($_);
    if($_ =~ /\.conf$/) {
      push(@conf, $File::Find::name);
    }
  }, $path);
  return [sort @conf];
}

sub _perl_example {
  my ($self, $eg, $c) = @_;
  my $tmpl = <<'TMPL';
use strict;
use warnings;

use HTTP::Tiny;

my $http = HTTP::Tiny->new();

my $server = '%s';
my $ext = '%s';
my $response = $http->get($server.$ext, {
  headers => { 'Content-type' => '%s' }
});

die "Failed!\n" unless $response->{success};

print "$response->{status} $response->{reason}\n";

%s
TMPL

  my $print_tmpl = <<'TMPL';
print $response->{content} if length $response->{content};
TMPL

  my $json_tmpl = <<'TMPL';
use JSON;
use Data::Dumper;
if(length $response->{content}) {
  my $hash = decode_json($response->{content});
  local $Data::Dumper::Terse = 1;
  local $Data::Dumper::Indent = 1;
  print Dumper $hash;
  print "\n";
}
TMPL
  my $print_stmt = $eg->{content} eq 'application/json' ? $json_tmpl : $print_tmpl;
  my $code = sprintf($tmpl, $self->_url($eg, $c), $eg->{content}, $print_stmt);
  $eg->{perl} = $code;
  return;
}

sub _python_example {
    my ($self, $eg, $c) = @_;
  my $tmpl = <<'TMPL';
import httplib2, sys

http = httplib2.Http(".cache")

server = "%s"
ext = "%s"
resp, content = http.request(server+ext, method="%s", headers={"Content-Type":"%s"})

if not resp.status == 200:
  print "Invalid response: ", resp.status
  sys.exit()

%s
TMPL

  my $print_tmpl = <<'TMPL';
print content
TMPL

  my $json_tmpl = <<'TMPL';
import json

decoded = json.loads(content)
print repr(decoded)
TMPL
  my $print_stmt = $eg->{content} eq 'application/json' ? $json_tmpl : $print_tmpl;
  my $code = sprintf($tmpl, $self->_url($eg, $c), ($eg->{method}||'GET'), $eg->{content}, $print_stmt);
  $eg->{python} = $code;
  return;
}

sub _ruby_example {
  my ($self, $eg, $c) = @_;
  my $tmpl = <<'TMPL';
require 'net/http'
require 'uri'

server='%s'
get_path = '%s'

url = URI.parse(server)
http = Net::HTTP.new(url.host, url.port)

request = Net::HTTP::Get.new(get_path, {'Content-Type' => '%s'})
response = http.request(request)

if response.code != "200":
  puts "Invalid response: #{response.code}"
  puts response.body
  exit
end

%s
TMPL

  my $print_tmpl = <<'TMPL';
puts response.body
TMPL

  my $json_tmpl = <<'TMPL';
require 'rubygems'
require 'json'
require 'yaml'

result = JSON.parse(response.body)
puts YAML::dump(result)
TMPL
  my $print_stmt = $eg->{content} eq 'application/json' ? $json_tmpl : $print_tmpl;
  my $code = sprintf($tmpl, $self->_url($eg, $c), $eg->{content}, $print_stmt);
  $eg->{ruby} = $code;
  return;
}

sub _curl_example {
  my ($self, $eg, $c) = @_;
  my $code = sprintf(q{curl '%s%s' -H 'Content-type:%s'}."\n", $self->_url($eg, $c), $eg->{content});
  $eg->{curl} = $code;
  return;
}

sub _wget_example {
  my ($self, $eg, $c) = @_;
  my $code = sprintf(q{wget -q --header='Content-type:%s' '%s%s' -O -}."\n", $eg->{content}, $self->_url($eg, $c));
  $eg->{wget} = $code;
  return;
}

sub _url {
  my ($self, $eg, $c) = @_;
  my $host = $c->req->base;
  $host =~ s/\/$//;
  my $uri = $eg->{true_root_uri};
  my $req_params = $eg->{params} || {};
  # my @keys = keys %{$req_params};
  # my $params = join(q{;}, map {} )
  my $params = join(q{;}, map { $_.q{=}.$req_params->{$_} } keys %{$req_params});
  $uri .= ('?'.$params) if $params;
  return ($host, $uri);
}

__PACKAGE__->meta->make_immutable;

1;
