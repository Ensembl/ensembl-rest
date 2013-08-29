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
use Bio::EnsEMBL::ApiVersion qw/software_version/;
use Test::Differences;

my $test = Bio::EnsEMBL::Test::MultiTestDB->new();
my $dba = $test->get_DBAdaptor('core');
Catalyst::Test->import('EnsEMBL::REST');
require EnsEMBL::REST;

my $VERSION = software_version();
my $schema_version = $dba->get_MetaContainer()->single_value_by_key('schema_version');
$schema_version *= 1;

# info/comparas
is_json_GET(
  '/info/comparas', { comparas => [] }, "is empty"
);

# info/data
is_json_GET(
  '/info/data', {releases => [ $schema_version ]}, "only release available is $schema_version"
);

# /info/ping
is_json_GET(
  '/info/ping', { ping => 1 }, "ping responds"
);

# info/species
{
  my $get_species = sub {
    my ($url, $msg) = @_;
    my $info_species = json_GET($url, $msg);
    foreach my $species (@{$info_species->{species}}) {
      $species->{groups} = [sort @{$species->{groups}}];
    }
    return $info_species;
  };

  my $expected = {species => [ { division => 'Ensembl', name => 'homo_sapiens', groups => ['core', 'variation'], aliases => [], release => $schema_version} ]};

  eq_or_diff_data(
    $get_species->('/info/species', 'Checking only DBA available is the test DBA'), $expected, 
    "/info/species | Checking only DBA available is the test DBA");
  eq_or_diff_data(
    $get_species->('/info/species?division=Ensembl', q{Output is same as /info/species if specified 'Ensembl' division}), $expected, 
    "/info/species?division=Ensembl | Output is same as /info/species if specified 'Ensembl' division");
  eq_or_diff_data(
    $get_species->('/info/species?division=ensembl', q{Output is same as /info/species if specified 'ensembl' division}), $expected, 
    "/info/species?division=ensembl | Output is same as /info/species if specified 'ensembl' division");
  eq_or_diff_data(
    $get_species->('/info/species?division=EnsEMBL', q{Output is same as /info/species if specified 'EnsEMBL' division}), $expected, 
    "/info/species?division=EnsEMBL | Output is same as /info/species if specified 'EnsEMBL' division");

  is_json_GET('/info/species?division=wibble', { species => [] }, 'Bogus division results in no results');
}

# /info/software
is_json_GET(
  '/info/software', { release => $VERSION }, "software reports current version $VERSION"
);

# /info/rest
is_json_GET(
  '/info/rest', { release => $EnsEMBL::REST::VERSION }, "rest current version is $EnsEMBL::REST::VERSION"
);

# /info/analysis/:species
{
  my $analysis_json = json_GET('/info/analysis/homo_sapiens', 'Get analysis hash');
  cmp_ok(scalar(keys %{$analysis_json}), '==', 32, 'Ensuring we have the right number of analyses available');
  my %unique_groups = map { $_, 1 } map { @{$_} } values %{$analysis_json};
  eq_or_diff_data(\%unique_groups, {core => 1}, 'Checking there is only one group with analyses');

  is_json_GET('/info/analysis/wibble', {}, 'Bogus species means empty hash');
}

# /info/external_dbs/:species
{
  my $external_dbs_json = json_GET('/info/external_dbs/homo_sapiens', 'Get the external dbs hash');
  cmp_ok(scalar(@{$external_dbs_json}), '==', 510, 'Ensuring we have the right number of external_dbs available');
  my $expected = [{ name => 'GO', description => undef, release => undef, display_name => 'GO' }];
  is_json_GET('/info/external_dbs/homo_sapiens?filter=GO', $expected, 'Checking GO filtering works');

  action_bad_regex('/info/external_dbs/wibble', qr/Could not fetch adaptor for species .+/, 'Bogus species means error message');
}

# /info/biotypes/:species
{
  my $biotypes_json = json_GET('/info/biotypes/homo_sapiens', 'Get the external dbs hash');
  is(ref($biotypes_json), 'ARRAY', 'Array wanted from endpoint');
  cmp_ok(scalar(@{$biotypes_json}), '==', 20, 'Ensuring we have the right number of biotypes');
  my ($protein_coding) = grep { $_->{biotype} eq 'protein_coding' } @{$biotypes_json};
  my $expected = { biotype => 'protein_coding', groups => ['core'], objects => ['gene', 'transcript']}
  eq_or_diff_data();
  action_bad_regex('/info/biotypes/wibble', qr/Could not fetch adaptor for species .+/, 'Bogus species means error message');
}

done_testing();
