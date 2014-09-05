# Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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

my $multi_test = Bio::EnsEMBL::Test::MultiTestDB->new('multi');
my $compara_dba = $multi_test->get_DBAdaptor('compara');

Catalyst::Test->import('EnsEMBL::REST');
require EnsEMBL::REST;

my $VERSION = software_version();
my $schema_version = $dba->get_MetaContainer()->single_value_by_key('schema_version');
$schema_version *= 1;

# info/comparas
is_json_GET(
  '/info/comparas', { comparas => [ { name => 'multi', release => $schema_version} ] }, "Comparas returns 1 DB"
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

  my $expected = {species => [ { division => 'Ensembl', name => 'homo_sapiens', 'accession' => 'GCA_000001405.9', common_name => 'human', display_name => 'Human', taxon_id => '9606', groups => ['core', 'funcgen', 'variation'], aliases => [], release => $schema_version, assembly => 'GRCh37'} ]};

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
  cmp_ok(scalar(@{$biotypes_json}), '==', 11, 'Ensuring we have the right number of biotypes');
  my ($protein_coding) = grep { $_->{biotype} eq 'protein_coding' } @{$biotypes_json};
  my $expected = { biotype => 'protein_coding', groups => ['core'], objects => ['gene', 'transcript']};
  eq_or_diff_data($protein_coding, $expected, 'Checking internal contents of biotype hash as expected');
  action_bad_regex('/info/biotypes/wibble', qr/Could not fetch adaptor for species .+/, 'Bogus species means error message');
}

#/info/compara/methods
{
  my $methods_json = json_GET('/info/compara/methods', 'Get the compara methods hash');
  cmp_ok(keys(%{$methods_json}), '==', 11, 'Ensuring we have the right number of compara methods available');
  is_json_GET(
    '/info/compara/methods?class=Homology', 
    {'Homology.homology' => [qw/ENSEMBL_PROJECTIONS ENSEMBL_PARALOGUES ENSEMBL_ORTHOLOGUES/]}, 
    'Checking filtering brings back subsets of compara methods'
  );
}

#/info/compara/species_sets/:method
{
  is_json_GET(
    '/info/compara/species_sets/ENSEMBL_PROJECTIONS', 
    [
      { 
        species_set_group => q{}, 
        name => "M.mus patch projections", 
        method => "ENSEMBL_PROJECTIONS", 
        species_set => ["mus_musculus"]
      },
      {
        species_set_group => q{},
        name => "H.sap patch projections",
        method => "ENSEMBL_PROJECTIONS",
        species_set => ["homo_sapiens"]
        },
    ],
    'Checking retrieval of ENSEMBL_PROJECTIONS returns 2 group descriptions'
  );
}

done_testing();
