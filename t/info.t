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
use Test::Deep;
use Test::Differences;
use Catalyst::Test ();
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::ApiVersion qw/software_version/;
use Bio::EnsEMBL::Variation::Utils::Constants qw(%OVERLAP_CONSEQUENCES);
use Data::Dumper;

my $test = Bio::EnsEMBL::Test::MultiTestDB->new();
my $dba = $test->get_DBAdaptor('core');

my $multi_test = Bio::EnsEMBL::Test::MultiTestDB->new('multi');
my $compara_dba = $multi_test->get_DBAdaptor('compara');

Catalyst::Test->import('EnsEMBL::REST');
require EnsEMBL::REST;

my $VERSION = software_version();
my $core_schema_version = $dba->get_MetaContainer()->single_value_by_key('schema_version');
$core_schema_version *= 1;

my $compara_schema_version = $compara_dba->get_MetaContainer()->single_value_by_key('schema_version');
$compara_schema_version *= 1;

# info/comparas
is_json_GET(
  '/info/comparas', { comparas => [ { name => 'vertebrates', release => $compara_schema_version} ] }, "Comparas returns 1 DB"
);

# info/data
is_json_GET(
  '/info/data', {releases => [ $core_schema_version ]}, "only release available is $core_schema_version"
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

  my $expected = {
    species => [
      {
        division => 'EnsemblVertebrates',
        name => 'homo_sapiens',
        accession => 'GCA_000001405.9',
        common_name => 'human',
        display_name => 'Human',
        taxon_id => '9606',
        groups => ['core', 'funcgen', 'variation'],
        aliases => [],
        release => $core_schema_version,
        assembly => 'GRCh37',
        strain => 'test_strain',
        strain_collection => 'human'
      }
    ]
  };
  my $expected_hide_strain_info = {
    species => [
      { 
        division => 'EnsemblVertebrates',
        name => 'homo_sapiens',
        accession => 'GCA_000001405.9',
        common_name => 'human',
        display_name => 'Human',
        taxon_id => '9606',
        groups => ['core', 'funcgen', 'variation'],
        aliases => [],
        release => $core_schema_version,
        assembly => 'GRCh37'
      }
    ]
  };
  my $expected_empty_list = {species => [ ]};

  eq_or_diff_data(
    $get_species->('/info/species', 'Checking only DBA available is the test DBA'),
    $expected, 
    "/info/species | Checking only DBA available is the test DBA"
  );
  eq_or_diff_data(
    $get_species->('/info/species?division=EnsemblVertebrates', q{Output is same as /info/species if specified 'EnsemblVertebrates' division}),
    $expected, 
    "/info/species?division=EnsemblVertebrates | Output is same as /info/species if specified 'EnsemblVertebrates' division"
  );
  eq_or_diff_data(
    $get_species->('/info/species?division=ensemblvertebrates', q{Output is same as /info/species if specified 'ensemblvertebrates' division}),
    $expected, 
    "/info/species?division=ensemblvertebrates | Output is same as /info/species if specified 'ensemblvertebrates' division"
  );
  eq_or_diff_data(
    $get_species->('/info/species?division=EnsEMBLvertebrates', q{Output is same as /info/species if specified 'EnsEMBLvertebrates' division}),
    $expected, 
    "/info/species?division=EnsEMBLvertebrates | Output is same as /info/species if specified 'EnsEMBLvertebrates' division"
  );
  eq_or_diff_data(
    $get_species->('/info/species?hide_strain_info=1', q{Output does not have strain and strain_collection info}),
    $expected_hide_strain_info,
    "/info/species?hide_strain_info=1 | Output does not have strain and strain_collection info"
  );
  eq_or_diff_data(
    $get_species->('/info/species?strain_collection=human', q{Output is same as /info/species if specified 'human' strain_collection}),
    $expected,
    "/info/species?strain_collection=human | Output is same as /info/species if specified 'human' strain_collection"
  );
  eq_or_diff_data(
    $get_species->('/info/species?strain_collection=bogus', q{Output is empty list for unknown collection }),
    $expected_empty_list,
    "/info/species?hide_strain_info=1 | Output is empty list"
  );

  is_json_GET('/info/species?division=wibble', $expected_empty_list, 'Bogus division results in no results');
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
  cmp_ok(scalar(keys %{$analysis_json}), '==', 38, 'Ensuring we have the right number of analyses available');
  my %unique_groups = map { $_, 1 } map { @{$_} } values %{$analysis_json};
  eq_or_diff_data(\%unique_groups, {core => 1, funcgen => 1}, 'Checking there is only one group with analyses');

  is_json_GET('/info/analysis/wibble', {}, 'Bogus species means empty hash');
}

