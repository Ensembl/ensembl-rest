# Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http=>//www.apache.org/licenses/LICENSE-2.0
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
use Test::Differences;
use Catalyst::Test ();
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');
my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('multi');
Catalyst::Test->import('EnsEMBL::REST');

my $base = '/variation/homo_sapiens';

#Get basic variation summary
  my $id = 'rs142276873';
  my $json = json_GET("$base/$id", 'Variation feature');
  #is(scalar(@$json), 1, '1 variation feature returned');
  my $expected_variation = {source => 'Variants (including SNPs and indels) imported from dbSNP', name => $id, MAF => '0.123049', ambiguity => 'R', var_class => 'SNP', synonyms => [], evidence => ['Multiple_observations','1000Genomes'], ancestral_allele => 'G', most_severe_consequence => 'Intron variant', mappings => [{"assembly_name" => "GRCh37", "location"=>"18:23821095-23821095", "strand" => 1, "start" => 23821095, "end" => 23821095, "seq_region_name" => "18", "coord_system" => "chromosome","allele_string"=>"G/A"}]};
  eq_or_diff($json, $expected_variation, "Checking the result from the variation endpoint");
  
# Get additional genotype information
  $id = 'rs67521280';
  $expected_variation = {source => 'Variants (including SNPs and indels) imported from dbSNP', name => $id, MAF => undef, ambiguity => undef, var_class => 'indel', synonyms => [], evidence => [], ancestral_allele => undef, most_severe_consequence => 'Intergenic variant', mappings => [{"assembly_name" => "GRCh37", "location"=> "11:6303493-6303493", "strand" => 1, "start" => 6303493, "end" => 6303493, "seq_region_name" => "11", "coord_system" => "chromosome","allele_string"=>"-/GT"}] };
  my $expected_genotype = { %{$expected_variation}, 
  genotypes => [{genotype => "GT|GT", gender => "Male", individual => "J. CRAIG VENTER", submission_id => 'ss95559393'}] };
  my $genotype_json = json_GET("$base/$id?genotypes=1", "Genotype info");
  eq_or_diff($genotype_json, $expected_genotype, "Returning genotype information");


# Include population information
  my $expected_pops = { %{$expected_variation},
  populations => [{population => "HUMANGENOME_JCVI:J. Craig Venter",frequency => "1",allele => "GT",allele_count => "2", submission_id => 'ss95559393'}]};
  my $pops_json = json_GET("$base/$id?pops=1", "Population info");
  eq_or_diff($pops_json, $expected_pops, "Returning population information");



done_testing();
