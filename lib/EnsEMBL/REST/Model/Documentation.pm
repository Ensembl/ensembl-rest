=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
Copyright [2016-2025] EMBL-European Bioinformatics Institute

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
use YAML::XS;
use Scalar::Util qw/weaken/;
use EnsEMBL::REST::EnsemblModel::Endpoint;

extends 'Catalyst::Model';
with 'Catalyst::Component::InstancePerContext';

has 'context' => (is => 'ro');
has '_parent' => (is => 'ro', weak_ref => 1);

sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  weaken($c);
  return $self->new({ context => $c, _parent => $self, %$self, @args });
}

has '_merged_config' => ( is => 'rw', isa => 'HashRef');

has 'example_expire_time' => ( is => 'ro', isa => 'Int', lazy => 1, default => 3600);

has 'replacements' => ( is => 'ro', isa => 'HashRef', lazy => 1, default => sub {{}});

has 'paths' => ( is => 'ro', isa => 'ArrayRef' );

# in case we want to over-write any documentation conf for the endpoints
# these conf do not get rid of the end-point on the server
has 'conf_replacements' => ( is => 'ro', isa => 'HashRef', lazy => 1, default => sub {{}});

# Overwrite the default behaviours of Hash::Merge described here:
#   http://search.cpan.org/~rehsack/Hash-Merge-0.200/lib/Hash/Merge.pm#BUILT-IN_BEHAVIORS
# Merge only between hash and hash. In other cases, replace the value by the "LEFT_PRECEDENT" method.
# This will allow overwritting of configuration items that have either scalar or array values.
    
Hash::Merge::specify_behavior (
  {
    'SCALAR' => {
      'SCALAR' => sub { $_[0] },
      'ARRAY'  => sub { $_[0] },
      'HASH'   => sub { $_[0] },
    },
    'ARRAY' => {
      'SCALAR' => sub { $_[0] },
      'ARRAY'  => sub { $_[0] },
      'HASH'   => sub { $_[0] }, 
    },
    'HASH' => {
      'SCALAR' => sub { $_[0] },
      'ARRAY'  => sub { $_[0] },
      'HASH'   => sub { Hash::Merge::_merge_hashes( $_[0], $_[1] ) }, 
    },
  }
);

sub merged_config {
  my ($self) = @_;
  my $merged_cfg = $self->_merged_config();
  return $merged_cfg if $merged_cfg;

  my $paths = wrap_array($self->paths());
  my $log = $self->context->log();

  $merged_cfg = {};
  foreach my $path (@{$paths}) {
    my $conf = $self->_find_conf($path);
    foreach my $conf_file (@{$conf}) {
      $log->debug('Processing '.$conf_file) if $log->is_debug();
      my $conf_content = $self->_get_conf_content($conf_file);
      my $conf = Config::General->new(-String => $conf_content);
      my $conf_hash = {$conf->getall()}->{endpoints};
      while(my ($k, $v) = each %{$conf_hash}) {
        $conf_hash->{$k}->{key} = $k;
        $v->{id} = $k;
        my $config_name = 'Controller::' . $conf_hash->{$k}->{group};
        my $controller_config = EnsEMBL::REST->config()->{$config_name};
        $v->{post_size} = $controller_config->{max_post_size} if defined $controller_config->{max_post_size};
        $v->{slice_length} = $controller_config->{max_slice_length} if defined $controller_config->{max_slice_length};
      }
      $merged_cfg = merge($conf_hash, $merged_cfg);
    }
  }
  $self->_merged_config($merged_cfg);
  $self->_parent->_merged_config($merged_cfg);
  return $merged_cfg;
}

