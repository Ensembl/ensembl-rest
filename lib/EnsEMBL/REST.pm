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

=pod

=head1 NAME

EnsEMBL::REST - A RESTful API for the access of data from Ensembl and Ensembl compatible resources

=head1 AUTHOR

The EnsEMBL Group - http://www.ensembl.org/Help/Contact

=cut

package EnsEMBL::REST;
use Moose;
use HTML::Entities;
use URI::Escape qw{ uri_escape_utf8 };
use namespace::autoclean;
use Log::Log4perl::Catalyst;
use EnsEMBL::REST::Types;

use 5.010_001;

extends 'Catalyst';
BEGIN { extends 'Catalyst::Controller::REST' }

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory
#     SubRequest: performs subrequests which we need for the doc pages
#          Cache: Perform in-application caching

  # -Debug
use Catalyst qw/
  ConfigLoader
  Static::Simple
  Cache
/;


our $VERSION = '15.11';

# Configure the application.
#
# Note that settings in ensembl_rest.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
  name => 'EnsEMBL::REST',
  # Disable deprecated behavior needed by old applications
  disable_component_resolution_regex_fallback => 1,

  #Allow key = [val] to become an array
  'Plugin::ConfigLoader' => {
    driver => {
      General => {-ForceArray => 1},
    },
  },
);

# Start the application
my $log4perl_conf = $ENV{ENS_REST_LOG4PERL}|| 'log4perl.conf';
if(-f $log4perl_conf) {
  __PACKAGE__->log(Log::Log4perl::Catalyst->new($log4perl_conf));
}
else {
  __PACKAGE__->log(Log::Log4perl::Catalyst->new());
}
__PACKAGE__->setup();

__PACKAGE__->config->{'custom-error-message'}->{'view-name'}         = 'TT';
__PACKAGE__->config->{'custom-error-message'}->{'error-template'}    = 'error.tt';


#HACK but it works
sub turn_on_config_serialisers {
  my ($class, $package) = @_;
  if($class->config->{jsonp}) {
    $package->config(
      map => {
        'text/javascript'     => 'JSONP',
      }
    );
  }

## Only add a default for text/html if it is not already set by the controller
  if(!$package->config->{map}->{'text/html'}) {
    $package->config(default => 'text/html');
    $package->config(
      map => {
        'text/html' => 'YAML::HTML'
      }
    );
  }

  return;
}


## Intercept default error page
## Page not found is dealt with in Root.pm, this deals with mistyped urls and replaces the default 'Please come back later' page
sub finalize_error {
  my $c = shift;
  my $config = $c->config->{'custom-error-message'};
  
  # in debug mode return the original "page" 
  if ( $c->debug ) {
    $c->maybe::next::method;
    return;
  }
  
  # create error string out of error array
  my $error = join '<br/> ', map { encode_entities($_) } @{ $c->error };
  $error ||= 'No output';

  # render the template
  my $action_name = $c->action->reverse;
  $c->stash->{'finalize_error'} = $action_name.': '.$error;
  $c->response->content_type(
    $config->{'content-type'} || 'text/html; charset=utf-8' );
  my $view_name = $config->{'view-name'} || 'TT';
  eval {
    $c->response->body($c->view($view_name)->render($c,
      $config->{'error-template'} || 'error.tt' ));
  };
  if ($@) {
    $c->log->error($@);
    $c->maybe::next::method;
  }
  
  my $response_status = $config->{'response-status'};
  $response_status = 500 if not defined $response_status;
  $c->response->status($response_status);
}


1;
