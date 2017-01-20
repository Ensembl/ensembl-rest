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

package Catalyst::Script::EnsemblTest;

use Moose;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;
use Bio::EnsEMBL::Test::MultiTestDB;

extends 'Catalyst::Script::Server';

has 'curr_dir' => (
  isa => 'Str',
  is => 'ro',
  lazy => 1,
  default => sub {
    my $dirname = dirname(__FILE__);
    my $up = File::Spec->updir();
    #So the path is something like
    # /path/to/app/lib/Catalyst/Script/../../../t/
    return abs_path(File::Spec->catdir($dirname, $up, $up, $up, 't'));
  },
);

has 'multi_test_db_config' => (
  isa => 'HashRef',
  is => 'ro',
  lazy => 1,
  default => sub {
    my ($self) = @_;
    my $dir = $self->curr_dir();
    return Bio::EnsEMBL::Test::MultiTestDB->get_db_conf($dir);
  }
);

has 'multi_test_dbs' => (
  isa => 'HashRef[Bio::EnsEMBL::Test::MultiTestDB]',
  is => 'ro',
  lazy => 1,
  default => sub {
    my ($self) = @_;
    my $config = $self->multi_test_db_config();
    my $dir = $self->curr_dir();
    my %dbs;
    foreach my $species (keys %{$config->{databases}}) {
      my $multi = Bio::EnsEMBL::Test::MultiTestDB->new($species, $dir);
      $dbs{$species} = $multi;
    }
    return \%dbs;
  },
);

#Load the DBs. Let normal desctruction clean them up
before 'run' => sub {
  my ($self) = @_;
  $self->multi_test_dbs();
};

__PACKAGE__->meta->make_immutable;
1;
 
=head1 NAME
 
Catalyst::Script::EnsemblTest - Ensembl Catalyst test server
 
=head1 SYNOPSIS
 
 ensembl_rest_test_server.pl [options]
 
 Options:
   -d     --debug          force debug mode
   -f     --fork           handle each request in a new process
                      (defaults to false)
          --help           display this help and exits
   -h     --host           host (defaults to all)
   -p     --port           port (defaults to 3000)
   -k     --keepalive      enable keep-alive connections
   -r     --restart        restart when files get modified
                       (defaults to false)
   --rd   --restart_delay  delay between file checks
                      (ignored if you have Linux::Inotify2 installed)
   --rr   --restart_regex  regex match files that trigger
                      a restart when modified
                      (defaults to '\.yml$|\.yaml$|\.conf|\.pm$')
   --rdir --restart_directory  the directory to search for
                      modified files, can be set multiple times
                      (defaults to '[SCRIPT_DIR]/..')
   --sym  --follow_symlinks   follow symlinks in search directories
                      (defaults to false. this is a no-op on Win32)
   --bg   --background        run the process in the background
   --pid  --pidfile           specify filename for pid file
 
 See also:
   perldoc Catalyst::Manual
   perldoc Catalyst::Manual::Intro
 
=head1 DESCRIPTION
 
Run a Catalyst test server for this application. Unlike other scripts
this will create all test databases held in t/test-genome-DBs offering
a fully functional test environment for you to inspect the test
DBs with.
 
=head1 SEE ALSO
 
L<Catalyst::ScriptRunner>
 
=cut
