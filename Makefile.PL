#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install 1.02;
use Module::Install::Catalyst; # Complain loudly if you don't have
                               # Catalyst::Devel installed or haven't said
                               # 'make dist' to create a standalone tarball.
use Cwd            ();
use File::Basename ();
use File::Copy;

my $default_config = File::Basename::dirname( Cwd::realpath($0) ).'/ensembl_rest.conf.default';
if (-f $default_config) {
	my $new_config = File::Basename::dirname( Cwd::realpath($0) ).'/ensembl_rest.conf';
	copy($default_config, $new_config);
}

my $cpanfile_path = File::Basename::dirname( Cwd::realpath($0) ).'/cpanfile';
do $cpanfile_path;

name 'EnsEMBL-REST';
license 'ensembl';
all_from 'lib/EnsEMBL/REST.pm';

catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
