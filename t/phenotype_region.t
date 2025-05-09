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

use JSON;
use Test::More;
use Test::Differences;
use Test::Deep;
use Catalyst::Test();
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');
my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('multi');
Catalyst::Test->import('EnsEMBL::REST');


my $base = '/phenotype/region/homo_sapiens';

my $var_region = '13:86442400:86442410';

#Null based queries
{
  my $region = '6:1000000..2000000';
  my $msg = "wibble is not a valid object type, valid types are: Gene, QTL, RegulatoryFeature, StructuralVariation, SupportingStructuralVariation, Variation";
  action_bad_regex("$base/$region?feature_type=wibble", qr/wibble/, $msg);
}


#Get Variation phenotype features overlapping
{
  my $expected = 1;

  my $expected_data = [
          {
            "id" => "rs2299299",
            "phenotype_associations" =>
            [
              {
               "source" => "DGVa",
               "ontology_accessions" => ["Orphanet:130"],
               "location" => "13:86442404-86442404",
               "description" => "BRUGADA SYNDROME",
               "attributes" =>
               {
                "p_value" => "2.00e-7"
               },
              }
            ]
          }
        ];

  my $json = json_GET("$base/$var_region?feature_type=Variation", '1 Variation with phenotype feature associated from chr 13');
  is(scalar(@{$json}), $expected, 'Variation with phenotype association found in the region');
  cmp_bag($json, $expected_data, "Checking the result content from the phenotype/region REST call");
}

# Get the light result version (only phenotypes)
{
  my $expected = 1;

  my $expected_data = [
          {
            "id" => "rs2299299",
            "phenotype_associations" =>
            [
              {
               "ontology_accessions" => ["Orphanet:130"],
               "description" => "BRUGADA SYNDROME"
              }
            ]
          }
        ];

  my $json = json_GET("$base/$var_region?feature_type=Variation;only_phenotypes=1", '1 Variation with phenotype feature associated from chr 13 - light results');
  is(scalar(@{$json}), $expected, 'Variation with phenotype association found in the region - light result');
  cmp_bag($json, $expected_data, "Checking the result content from the phenotype/region REST call - light result");
}


#Get Gene phenotype features overlapping
{
  my $region = '6:1312670:1315000';
  my $expected = 1;
  my $expected_asso = 2;
  my $json = json_GET("$base/$region?feature_type=Gene", '1 Gene with 2 phenotype feature associated from chr 6');
  is(scalar(@{$json}), $expected, 'Gene with phenotype association in the region');
  my $phe_asso = $json->[0]->{'phenotype_associations'};
  is(scalar(@{$phe_asso}), $expected_asso, '2 phenotype associations with the gene in the region');
  my $phe_2nd = $phe_asso->[1];
  my $expected_mim = '119570';
  is ($phe_2nd->{attributes}->{MIM}, $expected_mim, '2nd phenotype has expected minimal attributes');
}

#Get Gene phenotype features and include review_status, pubmed, submitters
{
  my $region = '6:1312670:1315000';
  my $expected_json = [ {
	'phenotype_associations' => [
	{
		'source' => 'GOA',
		'location' => '6:1312675-1314992',
		'description' => 'positive regulation of transcription from RNA polymerase II promoter',
		'attributes' => {
			'external_reference' => 'PMID:8626802'
		}
	},
	{
		'source' => 'GOA',
		'ontology_accessions' => ['GO:0060023'],
		'location' => '6:1312675-1314992',
		'description' => 'soft palate development',
		'attributes' => {
			'review_status' => 'no assertion criteria provided',
			'MIM' => '119570',
			'submitter_names' => ['OMIM', 'Illumina'],
			'external_reference' => 'PMID:8626802',
			'pubmed_ids' => ['PMID:1313972', 'PMID:1319114', 'PMID:1328889']
		}
	}],
	'id' => 'ENSG00000137273'
    }];
  my $json = json_GET("$base/$region?feature_type=Gene;include_review_status=1;include_pubmed_id=1;include_submitter=1;", '1 Gene with 2 phenotype feature associated from chr 6 and include phenotype feature attributes');
  cmp_bag ($json, $expected_json, 'compare deeply and 2nd phenotype has expected included attributes');
}


done_testing();
