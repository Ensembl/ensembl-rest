package EnsEMBL::REST::Model::Documentation;
use Moose;
use namespace::autoclean;
use Data::Dumper;
use Bio::EnsEMBL::Utils::Scalar qw/wrap_array/;
use Bio::EnsEMBL::Utils::IO qw/slurp/;
use Config::General;
require EnsEMBL::REST;
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

has 'example_expire_time' => ( is => 'ro', isa => 'Int', lazy => 1, default => sub {
  return EnsEMBL::REST->config()->{Documentation}->{example_expire_time} || 3600;
});

has 'replacements' => ( is => 'ro', isa => 'HashRef', lazy => 1, default => sub {
  return EnsEMBL::REST->config()->{Documentation}->{replacements} || {};
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
      my $conf_content = $self->_get_conf_content($conf_file);
      my $conf = Config::General->new(-String => $conf_content);
      my $conf_hash = {$conf->getall()}->{endpoints};
      while(my ($k, $v) = each %{$conf_hash}) {
        $conf_hash->{$k}->{key} = $k;
        $v->{id} = $k;
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
        next if $eg->{disable};
        $eg->{id}  = $id; 
        $self->_request_example($endpoint, $eg, $c);
        $eg->{enriched} = 1;
    }

    return;
}

sub _request_example {
  my ($self, $endpoint, $eg, $c) = @_;
  
  my $path    = $eg->{path};
  my $capture = $eg->{capture} || [];
  my $params  = $eg->{params} || {};
  $params->{'content-type'} = $eg->{content};
  $c->request->params($params) if $params;
  $capture = [$capture] unless ref($capture) eq 'ARRAY';
  $eg->{uri} = $path . ( join '/', @{$capture} );
  my $param_string = $self->_hash_to_params($params);
  $eg->{true_root_uri} = $eg->{uri};
  $eg->{uri} = $eg->{uri} .'?'. $param_string;
  
  my ($example_host, $example_uri) = $self->_url($eg, $c);
  $eg->{example}->{host} = $example_host;
  $eg->{example}->{uri} = $example_uri;
  
  my $cache = $c->cache;
  my $key = $endpoint->{key}.'++'.$eg->{id};
  
  $eg->{response} = $cache->compute($key, { expires_in => $self->example_expire_time() }, sub {
    my $json = JSON->new();
    $json->pretty(1);
    my $subreq_res = $c->subreq_res( $eg->{true_root_uri}, {}, $params );
    my $sub_result = $subreq_res->body;
    $c->log()->warn(join ("\n", @{ $c->error })) if @{ $c->error };
    if ( $eg->{content} eq 'application/json' ) {
      $sub_result = $json->encode( decode_json( $sub_result  ) );
    }
    return $sub_result;
  });
  
  return;
}

sub get_groups {
    my ($self, $c) = @_;
    my $conf = $self->merged_config($c);
    my %groups;
    while ( my ( $k, $v ) = each %{$conf} ) {
        next if $v->{disable};
        $groups{ $v->{group} } = [] unless $groups{ $v->{group} };
        push( @{ $groups{ $v->{group} } }, $v );
    }
    my @kill_list;
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

sub _url {
  my ($self, $eg, $c) = @_;
  my $host = $c->req->base;
  $host =~ s/\/$//;
  my $uri = $eg->{true_root_uri};
  my $req_params = $eg->{params} || {};
  my $params = $self->_hash_to_params($req_params);
  $uri .= ('?'.$params) if $params;
  return ($host, $uri);
}

sub _hash_to_params {
  my ($self, $hash) = @_;
  my @params;
  foreach my $key (keys %{$hash}) {
    my $value = $hash->{$key};
    my @values = (ref($value) eq 'ARRAY') ? @{$value} : $value;
    foreach my $v (@values) {
      push(@params, "${key}=${v}");
    }
  }
  return join(q{;}, @params);
}

sub _get_conf_content {
  my ($self, $conf_file) = @_;
  $self->log->debug('Working with '.$conf_file.' and will perform __VAR()__ replacements');
  my $content = slurp($conf_file);
  my $replacements = $self->replacements();
  foreach my $key (%{$replacements}) {
    my $value = $replacements->{$key};
    $content =~ s/__VAR\($key\)__/$value/g;
  }
  return $content;
}

__PACKAGE__->meta->make_immutable;

1;