# /info/external_dbs/:species
{
  my $external_dbs_json = json_GET('/info/external_dbs/homo_sapiens', 'Get the external dbs hash');
  cmp_ok(scalar(@{$external_dbs_json}), '==', 511, 'Ensuring we have the right number of external_dbs available');
  my $expected = [{ name => 'GO', description => undef, release => undef, display_name => 'GO' }];
  is_json_GET('/info/external_dbs/homo_sapiens?filter=GO', $expected, 'Checking GO filtering works');
  my $xref_external_dbs_json = json_GET('info/external_dbs/homo_sapiens?feature=xref', 'Get the xref external dbs hash');
  is(scalar(@{$xref_external_dbs_json}), 39, 'Ensuring we have the right number of xref external_dbs available');

  action_bad_regex('/info/external_dbs/wibble', qr/Could not fetch adaptor for species .+/, 'Bogus species means error message');
}

# /info/biotypes/:species
{
  my $biotypes_json = json_GET('/info/biotypes/homo_sapiens', 'Get the biotypes hash');
  is(ref($biotypes_json), 'ARRAY', 'Array wanted from endpoint');
  cmp_ok(scalar(@{$biotypes_json}), '==', 12, 'Ensuring we have the right number of biotypes');
  my ($protein_coding) = grep { $_->{biotype} eq 'protein_coding' } @{$biotypes_json};
  my $expected = { biotype => 'protein_coding', groups => ['core'], objects => ['gene', 'transcript']};
  eq_or_diff_data($protein_coding, $expected, 'Checking internal contents of biotype hash as expected');
  action_bad_regex('/info/biotypes/wibble', qr/Could not fetch adaptor for species .+/, 'Bogus species means error message');
}

# /info/biotypes/groups
{
  my $groups_json = json_GET('/info/biotypes/groups', 'Get the list biotype groups');
  is(ref($groups_json), 'ARRAY', 'Array wanted from endpoint');
  cmp_ok(scalar(@{$groups_json}), '==', 2, 'Ensuring we have the right number of biotype groups');
  is(shift @{$groups_json}, 'coding', 'first group is coding');
  is(pop @{$groups_json}, 'snoncoding', 'last group is snoncoding')
}

# /info/biotypes/groups/:group
{
  my $biotypes_json = json_GET('/info/biotypes/groups/coding', 'Get the list of coding biotypes');
  is(ref($biotypes_json), 'ARRAY', 'Array wanted from endpoint');
  cmp_ok(scalar(@{$biotypes_json}), '==', 2, 'Ensuring we have the right number of biotypes of group coding');
  my $biotype = shift @{$biotypes_json};
  is(ref($biotype), 'HASH', 'Biotypes represented by Hashes');
  my $expected = { name => 'protein_coding', biotype_group => 'coding', object_type => 'gene', so_acc => 'SO:0001217', so_term => 'protein_coding_gene'};
  eq_or_diff_data($biotype, $expected, 'Checking internal contents of biotype hash as expected');
  action_bad_regex('/info/biotypes/groups/fake_group', qr/biotypes not found for group/, 'No matches for provided group error');
  action_bad_regex('/info/biotypes/groups/coding/aaa', qr/biotypes not found for group coding and object_type/, 'No matches for provided object_type error');
}

