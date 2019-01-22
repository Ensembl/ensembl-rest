=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2019] EMBL-European Bioinformatics Institute

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

package EnsEMBL::REST::PreloadRegistry;

#
# We need to preload the registry otherwise it will be reloaded every time a 
# new worker thread is spawned (this will be very slow for the unlucky users).
# plack and starman servers support the -M param to specify a module to load
# before workers are forked, e.g.
#
# starman --listen :9300 -MEnsEMBL::REST::PreloadRegistry ensembl-rest/ensembl_rest.psgi
#

use strict;
use warnings;
use Config::General qw(ParseConfig);
use Bio::EnsEMBL::Registry;

my $config_file = $ENV{ENSEMBL_REST_CONFIG};

unless ($config_file) {
  die "Failed to preload registry: \$ENV{ENSEMBL_REST_CONFIG} is not defined\n";
}

unless (-f $config_file) {
  die "Failed to preload registry: cannot find REST server config at '$config_file'\n";
}

out("Using config file '$config_file'");

my %config = ParseConfig($config_file);
my $reg    = $config{'Model::Registry'};

my @db_servers;

# look for primary db server
if ($reg->{host} && $reg->{user} && $reg->{port}) {
  out("Using db host '$reg->{host}'");
  push @db_servers, {
    -host => $reg->{host}, 
    -user => $reg->{user}, 
    -port => $reg->{port}
  }; 
}

# look for other db servers (e.g. host_n)
for my $key (sort keys %$reg) {
  next unless $key =~ /^host_(\d+)$/;
  my $i = $1;
  if ($reg->{"user_$i"} && $reg->{"port_$i"}) {
    out("Using db host $i '" . $reg->{"host_$i"} . "'");
    push @db_servers, {
      -host => $reg->{"host_$i"}, 
      -user => $reg->{"user_$i"}, 
      -port => $reg->{"port_$i"}
    }; 
  }
}

out('Registering dbs...');

Bio::EnsEMBL::Registry->load_registry_from_multiple_dbs(@db_servers);

out('Done');


sub out {
  my $msg = shift;
  warn sprintf("[%s] %s\n", __PACKAGE__, $msg);
  return;
} 

1;
