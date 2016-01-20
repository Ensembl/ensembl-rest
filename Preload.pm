=head1 LICENSE
Copyright [2009-2014] EMBL-European Bioinformatics Institute
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
# plackup --port 5000 -MEnsEMBL::REST::PreloadRegistry ensembl-rest/ensembl_rest.psgi
#

use strict;
use Config::General qw(ParseConfig);
use Bio::EnsEMBL::LookUp::LocalLookUp;

my $root = $ENV{ENSEMBL_REST_SERVER_ROOT};

unless ($root) {
  die "Failed to preload registry: \$ENV{ENSEMBL_REST_SERVER_ROOT} is not defined\n";
}

my $conf_file = "$root/ensembl-rest/ensembl_rest.conf";

unless (-f $conf_file) {
  die "Failed to preload registry: cannot find REST server config at $conf_file\n";
}

my %config = ParseConfig($conf_file);
my $reg    = $config{'Model::Registry'};

warn "\n[EnsEMBL::REST::PreloadRegistry] Registering dbs...\n";

Bio::EnsEMBL::LookUp::LocalLookUp->register_all_dbs(
  $reg->{host},
  $reg->{port},
  $reg->{user},
);

warn "[EnsEMBL::REST::PreloadRegistry] Done\n";

1;
Status API Training Shop Blog About Pricing
© 2015 GitHub, Inc. Terms Privacy Security Contact Help
