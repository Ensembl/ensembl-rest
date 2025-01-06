# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
# Copyright [2016-2025] EMBL-European Bioinformatics Institute
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
use Test::Deep;
use Catalyst::Test ();
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;
use Storable qw(dclone);
use JSON;
my $dba = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');
my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('multi');
Catalyst::Test->import('EnsEMBL::REST');

my $base = '/variation/homo_sapiens';

#Get basic variation summary
  my $id = 'rs142276873';
  my $json = json_GET("$base/$id", 'Variation feature');
  #is(scalar(@$json), 1, '1 variation feature returned');
  my $expected_variation_1 = {source => 'Variants (including SNPs and indels) imported from dbSNP', name => $id, MAF => '0.123049', minor_allele => 'A', ambiguity => 'R', var_class => 'SNP', synonyms => [], evidence => ['Multiple_observations','1000Genomes'], most_severe_consequence => 'intron_variant', mappings => [{"assembly_name" => "GRCh37", "location"=>"18:23821095-23821095", "strand" => 1, "start" => 23821095, "end" => 23821095, "seq_region_name" => "18", "coord_system" => "chromosome","allele_string"=>"G/A", "ancestral_allele" => "G"}]};
  cmp_deeply($json, $expected_variation_1, "Checking the result from the variation endpoint");

# Include phenotype information
  my $expected_phenotype = { %{$expected_variation_1},
  "phenotypes" => [{"source" => "DGVa","variants" => undef, "ontology_accessions" => ["Orphanet:130"], "trait" => "BRUGADA SYNDROME", "genes" => undef}]};
  my $phen_json = json_GET("$base/$id?phenotypes=1", "Phenotype info");
  cmp_deeply($phen_json, $expected_phenotype, "Returning phenotype information");

#Get basic structural variation summary
  my $id_sv = 'esv93078';
  my $json_sv = json_GET("$base/$id_sv", 'Variation feature');
  #is(scalar(@$json), 1, '1 variation feature returned');
  my $expected_sv = {
    source => 'Database of Genomic Variants Archive',
    name => $id_sv,
    alias => undef,
    study => {
      name => "estd59",
      description => "1000 Genomes Project Consortium - Pilot Project. PMID:20981092 [remapped from build NCBI36]",
      url => "ftp://ftp.ebi.ac.uk/pub/databases/dgva/estd59_1000_Genomes_Consortium_Pilot_Project",
    },
    validation_status => "high quality",
    var_class => "CNV",
    mappings => [{
      assembly_name => "GRCh37", 
      location => "8:7803891-7825340",
      strand => 1, 
      start => 7803891, 
      end => 7825340, 
      seq_region_name => "8", 
      coord_system => "chromosome",
      genomic_size => 21450
    }],
    supporting_evidence => [{
      alias => undef,
      name => "essv194300",
      mappings => [{
        assembly_name => "GRCh37", 
        location => "8:7803891-7825340",
        strand => 1, 
        start => 7803891, 
        end => 7825340, 
        seq_region_name => "8", 
        coord_system => "chromosome",
        genomic_size => 21450
      }],
      source => "Database of Genomic Variants Archive",
      study => {
        name => "estd59",
        description => "1000 Genomes Project Consortium - Pilot Project. PMID:20981092 [remapped from build NCBI36]",
        url => "ftp://ftp.ebi.ac.uk/pub/databases/dgva/estd59_1000_Genomes_Consortium_Pilot_Project",
      },
      var_class => "loss"
    }],
  };
  cmp_deeply($json_sv, $expected_sv, "Checking the result from the variation endpoint - SV");

# Include genotyping chips information
  $id = 'rs7698608';
  my $expected_variation_3 = {source => 'Variants (including SNPs and indels) imported from dbSNP', name => $id, MAF => '0.448577', minor_allele => 'C', ambiguity => 'M', var_class => 'SNP', synonyms => bag(qw/rs60248177 rs17215092/), evidence => [], most_severe_consequence => '5_prime_UTR_variant', mappings => [{"assembly_name" => "GRCh37", "location"=>"4:103937974-103937974", "strand" => 1, "start" => 103937974, "end" => 103937974, "seq_region_name" => "4", "coord_system" => "chromosome","allele_string"=>"C/A","ancestral_allele" => undef}]};
  $json = json_GET("$base/$id", 'Variation feature');
  cmp_deeply($json, $expected_variation_3, "Checking the result from the variation endpoint");

  my $expected_genotyping_chips = { %{$expected_variation_3},
  "genotyping_chips" => ['Illumina_HumanOmni1-Quad', 'Affy GeneChip 500K', 'Illumina_HumanOmni2.5', 'Affy GenomeWideSNP_6.0', 'Illumina_HumanOmni5', 'Illumina_1M-duo' ]};
  my $geno_chip_json = json_GET("$base/$id?genotyping_chips=1", "Genotyping chips info");
  cmp_ok(exists $geno_chip_json->{'genotyping_chips'}, "==", 1, "Variant has genotyping chips information");
  cmp_ok(scalar(@{$geno_chip_json->{'genotyping_chips'}}), "==", 6, 'Variant with 6 genotyping chips');

