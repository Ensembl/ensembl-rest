=pod

=head1 NAME

EnsEMBL::REST - A RESTful API for the access of data from Ensembl and Ensembl compatible resources

=head1 AUTHOR

The EnsEMBL Group - helpdesk@ensembl.org

=HEAD1 LICENSE

Copyright © 1999-2012 The European Bioinformatics Institute and Genome Research Limited, and others. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1). Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2). Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer 
    in the documentation and/or other materials provided with the distribution.

3). The name "Ensembl" must not be used to endorse or promote products derived from this software without prior written permission. 
    For written permission, please contact helpdesk@ensembl.org

4). Products derived from this software may not be called "Ensembl" nor may "Ensembl" appear in their names without prior written 
    permission of the Ensembl developers.

5). Redistributions in any form whatsoever must retain the following acknowledgement:
            "This product includes software developed by Ensembl (http://www.ensembl.org/)."

THIS SOFTWARE IS PROVIDED BY THE ENSEMBL GROUP "AS IS" AND ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
SHALL THE ENSEMBL GROUP OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
POSSIBILITY OF SUCH DAMAGE.

=cut

package EnsEMBL::REST;
use Moose;
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
  SubRequest
  Cache
/;


our $VERSION = '1.4.4';

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
  
  if($class->config->{sereal}) {
    $package->config(
      map => {
        'application/x-sereal'     => 'Sereal',
      }
    );
  }
  
  if($class->config->{msgpack}) {
    $package->config(
      map => {
        'application/x-msgpack' => 'MessagePack'
      }
    );
  }
  return;
}

1;
