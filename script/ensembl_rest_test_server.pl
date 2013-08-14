#!/usr/bin/env perl

BEGIN {
  $ENV{CATALYST_SCRIPT_GEN} = 40;
  
  use FindBin qw/$Bin/;
  use lib "$Bin/lib";
  $ENV{CATALYST_CONFIG} = "$Bin/../ensembl_rest_testing.conf";
  # $ENV{ENS_REST_LOG4PERL} = "$Bin/../log4perl_testing.conf";
}

$SIG{INT} = sub {
  #Capture normal SIG INTs to force the cleaning up of the databases. For
  #some reason Catalyst/PSGI/Something is very good at ignoring
  #DEMOLISH blocks
  my $code = Catalyst::Script::EnsemblTest->new(application_name => 'EnsEMBL::REST');
  exit();
};

use Catalyst::ScriptRunner;
Catalyst::ScriptRunner->run('EnsEMBL::REST', 'EnsemblTest');

1;

=head1 NAME

ensembl_rest_test_server.pl - Ensembl REST Test Server

=head1 SYNOPSIS

ensembl_rest_server.pl [options]

   -d --debug           force debug mode
   -f --fork            handle each request in a new process
                        (defaults to false)
   -? --help            display this help and exits
   -h --host            host (defaults to all)
   -p --port            port (defaults to 3000)
   -k --keepalive       enable keep-alive connections
   -r --restart         restart when files get modified
                        (defaults to false)
   -rd --restart_delay  delay between file checks
                        (ignored if you have Linux::Inotify2 installed)
   -rr --restart_regex  regex match files that trigger
                        a restart when modified
                        (defaults to '\.yml$|\.yaml$|\.conf|\.pm$')
   --restart_directory  the directory to search for
                        modified files, can be set multiple times
                        (defaults to '[SCRIPT_DIR]/..')
   --follow_symlinks    follow symlinks in search directories
                        (defaults to false. this is a no-op on Win32)
   --background         run the process in the background
   --pidfile            specify filename for pid file

 See also:
   perldoc Catalyst::Manual
   perldoc Catalyst::Manual::Intro

=head1 DESCRIPTION

Run a Catalyst Testserver for this application.

=head1 AUTHORS

Catalyst Contributors, see Catalyst.pm

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