# POST genotyping chips info
  my $url = $base."?genotyping_chips=1";
  my $post_data_genotyping_chips = '{ "ids" : ["rs142276873","rs7698608"] }';
  #my $expected_result_genotyping_chips = { rs142276873 => { %{$expected_variation_1}, genotyping_chips => [] }, rs7698608 => $expected_genotyping_chips };
  my $geno_chip_json_post = json_POST($url, $post_data_genotyping_chips, "POST list of variations and fetch with genotyping chips information");
  cmp_ok(scalar(keys %{$geno_chip_json_post}), "==", 2, "POST genotyping chips info: retrieve 2 variants");
  cmp_ok(scalar(@{$geno_chip_json_post->{"rs142276873"}->{'genotyping_chips'}}), "==", 0, "Variant has 0 genotyping chips information");
  cmp_ok(scalar(@{$geno_chip_json_post->{"rs7698608"}->{'genotyping_chips'}}), "==", 6, 'Variant with 6 genotyping chips');

# Get additional genotype information
  $id = 'rs67521280';
  my $expected_variation_2 = {source => 'Variants (including SNPs and indels) imported from dbSNP', name => $id, MAF => undef, minor_allele => undef, failed => 'None of the variant alleles match the reference allele;Mapped position is not compatible with reported alleles', ambiguity => undef, var_class => 'indel', synonyms => [], evidence => [], most_severe_consequence => 'intergenic_variant', mappings => [{"assembly_name" => "GRCh37", "location"=> "11:6303493-6303493", "strand" => 1, "start" => 6303493, "end" => 6303493, "seq_region_name" => "11", "coord_system" => "chromosome","allele_string"=>"-/GT", "ancestral_allele" => undef}] };
  my $expected_genotype = { %{$expected_variation_2}, 
  genotypes => [{genotype => "GT|GT", gender => "Male", sample => "J. CRAIG VENTER", submission_id => 'ss95559393'}] };
  my $genotype_json = json_GET("$base/$id?genotypes=1", "Genotype info");
  cmp_deeply($genotype_json, $expected_genotype, "Returning genotype information");

# Include population allele frequency information
  my $expected_pops = { %{$expected_variation_2},
  populations => [{population => "HUMANGENOME_JCVI:J. Craig Venter",frequency => 1,allele => "GT",allele_count => 2, submission_id => 'ss95559393'}]};
  my $pops_json = json_GET("$base/$id?pops=1", "Population info");
  cmp_deeply($pops_json, $expected_pops, "Returning population information");

# Include population_genotype information ( data faked)
   my $expected_pop_genos = { %{$expected_variation_2},
   population_genotypes =>[
 { count => 11,frequency => 0.5,    genotype => 'A|G', population => 'PERLEGEN:AFD_AFR_PANEL',    subsnp_id => 'ss23290311'}, 
 { count => 5, frequency => 0.227273, genotype => 'A|A',  population => 'PERLEGEN:AFD_AFR_PANEL',  subsnp_id => 'ss23290311'},
 { count => 6, frequency => 0.272727, genotype => 'G|G',  population => 'PERLEGEN:AFD_AFR_PANEL', subsnp_id => 'ss23290311' },
 { count => 9, frequency => 0.375, genotype => 'A|G',  population => 'PERLEGEN:AFD_CHN_PANEL', subsnp_id => 'ss23290311'},
 { count => 1, frequency => 0.0416667, genotype => 'A|A', population => 'PERLEGEN:AFD_CHN_PANEL', subsnp_id => 'ss23290311'  },
 { count => 14, frequency => 0.583333,  genotype => 'G|G',  population => 'PERLEGEN:AFD_CHN_PANEL', subsnp_id => 'ss23290311'},
 ]};
 
   my $pop_genos_json = json_GET("$base/$id?population_genotypes=1", "Population_genotype info");
   cmp_deeply($pop_genos_json, $expected_pop_genos, "Returning population_genotype information");

