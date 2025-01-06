#!/usr/bin/env perl
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
#

use strict;
use warnings;
use Daemon::Control;
use FindBin qw($Bin);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use Fcntl ':mode';

my $root_dir   = $ENV{ENSEMBL_REST_ROOT} || "$Bin/../../";
my $psgi_file  = "$root_dir/configurations/production/ensrest.psgi";
my $starman    = $ENV{ENSEMBL_REST_STARMAN} || 'starman';
my $port       = $ENV{ENSEMBL_REST_PORT} || 5000;
my $workers    = $ENV{ENSEMBL_REST_WORKERS} || 10;
my $backlog    = $ENV{ENSEMBL_REST_BACKLOG} || 1024;
my $status_file= $ENV{ENSEMBL_REST_STATUS} || "$root_dir/ensembl_rest.status";
my $restart_interval = 1;
my $max_requests=$ENV{ENSEMBL_REST_MAX_REQUESTS} || 10000;
my $pid_file   = $ENV{ENSEMBL_REST_PID} || "$root_dir/ensembl_rest.pid";
my $init_config= $ENV{ENSEMBL_INIT_CONFIG} || '~/.bashrc';
my $log_root   = $ENV{ENSEMBL_LOG_ROOT} || "$root_dir/logs";
my $pid_root   = dirname($pid_file);

if ($ARGV[0] =~ /^(start|restart|foreground)$/) {
  ensure_dir_exists($pid_root, 0755, 'PID root');
  ensure_dir_exists($log_root, 0755, 'log root');
}

Daemon::Control->new(
  {
    name         => "Ensembl REST",
    lsb_start    => '$syslog $remote_fs',
    lsb_stop     => '$syslog',
    lsb_sdesc    => 'Ensembl REST server control',
    lsb_desc     => 'Ensembl REST server control',
    stop_signals => [ qw(QUIT TERM TERM INT KILL) ],
    init_config  => $init_config,
    program      => $starman,
    program_args => [ 
      '--backlog',      $backlog,
      '--listen',       ":$port", 
      '--workers',      $workers, 
      '--max-requests', $max_requests,
      '--status-file',  $status_file,
      '--interval',     $restart_interval,
      '-M',             'EnsEMBL::REST::PreloadRegistry',
      '--preload-app',  
      $psgi_file 
    ],
    pid_file     => $pid_file,
  }
)->run;

sub ensure_dir_exists {
  my ($dir, $target_mode, $name) = @_;

  if (! -d $dir) {
    warn "Creating $name directory '$dir'\n";
    make_path($dir, {chmod => $target_mode});
  }

  my $mode = S_IMODE( (stat($dir))[2] );
  if ($mode ne $target_mode) {
    warn "Setting permissions of $name directory '$dir'\n";
    chmod($target_mode, $dir) || die "Failed to set permissions: $!";
  }

  return;
}