sub enrich {
    my ( $self, $endpoint ) = @_;

    my $json = JSON->new();
    $json->pretty(1);
    my $log = $self->context->log;

    # Modify and validate the possible output formats.
    my $outputs = $endpoint->{output};
    $outputs = [$outputs] unless ref($outputs);
    my %outputs_hash = map { lc($_) => 1 } @{$outputs};

    #Add JSONP if available
    if(EnsEMBL::REST->config->{jsonp} && exists $outputs_hash{'json'} && ! exists $outputs_hash{'jsonp'}) {
      push(@{$outputs}, 'jsonp');
      $endpoint->{output} = $outputs;

      #Now add it as a parameter if missing
      if(! exists $endpoint->{params}->{callback}) {
        $endpoint->{params}->{callback} = {
          type => 'String',
          description => 'Name of the callback subroutine to be returned by the requested JSONP response. Required ONLY when using JSONP as the serialisation method. Please see <a href="http://github.com/Ensembl/ensembl-rest/wiki">the user guide</a>.',
          required => 0,
          example => [qw/randomlygeneratedname/]
        };
      }
    }

    my $endpoint_obj = EnsEMBL::REST::EnsemblModel::Endpoint->new(%{$endpoint});

    #Build each output example
    foreach my $id ( keys %{ $endpoint_obj->{examples} } ) {
        my $eg = $endpoint_obj->{examples}->{$id};
        next if $eg->{enriched};
        next if $eg->{disable};
        $eg->{id}  = $id;
        $self->_request_example($endpoint_obj, $eg);
        $eg->{enriched} = 1;
    }

    return $endpoint_obj;
}

sub _request_example {
  my ($self, $endpoint, $eg) = @_;
  my $c = $self->context();
  my $path    = $eg->{path};
  my $capture = $eg->{capture} || [];
  my $params  = $eg->{params} || {};
  $c->request->params($params) if $params;
  $capture = [$capture] unless ref($capture) eq 'ARRAY';
  $eg->{uri} = $path . ( join '/', @{$capture} );
  my $param_string = $self->_hash_to_params($params);
  $eg->{true_root_uri} = $eg->{uri};
  if(! $endpoint->is_post()) {
    $eg->{uri} = $eg->{uri} .'?'. $param_string;
  }

  my ($example_host, $example_uri) = $self->_url($endpoint, $eg, $c);
  $eg->{example}->{host} = $example_host;
  $eg->{example}->{uri} = $example_uri;

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
  my ($self, $path) = @_;
  my $c = $self->context();
  my $log = $c->log();
  $log->debug('Looking for CFGs in the directory '.$path) if $log->is_debug();

  my $conf_replacements = $self->conf_replacements();
  #If path is not absolute then
  if(! File::Spec->file_name_is_absolute($path)) {
    $path = $c->path_to($path);
    $log->debug('Path is now '.$path.' as given path was not absolute') if $log->is_debug();
  }
  my @conf;
  find(sub {
    
    my $full_path =  $File::Find::name;
    if($_ =~ /\.conf$/) {
	if(exists($conf_replacements->{$_}) && defined($conf_replacements->{$_})){
	  $log->debug("Replacement conf file found: $_ will be replaced with $conf_replacements->{$_}");
	  $full_path = $File::Find::dir.File::Spec->catfile('', $conf_replacements->{$_});
	}
	unless (grep {/^$full_path/} @conf) { push(@conf,$full_path); }
    }
  }, $path);
  return [sort @conf];
}

sub _url {
  my ($self, $endpoint, $eg) = @_;
  my $c = $self->context();
  my $host = $c->req->base;
  $host =~ s/\/$//;
  my $uri = $eg->{true_root_uri};
  if(! $endpoint->is_post()) {
    my $req_params = $eg->{params} || {};
    $req_params->{'content-type'} = $eg->{content};
    my $params = $self->_hash_to_params($req_params);
    $uri .= '?'.$params;
  }
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
  $self->context->log->debug('Working with '.$conf_file.' and will perform __VAR()__ replacements');
  my $content = slurp($conf_file);
  my $replacements = $self->replacements();
  foreach my $key (keys %{$replacements}) {
    my $value = $replacements->{$key};
    $content =~ s/__VAR\($key\)__/$value/g;
  }
  return $content;
}

__PACKAGE__->meta->make_immutable;

1;