my $post_data = '{ "ids" : ["rs142276873","rs67521280","esv93078"]}';
my $expected_result = {
  rs142276873 => $expected_variation_1,
  rs67521280 => $expected_variation_2,
  esv93078 => $expected_sv
};

is_json_POST($base,$post_data,$expected_result,"Try to POST list of variations");

# Test population allele frequency with no allele_count
  $id = 'COSM946275';
  my $expected_pops_nc = {
    'source' => 'http://cancer.sanger.ac.uk/cancergenome/projects/cosmic/',
    'mappings' => [
      {
        'location' => '13:25744274-25744274',
        'assembly_name' => 'GRCh37',
        'end' => 25744274,
        'seq_region_name' => '13',
        'strand' => 1,
        'coord_system' => 'chromosome',
        'allele_string' => 'C/T',
        'start' => 25744274,
        'ancestral_allele' => undef,
     }
    ],
    'name' => 'COSM946275',
    'MAF' => undef,
    'ambiguity' => 'Y',
    'populations' => [
      {
        'frequency' => '0.923077',
        'population' => 'COSMIC:gene:FAM123A_ENST00000515384:tumour_site:endometrium',
        'allele' => 'C',
      },
      {
        'frequency' => '0.0769231',
        'population' => 'COSMIC:gene:FAM123A_ENST00000515384:tumour_site:endometrium',
        'allele' => 'T',
     }
    ],
    'var_class' => 'somatic SNV',
    'synonyms' => [],
    'evidence' => [],
    'most_severe_consequence' => 'missense_variant',
    'minor_allele' => undef
   };
  $pops_json = json_GET("$base/$id?pops=1", "Population info");
  cmp_deeply($pops_json->{'populations'},
             bag(@{$expected_pops_nc->{'populations'}}),
             "Returning population information - no allele_count");

# In test database the variant data for the publication PMID:22779046 PMC:3392070
# is set to $publication_output
my $publication_output = 
[ 
  { 
    "source" => "Variants (including SNPs and indels) imported from dbSNP",
    "mappings" =>
    [
      {
        "location"      => "4:103937974-103937974",
        "assembly_name" => "GRCh37",
        "end" => 103937974,
        "seq_region_name" => "4",
        "strand" => 1,
        "coord_system" => "chromosome",
        "allele_string" => "C/A",
        "start" => 103937974, 
        "ancestral_allele" => undef,
      }
    ],
    "name" => "rs7698608",
    "MAF"  => "0.448577",
    "ambiguity" => "M",
    "var_class" => "SNP",
    "synonyms" => 
      [
        "rs60248177",
        "rs17215092"
      ],
    "evidence" => 
      [
      ],
    "minor_allele" => "C",
    "most_severe_consequence" => "5_prime_UTR_variant"
  }
];


# GET variation/:species/pmid/:pmid
{
  my $pmid_base = $base . "/pmid";
  my $pmid = 22779046;

  # PMID not in test database
  my $pmid_not_found = 123;

  # PMID invalid
  my $pmid_invalid = "ABC";

  # Check correct data structure is returned
  my $variants_json = json_GET($pmid_base . '/' . $pmid, 'Get the variants array');
  is(ref($variants_json), 'ARRAY', 'Array wanted from endpoint');
  
  # Check the variations
  # Must be checked individually due to variable ordering in output. is_json doesn't ignore order, cmp_bag cannot handle arrays within hashes
  is($variants_json->[0]->{source}, $publication_output->[0]->{source} ,'PMID source key');
  is_deeply($variants_json->[0]->{mappings},$publication_output->[0]->{mappings},'PMID mappings key');
  cmp_bag($variants_json->[0]->{synonyms},$publication_output->[0]->{synonyms},'PMID synonyms');
  is($variants_json->[0]->{name}, $publication_output->[0]->{name} ,'PMID name key');
  is($variants_json->[0]->{MAF},$publication_output->[0]->{MAF} ,'PMID MAF key'); # Interestingly these are not numerically equal under certain testing conditions...
  is($variants_json->[0]->{ambiguity}, $publication_output->[0]->{ambiguity} ,'PMID ambiguity key');
  is($variants_json->[0]->{var_class}, $publication_output->[0]->{var_class} ,'PMID source key');
  is($variants_json->[0]->{minor_allele}, $publication_output->[0]->{minor_allele} ,'PMID minor_allele key');
  is($variants_json->[0]->{most_severe_consequence}, $publication_output->[0]->{most_severe_consequence} ,'PMID most_severe_consequence key');

 
  # Invalid species
  action_bad(
    "/variation/wibble/pmid/" . $pmid,
    'Bad species name results in a non-200 response'
  );
  # PMID not found
  action_bad($pmid_base . "/" . $pmid_not_found, 'PMID should not be found.');

  # PMID invalid format
  action_bad($pmid_base . "/" . $pmid_invalid, 'PMID invalid');
}



