
requires 'Catalyst';
requires 'Mojolicious', '<= 8.43';
requires 'Catalyst::Devel';

requires 'Catalyst::Runtime';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'Moose';
requires 'namespace::autoclean';
requires 'Config::General'; # This should reflect the config file format you've chosen
                            # See Catalyst::Plugin::ConfigLoader for supported formats

#Ensembl Rest Specific
requires 'Catalyst::Action::REST';
requires 'Catalyst::Component::InstancePerContext';
requires 'Catalyst::View::JSON';
requires 'Catalyst::View::TT';
requires 'JSON::XS';
requires 'JSON';
requires 'YAML::XS';
requires 'YAML::Syck';
requires 'URI::Find';
requires 'Log::Log4perl::Catalyst';
requires 'Hash::Merge';
requires 'Catalyst::Plugin::Cache';
requires 'CHI';
requires 'XML::Simple';
requires 'Readonly';
requires 'Readonly::XS';
requires 'DBD::SQLite';
requires 'List::MoreUtils';
requires 'Try::Tiny';
requires 'Starman';
requires 'Carp::Clan';

# Transient dependencies from Ensembl
requires 'Parse::RecDescent';
requires 'XML::Writer';
requires 'Bio::DB::HTS';

# ENSEMBL IS NOT EXPLICITLY REQUIRED; PLEASE INSTALL ALL ENSEMBL MODULES AS NORMAL
# recommends 'Bio::EnsEMBL::DBSQL::DBAdaptor';
# recommends 'Bio::EnsEMBL::Compara::DBSQL::DBAdaptor';
# recommends 'Bio::EnsEMBL::Variation::DBSQL::DBAdaptor';
# recommends 'Bio::EnsEMBL::Funcgen::DBSQL::DBAdaptor';

# Plack Middleware
recommends 'Plack::Middleware::Assets';
recommends 'Plack::Middleware::ReverseProxy';
recommends 'Plack::Middleware::SizeLimit';
recommends 'Plack::Middleware::CrossOrigin';
recommends 'Plack::Middleware::Deflater';
recommends 'Cache::Memcached';
recommends 'CHI::Driver::Memcached';
recommends 'Template::Stash::XS';
recommends 'DateTime';
recommends 'Server::Starter';
recommends 'Log::Dispatch::FileRotate';
recommends 'Net::Server::SS::PreFork';

#Test requirements
test_requires 'Test::More';
test_requires 'Test::Differences';
test_requires 'Test::JSON';
test_requires 'Test::XML::Simple';
test_requires 'Test::XPath';
test_requires 'Test::Deep';
test_requires 'HTTP::Request::Common';
test_requires 'Plack::Test';
test_requires 'Net::CIDR::Lite';
test_requires 'Test::Time::HiRes';
test_requires 'Test::Warnings';
test_requires 'Devel::Cover';
test_requires 'Devel::Cover::Report::Coveralls';