# /info/biotypes/name/:name
{
  action_bad_regex('/info/biotypes/name', qr/Missing mandatory argument/, 'No argument provided means error message');
  my $biotypes_json = json_GET('/info/biotypes/name/protein_coding', 'Get protein_coding biotypes');
  is(ref($biotypes_json), 'ARRAY', 'Array wanted from endpoint');
  cmp_ok(scalar(@{$biotypes_json}), '==', 2, 'Ensuring we have the right number of biotypes of name protein_coding');
  my $biotype = shift @{$biotypes_json};
  is(ref($biotype), 'HASH', 'Biotypes represented by Hashes');
  my $expected = { name => 'protein_coding', biotype_group => 'coding', object_type => 'gene', so_acc => 'SO:0001217', so_term => 'protein_coding_gene' };
  eq_or_diff_data($biotype, $expected, 'Checking internal contents of biotype hash as expected');
  my $biotype_json = json_GET('/info/biotypes/name/protein_coding/gene', 'Get protein_coding gene biotype');
  eq_or_diff_data(shift @{$biotype_json}, $expected, 'Checking internal contents of biotype hash as expected');
  action_bad_regex('/info/biotypes/name/fake_name', qr/biotypes not found for name/, 'No matches for provided name error');
  action_bad_regex('/info/biotypes/name/protein_coding/fake_ot', qr/biotypes not found for name protein_coding and object_type/, 'No matches for provided object_type error');
}

