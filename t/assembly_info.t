use strict;
use warnings;

BEGIN {
  use FindBin qw/$Bin/;
  use lib "$Bin/lib";
  use RestHelper;
  $ENV{CATALYST_CONFIG} = "$Bin/../ensembl_rest_testing.conf";
  $ENV{ENS_REST_LOG4PERL} = "$Bin/../log4perl_testing.conf";
}

use Test::More;
use Catalyst::Test ();
use Bio::EnsEMBL::Test::MultiTestDB;

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new();
Catalyst::Test->import('EnsEMBL::REST');

my $schema_build = $dba->get_DBAdaptor('core')->_get_schema_build();

is_json_GET(
  '/assembly/info/homo_sapiens',
  { 
    'assembly.name' => 'GRCh37.p8', 
    'assembly.date' => '2009-02', 
    top_level_seq_region_names => [qw/6 X/],
    karyotype => [qw/6 X/],
    'genebuild.start_date' => "2010-07-Ensembl",
    'genebuild.initial_release_date' => "2011-04",
    schema_build => $schema_build,
    'genebuild.last_geneset_update' => "2012-10",
    'genebuild.method' => "full_genebuild",
    coord_system_versions => [ '', qw/GRCh37 NCBI36 NCBI34 NCBI35/ ],
    default_coord_system_version => 'GRCh37',
  },
  'Checking output of info'
);

is_json_GET(
  '/assembly/info/homo_sapiens/6',
  {assembly_exception_type => 'REF', coordinate_system => 'chromosome', is_chromosome => 1, length => 171115067 },
  'Checking info of region 6 matches expected'
);

action_bad('/assembly/info/homo_sapiens/wibble', 'Checking a bogus region results in no information');

done_testing();
