#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install 1.02;
use Module::Install::Catalyst; # Complain loudly if you don't have
                               # Catalyst::Devel installed or haven't said
                               # 'make dist' to create a standalone tarball.

name 'EnsEMBL-REST';
license 'ensembl';
all_from 'lib/EnsEMBL/REST.pm';

requires 'Catalyst::Runtime' => '5.90015';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'Moose';
requires 'namespace::autoclean';
requires 'Config::General'; # This should reflect the config file format you've chosen
                            # See Catalyst::Plugin::ConfigLoader for supported formats

#Ensembl Rest Specific
requires 'Catalyst::Controller::REST';
requires 'Catalyst::Plugin::SubRequest';
requires 'Catalyst::View::JSON';
requires 'Catalyst::View::TT';
requires 'JSON::XS';
requires 'Log::Log4perl::Catalyst';
requires 'Hash::Merge';
requires 'Catalyst::Plugin::Cache';
requires 'CHI';
requires 'XML::Simple';

# Transient dependencies from Ensembl
requires 'Parse::RecDescent';
requires 'XML::Writer';

# ENSEMBL IS NOT EXPLICITLY REQUIRED; PLEASE INSTALL ALL ENSEMBL MODULES AS NORMAL
# recommends 'Bio::EnsEMBL::DBSQL::DBAdaptor';
# recommends 'Bio::EnsEMBL::Compara::DBSQL::DBAdaptor';
# recommends 'Bio::EnsEMBL::Variation::DBSQL::DBAdaptor';
# recommends 'Bio::EnsEMBL::Funcgen::DBSQL::DBAdaptor';

# Plack Middleware
recommends 'Plack::Middleware::Assets';
recommends 'Plack::Middleware::ReverseProxy';
recommends 'Plack::Middleware::SizeLimit';
recommends 'Plack::Middleware::Throttle';
recommends 'Cache::Memcached';
recommends 'Sereal::Encoder';
recommends 'Data::MessagePack';
recommends 'Template::Stash::XS';


#Test requirements
test_requires 'Test::More' => '0.88';
test_requires 'Test::Differences';
test_requires 'Test::JSON';
test_requires 'Test::XML::Simple';
test_requires 'Test::XPath';
catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