#/info/compara/methods
{
  my $methods_json = json_GET('/info/compara/methods', 'Get the compara methods hash');
  cmp_ok(keys(%{$methods_json}), '==', 10, 'Ensuring we have the right number of compara methods available');
  cmp_deeply(json_GET('/info/compara/methods?class=Homology', 'Get Homology methods'), 
    {'Homology.homology' => bag(qw/ENSEMBL_PROJECTIONS ENSEMBL_PARALOGUES ENSEMBL_ORTHOLOGUES/)}, 
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

#/info/variation/:species
{
  my $variation_json = json_GET('/info/variation/homo_sapiens', 'Get analysis hash');
  cmp_ok(scalar(@{$variation_json}), '==', 8, 'Ensuring we have the right number of sources available');

  # Check with filter
  my $expected = 
    [
      { 
        name => 'dbSNP',
        version => '138',
        description => 'Variants (including SNPs and indels) imported from dbSNP',
        url => 'http://www.ncbi.nlm.nih.gov/projects/SNP/',
        somatic_status => 'mixed',
        data_types => ['variation']
      }
    ];
  cmp_bag(json_GET('/info/variation/homo_sapiens?filter=dbSNP',"Get dbSNP variants"), $expected, 'Checking dbSNP source filtering works');
}

#/info/variation/populations/:species
{
  my $json = json_GET('/info/variation/populations/homo_sapiens', 'GET all populations for given species in variation database');
  cmp_ok(scalar(@{$json}), '==', 42, 'Test that correct number of populations is returned');

  # check with filter
  my $expected = 
    [
      {
        'name' => 'CSHL-HAPMAP:HapMap-CEU',
        'description' => 'Utah residents with Northern and Western European ancestry from the CEPH collection.',
        'size' => '185'
      },
      {
        'name' => 'CSHL-HAPMAP:HapMap-HCB',
        'description' => '45 unrelated Han Chinese in Beijing, China, representing one of the populations studied in the International HapMap project.',
        'size' => '48'
      },
      {
        'name' => 'CSHL-HAPMAP:HapMap-JPT',
        'description' => 'Japanese in Tokyo, Japan.,JPT is one of the 11 populations in HapMap phase 3.',
        'size' => '93'
      },
      {
        'name' => 'CSHL-HAPMAP:HapMap-YRI',
        'description' => 'Yoruba in Ibadan, Nigeria.,YRI is one of the 11 populations in HapMap phase 3.',
        'size' => '185'
      },
      {
        'name' => '1000GENOMES:phase_1_ASW',
        'description' => 'Americans of African Ancestry in SW USA',
        'size' => '61'
      }
    ];
  cmp_bag(json_GET('/info/variation/populations/homo_sapiens?filter=LD',"LD variants"), $expected, 'Checking filtering for LD population works');
}

#/info/variation/populations/:species:/:population_name
{
  my $population_name = "1000GENOMES:phase_1_ASW";
  my $json = json_GET("/info/variation/populations/homo_sapiens/1000GENOMES:phase_1_ASW", 'GET specific population for given species in variation database');
  cmp_ok(scalar(@{$json}), '==', 1, 'Test that one population was returned');
  cmp_ok($json->[0]->{name}, 'eq', $population_name, 'Test that correct population was returned');
  cmp_ok($json->[0]->{size}, '==', 61, 'Test correct population size');
  cmp_ok(scalar(@{$json->[0]->{individuals}}), '==', 61, 'Test that correct number of individuals was returned');
  cmp_ok($json->[0]->{individuals}->[0]->{name}, 'eq', '1000GENOMES:phase_1:NA19625', 'Test first individual name');
  cmp_ok($json->[0]->{individuals}->[0]->{gender}, 'eq', 'Female', 'Test first individual gender');
}

#/info/variation/populations/:species:/:population_name - bad name
{
  my $bad_get = "/info/variation/populations/homo_sapiens/badPopulationName";
  action_bad($bad_get, "Population badPopulationName not found.");
}

#/info/variation/populations/:species:/:population_name - bad_species
{
  my $bad_get = "/info/variation/populations/bad_species/1000GENOMES:phase_1_ASW";
  action_bad($bad_get, 'bad_species is not a valid species name');
}

#/info/variation/populations/:species:/:population_name - species with no population data
{
  my $chicken = Bio::EnsEMBL::Test::MultiTestDB->new("gallus_gallus");
  my $bad_get = "/info/variation/populations/gallus_gallus/1000GENOMES:phase_1_ASW";
  action_bad($bad_get, 'Species gallus_gallus does not have population data');
}

#/info/variation/consequence_types
{
  # Check correct data structure returned
  my $consequence_types_json = json_GET('/info/variation/consequence_types', 'Get the consequence_types hash');
  is(ref($consequence_types_json), 'ARRAY', 'Array wanted from endpoint');

  # Check there are at least 10 consequence_types
  cmp_ok(scalar(@{$consequence_types_json}), '>=', 10, 'Ensuring there are at least 10 consequence_types');

  # Check the number of consequence types match those in the
  # Bio::EnsEMBL::Variation::Utils::Constants qw(%OVERLAP_CONSEQUENCES);
  my $num_consequences = scalar(keys(%OVERLAP_CONSEQUENCES));
  cmp_ok(scalar(@{$consequence_types_json}), '==', $num_consequences, 'Endpoint returns same number of consequence types as Constants.pm');

  my $known_SO_term = 'synonymous_variant';
  my $known_SO_accession = 'SO:0001819';

  # Check that this term exists in the data returned
  # Does the array returned contain an element that has SO_term, SO_accession number above
  my @matched = grep {
                       (
                         ($_->{SO_term} eq $known_SO_term)
                         &&
                         ($_->{SO_accession} eq $known_SO_accession)
                       )
                     } @$consequence_types_json;
  cmp_ok(scalar(@matched), '==', 1, "Get match for known consequence type");

  my $consequence_types_rank_json = json_GET(
    '/info/variation/consequence_types?rank=1',
    'Get the consequence_types with consequence ranking');
  ok($consequence_types_rank_json &&
       @$consequence_types_rank_json[0]->{SO_term} &&
       @$consequence_types_rank_json[0]->{consequence_ranking},
     "Check if returning consequence rankings");
}

done_testing();