# GET variation/:species/pmcid/:pmcid
{
  my $pmcid_base = $base . "/pmcid";
  my $pmcid = "PMC3392070";

  # PMCID not in test database
  my $pmcid_not_found = "PMC123";

  # Check correct data structure is returned
  my $variants_json = json_GET($pmcid_base . '/' . $pmcid, 'Get the variants array');
  is(ref($variants_json), 'ARRAY', 'Array wanted from endpoint');
  
  # Check the variations
  is($variants_json->[0]->{source}, $publication_output->[0]->{source} ,'PMID source key');
  is_deeply($variants_json->[0]->{mappings},$publication_output->[0]->{mappings},'PMID mappings key');
  cmp_bag($variants_json->[0]->{synonyms},$publication_output->[0]->{synonyms},'PMID synonyms');
  is($variants_json->[0]->{name}, $publication_output->[0]->{name} ,'PMID name key');
  is($variants_json->[0]->{MAF},$publication_output->[0]->{MAF} ,'PMID MAF key');
  is($variants_json->[0]->{ambiguity}, $publication_output->[0]->{ambiguity} ,'PMID ambiguity key');
  is($variants_json->[0]->{var_class}, $publication_output->[0]->{var_class} ,'PMID source key');
  is($variants_json->[0]->{minor_allele}, $publication_output->[0]->{minor_allele} ,'PMID minor_allele key');
  is($variants_json->[0]->{most_severe_consequence}, $publication_output->[0]->{most_severe_consequence} ,'PMID most_severe_consequence key');
 
  # Invalid species
  action_bad(
    "/variation/wibble/pmcid/" . $pmcid,
    'Bad species name results in a non-200 response'
  );

  # PMCID not found
  action_bad($pmcid_base . "/" . $pmcid_not_found, 'PMCID should not be found.');
}

$base = '/variant_recoder/homo_sapiens';

my $exp = [
  {
    'G' => {
      'hgvsp' => [
        'ENSP00000371073.2:p.Asp22Glu',
        'ENSP00000371079.3:p.Asp22Glu',
        'ENSP00000381976.1:p.Asp22Glu',
        'ENSP00000399510.1:p.Asp22Glu',
        'ENSP00000400904.1:p.Asp22Glu',
        'ENSP00000394848.2:p.Asp22Glu',
        'ENSP00000408558.1:p.Asp22Glu',
        'ENSP00000412018.1:p.Asp22Glu',
        'ENSP00000405307.1:p.Asp22Glu',
        'ENSP00000414181.1:p.Asp22Glu'
      ],
      'hgvsc' => [
        'ENST00000381657.2:c.66C>G',
        'ENST00000381663.3:c.66C>G',
        'ENST00000399012.1:c.66C>G',
        'ENST00000415337.1:c.66C>G',
        'ENST00000429181.1:c.66C>G',
        'ENST00000430923.2:c.66C>G',
        'ENST00000443019.1:c.66C>G',
        'ENST00000445062.1:c.66C>G',
        'ENST00000447472.1:c.66C>G',
        'ENST00000448477.1:c.66C>G',
        'ENST00000484611.2:n.158C>G'
      ],
      'spdi' => [
        'X:200919:C:G'
      ],
      'id' => [
        'rs200625439'
      ],
      'hgvsg' => [
        'X:g.200920C>G'
      ]
    }
  }
];

for my $input(qw(
  rs200625439
  ENST00000381657.2:c.66C>G
  X:g.200920C>G
  X:200919:C:G
)) {
  $exp->[0]->{'G'}->{input} = $input;
  is_deeply(
    json_GET("$base/$input", "variant_recoder - $input"),
    $exp,
    'variant_recoder - GET - '.$input
  );
}

# protein input can resolve to multiple HGVSg

$json = json_GET("$base/ENSP00000371073.2:p.Asp22Glu", "variant_recoder - multi");
my @hgvsg_ids = ();
foreach my $allele (keys %{$json->[0]}) {
  push @hgvsg_ids, @{$json->[0]->{$allele}->{hgvsg}};
}

is_deeply(
  [sort @hgvsg_ids],
  ['X:g.200920C>A', 'X:g.200920C>G'],
  'variant_recoder - GET - multi'
);

# restrict fields
my $expf = dclone($exp);
delete($expf->[0]->{G}->{$_}) for qw(hgvsc hgvsp);
$expf->[0]->{G}->{input} = 'rs200625439';

is_deeply(
  json_GET("$base/rs200625439?fields=hgvsg,id,spdi", "variant_recoder - restrict fields"),
  $expf,
  'variant_recoder - GET - restrict fields'
);

# test errors
action_bad_regex('/variant_recoder', qr/page not found/, 'error - no species');
action_bad_regex('/variant_recoder/dave', qr/Can not find internal name for species/, 'error - invalid species');
action_bad_regex("$base/dave", qr/No variant found/, 'error - var not found');

# POST
$exp->[0]->{G}->{input} = 'rs200625439';
my $exp2 = [
  { 
    'T' => {
      'hgvsp' => [
        'ENSP00000371073.2:p.Arg146Cys',
        'ENSP00000371079.3:p.Arg146Cys',
        'ENSP00000381976.1:p.Arg146Cys',
        'ENSP00000399510.1:p.Arg146Cys',
        'ENSP00000394848.2:p.Arg146Cys',
        'ENSP00000405307.1:p.Arg146Cys'
      ],
      'hgvsc' => [
        'ENST00000381657.2:c.436C>T',
        'ENST00000381663.3:c.436C>T',
        'ENST00000399012.1:c.436C>T',
        'ENST00000415337.1:c.436C>T',
        'ENST00000430923.2:c.436C>T',
        'ENST00000447472.1:c.436C>T'
      ],
      'input' => 'rs142663151',
      'id' => [
        'rs142663151'
      ],
      'hgvsg' => [
        'X:g.208208C>T'
      ],
      'spdi' => [
        'X:208207:C:T'
      ]
    }
  }
];

is_json_POST(
  $base,
  '{"ids" : ["rs200625439", "rs142663151"]}',
  [$exp->[0], $exp2->[0]],
  'variant_recoder - POST'
);

# restrict fields
my $expf2 = dclone($exp2);
foreach my $allele (keys %{$expf2->[0]}) {
  delete($expf2->[0]->{$allele}->{$_}) for qw(hgvsc hgvsp);
}
is_json_POST(
  $base,
  '{"ids" : ["rs200625439", "rs142663151"], "fields": "hgvsg,id,spdi"}',
  [$expf->[0], $expf2->[0]],
  'variant_recoder - POST - restrict fields'
);

# test options vcf_string and var_synonyms
my $exp_options = [
  {
    'T' => {
      'hgvsp' => [
        'ENSP00000371073.2:p.Arg146Cys',
        'ENSP00000371079.3:p.Arg146Cys',
        'ENSP00000381976.1:p.Arg146Cys',
        'ENSP00000399510.1:p.Arg146Cys',
        'ENSP00000394848.2:p.Arg146Cys',
        'ENSP00000405307.1:p.Arg146Cys'
      ],
      'hgvsc' => [
        'ENST00000381657.2:c.436C>T',
        'ENST00000381663.3:c.436C>T',
        'ENST00000399012.1:c.436C>T',
        'ENST00000415337.1:c.436C>T',
        'ENST00000430923.2:c.436C>T',
        'ENST00000447472.1:c.436C>T'
      ],
      'input' => 'rs142663151',
      'id' => [
        'rs142663151'
      ],
      'hgvsg' => [
        'X:g.208208C>T'
      ],
      'spdi' => [
        'X:208207:C:T'
      ],
      'vcf_string' => [
        'X-208208-C-T'
      ],
    }
  }
];

my $exp_options_2 = [
  {
    'A' => {
      'input' => 'rs7569578',
      'id' => [
        'rs7569578'
      ],
      'hgvsg' => [
        '2:g.45411130N>A'
      ],
      'spdi' => [
        '2:45411129:T:A'
      ],
      'vcf_string' => [
        '2-45411130-T-A'
      ],
      var_synonyms => [
        'Archive dbSNP: rs57302278'
      ],
    }
  }
];

is_deeply(
  json_GET("$base/rs7569578?vcf_string=1&var_synonyms=1", "variant_recoder - option vcf_string and var_synonyms"),
  $exp_options_2,
  'variant_recoder - GET - option vcf_string and var_synonyms'
);

is_json_POST(
  $base,
  '{"ids" : ["rs142663151", "rs7569578"], "vcf_string": "1", "var_synonyms" : "1"}',
  [$exp_options->[0], $exp_options_2->[0]],
  'variant_recoder - POST - option vcf_string and var_synonyms'
);

# test errors
action_bad_post($base, '{}', qr/key in your POST/, 'error - POST missing key');

done_testing();
