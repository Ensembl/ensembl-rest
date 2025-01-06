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
use Test::Exception;
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;
use Catalyst::Test ();

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');
my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('multi');
Catalyst::Test->import('EnsEMBL::REST');

my $vep_get = '/vep/homo_sapiens/region/7:86442404-86442404:1/C?content-type=application/json';
my $vep_output =
[{
  allele_string => "N/C",
  end => 86442404,
  id => '7_86442404_N/C',
  input => '7 86442404 86442404 N/C 1',
  most_severe_consequence => "intron_variant",
  seq_region_name => "7",
  start => 86442404,
  assembly_name => 'GRCh37',
  strand => 1,
  transcript_consequences =>
  [
    {
      biotype => 'protein_coding',
      consequence_terms => [
        'intron_variant'
      ],
      impact => 'MODIFIER',
      gene_id => 'ENSG00000198822',
      gene_symbol => 'GRM3',
      gene_symbol_source => 'HGNC',
      strand => 1,
      transcript_id => 'ENST00000361669',
      variant_allele => 'C'
    },
    {
      biotype => 'protein_coding',
      consequence_terms => [
        'intron_variant'
      ],
      impact => 'MODIFIER',
      gene_id => 'ENSG00000198822',
      gene_symbol => 'GRM3',
      gene_symbol_source => 'HGNC',
      strand => 1,
      transcript_id => 'ENST00000394720',
      variant_allele => 'C'
    },
    {
      biotype => 'protein_coding',
      consequence_terms => [
        'intron_variant'
      ],
      impact => 'MODIFIER',
      gene_id => 'ENSG00000198822',
      gene_symbol => 'GRM3',
      gene_symbol_source => 'HGNC',
      strand => 1,
      transcript_id => 'ENST00000439827',
      variant_allele => 'C'
    },
    {
      biotype => 'protein_coding',
      consequence_terms => [
        'intron_variant'
      ],
      impact => 'MODIFIER',
      gene_id => 'ENSG00000198822',
      gene_symbol => 'GRM3',
      gene_symbol_source => 'HGNC',
      strand => 1,
      transcript_id => 'ENST00000536043',
      variant_allele => 'C'
    },
    {
      biotype => 'protein_coding',
      consequence_terms => [
        'intron_variant'
      ],
      impact => 'MODIFIER',
      gene_id => 'ENSG00000198822',
      gene_symbol => 'GRM3',
      gene_symbol_source => 'HGNC',
      strand => 1,
      transcript_id => 'ENST00000546348',
      variant_allele => 'C'
    },
  ]}];

# Test vep/region
my $json = json_GET($vep_get,'GET a VEP region');
cmp_bag($json, $vep_output, 'Example vep region get message');


# test with non-toplevel sequence (should transform to toplevel)
$vep_get = '/vep/homo_sapiens/region/HSCHR6_CTG1:1000001-1000001:1/G?content-type=application/json';
$vep_output = [
  {
    'assembly_name' => 'GRCh37',
    'end' => 1060001,
    'seq_region_name' => '6',
    'strand' => 1,
    'id' => 'temp',
    'most_severe_consequence' => 'intergenic_variant',
    'allele_string' => 'C/G',
    'intergenic_consequences' => [
      {
        'consequence_terms' => [
          'intergenic_variant'
        ],
        'variant_allele' => 'G',
        'impact' => 'MODIFIER'
      }
    ],
    'start' => 1060001
  }
];
$json = json_GET($vep_get,'GET a VEP region on a non-toplevel sequence');

my $vep_post = '/vep/homo_sapiens/region';
my $vep_post_body = '{ "variants" : ["7 34381884 var1 C T . . .",
                                     "7 86442404 var2 T C . . ."]}';


$vep_output =
[{
     allele_string => 'C/T',
     end => 34381884,
     id => 'var1',
     input => '7 34381884 var1 C T . . .',
     most_severe_consequence => 'downstream_gene_variant',
     seq_region_name => '7',
     assembly_name => 'GRCh37',
     start => 34381884,
     strand => 1,
     transcript_consequences => [
      {
        biotype => 'processed_transcript',
        consequence_terms => [
          'downstream_gene_variant'
        ],
        distance => 4240,
        gene_id => 'ENSG00000197085',
        gene_symbol => 'NPSR1-AS1',
        gene_symbol_source => 'HGNC',
        impact => 'MODIFIER',
        strand => -1,
        transcript_id => 'ENST00000419766',
        variant_allele => 'T'
      }
    ]
  },
  {
  allele_string => "T/C",
  colocated_variants =>
  [{
    frequencies => {
      C => {
        afr => 0.01,
        amr => 0.04,
        asn => 0.09,
        eur => 0.02,
      }
    },
    allele_string => "T/C",
    end => 86442404,
    id => "rs2299222",
    minor_allele => "C",
    minor_allele_freq => 0.0399,
    start => 86442404,
    strand => 1,
  }],
  end => 86442404,
  id => "var2",
  input => '7 86442404 var2 T C . . .',
  most_severe_consequence => "intron_variant",
  seq_region_name => "7",
  assembly_name => 'GRCh37',
  start => 86442404,
  strand => 1,
  transcript_consequences =>
  [
    {
      biotype => 'protein_coding',
      consequence_terms => [
        'intron_variant'
      ],
      gene_id => 'ENSG00000198822',
      gene_symbol => 'GRM3',
      gene_symbol_source => 'HGNC',
      impact => 'MODIFIER',
      strand => 1,
      transcript_id => 'ENST00000361669',
      variant_allele => 'C'
    },
    {
      biotype => 'protein_coding',
      consequence_terms => [
        'intron_variant'
      ],
      gene_id => 'ENSG00000198822',
      gene_symbol => 'GRM3',
      gene_symbol_source => 'HGNC',
      impact => 'MODIFIER',
      strand => 1,
      transcript_id => 'ENST00000394720',
      variant_allele => 'C'
    },
    {
      biotype => 'protein_coding',
      consequence_terms => [
        'intron_variant'
      ],
      gene_id => 'ENSG00000198822',
      gene_symbol => 'GRM3',
      gene_symbol_source => 'HGNC',
      impact => 'MODIFIER',
      strand => 1,
      transcript_id => 'ENST00000439827',
      variant_allele => 'C'
    },
    {
      biotype => 'protein_coding',
      consequence_terms => [
        'intron_variant'
      ],
      gene_id => 'ENSG00000198822',
      gene_symbol => 'GRM3',
      gene_symbol_source => 'HGNC',
      impact => 'MODIFIER',
      strand => 1,
      transcript_id => 'ENST00000536043',
      variant_allele => 'C'
    },
    {
      biotype => 'protein_coding',
      consequence_terms => [
        'intron_variant'
      ],
      gene_id => 'ENSG00000198822',
      gene_symbol => 'GRM3',
      gene_symbol_source => 'HGNC',
      impact => 'MODIFIER',
      strand => 1,
      transcript_id => 'ENST00000546348',
      variant_allele => 'C'
    },
  ]
}];

$json = json_POST($vep_post,$vep_post_body,'POST a selection of regions to the VEP');
cmp_bag($json,$vep_output, "VEP region POST");

#Ensure that providing an invalid ID is correctly handled by the ID endpoint
$vep_post = '/vep/homo_sapiens/id';
my $vep_post_body_invalid = '{ "ids" : ["invalid_id", "rs186950277", "rs17081232" ]}';
lives_ok{$json = json_POST($vep_post,$vep_post_body_invalid,'POST a selection of IDs to VEP')} 'ensuring invalid ID is handled';

#Ensure that providing invalid hgvs is correctly handled by the HGVS endpoint
$vep_post = '/vep/homo_sapiens/hgvs';
$vep_post_body_invalid = '{ "hgvs_notations" : ["invalid_hgvs", "ENST00000314040:c.311G>T"] }';
lives_ok{$json = json_POST($vep_post,$vep_post_body_invalid,'POST a selection of HGVS variants to VEP')} 'ensuring invalid HGVS is handled';


# test vep/id
my $vep_id_get = '/vep/homo_sapiens/id/rs186950277?content-type=application/json';
my $rs186950277_output =
[{
  allele_string => "G/A/T",
  colocated_variants =>
  [{
    'minor_allele_freq' => 0.0014,
    'frequencies' => {
      'A' => {
        'amr' => 0.01,
        'afr' => 0,
        'eur' => 0.0013,
        'asn' => 0
      }
    },
    'end' => 60403074,
    'strand' => 1,
    'id' => 'rs186950277',
    'allele_string' => 'G/A/T',
    'minor_allele' => 'A',
    'start' => 60403074
  }],
  end => 60403074,
  id => 'rs186950277',
  input => 'rs186950277',
  intergenic_consequences => [
    {
      consequence_terms => [
        'intergenic_variant'
      ],
      impact => 'MODIFIER',
      variant_allele => 'A'
    },
    {
      consequence_terms => [
        'intergenic_variant'
      ],
      impact => 'MODIFIER',
      variant_allele => 'T'
    }
  ],
  most_severe_consequence => 'intergenic_variant',
  seq_region_name => '8',
  assembly_name => 'GRCh37',
  start => 60403074,
  strand => 1
  }];

$json = json_GET($vep_id_get,'GET consequences for Variation ID');
cmp_bag($json, $rs186950277_output, 'VEP id GET');

# test vep/id for structural variants
$vep_id_get = '/vep/homo_sapiens/id/esv93078?content-type=application/json';
my $esv93078_output =
[{
  allele_string => "copy_number_variation",
  end => 7825340,
  id => 'esv93078',
  input => 'esv93078',
  intergenic_consequences => [
    {
      consequence_terms => [
        'intergenic_variant'
      ],
      impact => 'MODIFIER',
      variant_allele => 'copy_number_variation'
    }
  ],
  most_severe_consequence => 'intergenic_variant',
  seq_region_name => '8',
  assembly_name => 'GRCh37',
  start => 7803891,
  strand => 1
  }];

$json = json_GET($vep_id_get,'GET consequences for Variation ID');
cmp_bag($json, $esv93078_output, 'VEP id GET');

my $rs17081232_output = [{
  allele_string => 'G/A',
  colocated_variants => [
    {
      'minor_allele_freq' => 0.2443,
      'frequencies' => {
        'A' => {
          'amr' => 0.25,
          'afr' => 0.45,
          'eur' => 0.11,
          'asn' => 0.24
        }
      },
      'end' => 32305409,
      'strand' => 1,
      'id' => 'rs17081232',
      'allele_string' => 'G/A',
      'minor_allele' => 'A',
      'start' => 32305409
    }
  ],
  end => 32305409,
  id => 'rs17081232',
  input => 'rs17081232',
  intergenic_consequences => [
    {
      consequence_terms => [
        'intergenic_variant'
      ],
      impact => 'MODIFIER',
      variant_allele => 'A'
    }
  ],
  most_severe_consequence => 'intergenic_variant',
  seq_region_name => '4',
  assembly_name => 'GRCh37',
  start => 32305409,
  strand => 1
}];

my $vep_id_post = '/vep/homo_sapiens/id';
my $vep_id_body = '{ "ids" : ["rs186950277", "rs17081232", "esv93078" ]}';
$vep_output =
[$rs186950277_output->[0], $rs17081232_output->[0], $esv93078_output->[0]];


$json = json_POST($vep_id_post,$vep_id_body,'VEP ID list POST');
cmp_bag($json, $vep_output, 'VEP id POST');


# test vep/hgvs with a genomic coord
my $vep_hgvs_get = '/vep/homo_sapiens/hgvs/6:g.1102327G>T?content-type=application/json';
$vep_output = [{
  allele_string => 'G/T',
  assembly_name => 'GRCh37',
  end => 1102327,
  id => '6:g.1102327G>T',
  input => '6:g.1102327G>T',
  most_severe_consequence => 'missense_variant',
  seq_region_name => '6',
  start => 1102327,
  strand => 1,
  transcript_consequences => [
    {
      amino_acids => 'W/L',
      biotype => 'protein_coding',
      cdna_end => 581,
      cdna_start => 581,
      cds_end => 311,
      cds_start => 311,
      codons => 'tGg/tTg',
      consequence_terms => [
        'missense_variant'
      ],
      gene_id => 'ENSG00000176515',
      gene_symbol => 'AL033381.1',
      gene_symbol_source => 'Clone_based_ensembl_gene',
      impact => 'MODERATE',
      polyphen_prediction => 'possibly_damaging',
      polyphen_score => 0.514,
      protein_end => 104,
      protein_start => 104,
      strand => 1,
      transcript_id => 'ENST00000314040',
      variant_allele => 'T'
    }
  ]
}];

$json = json_GET($vep_hgvs_get,'GET consequences for genomic HGVS notation');
cmp_bag($json, $vep_output, 'VEP genomic HGVS GET');

# test vep/hgvs with a transcript coord
$vep_hgvs_get = '/vep/homo_sapiens/hgvs/ENST00000314040:c.311G>T?content-type=application/json';
$vep_output->[0]->{id} = 'ENST00000314040:c.311G>T';
$vep_output->[0]->{input} = 'ENST00000314040:c.311G>T';

$json = json_GET($vep_hgvs_get,'GET consequences for transcript HGVS notation');
eq_or_diff($json, $vep_output, 'VEP transcript HGVS GET');

# test VEP hgvs post
$vep_post = '/vep/homo_sapiens/hgvs';
$vep_post_body = '{ "hgvs_notations" : ["ENST00000314040:c.311G>T"] }';
$json = json_POST($vep_post,$vep_post_body,'VEP HGVS list POST');

$vep_output->[0]->{input} = "ENST00000314040:c.311G>T";
$vep_output->[0]->{input} = "ENST00000314040:c.311G>T";
eq_or_diff($json, $vep_output, 'VEP HGVS POST');

# test using a plugin
my $vep_plugin_get = '/vep/homo_sapiens/hgvs/6:g.1102327G>T?content-type=application/json&RestTestPlugin=Hello';
$vep_output = [{
  allele_string => 'G/T',
  assembly_name => 'GRCh37',
  end => 1102327,
  id => '6:g.1102327G>T',
  input => '6:g.1102327G>T',
  most_severe_consequence => 'missense_variant',
  seq_region_name => '6',
  start => 1102327,
  strand => 1,
  transcript_consequences => [
    {
      amino_acids => 'W/L',
      biotype => 'protein_coding',
      cdna_end => 581,
      cdna_start => 581,
      cds_end => 311,
      cds_start => 311,
      codons => 'tGg/tTg',
      consequence_terms => [
        'missense_variant'
      ],
      gene_id => 'ENSG00000176515',
      gene_symbol => 'AL033381.1',
      gene_symbol_source => 'Clone_based_ensembl_gene',
      impact => 'MODERATE',
      polyphen_prediction => 'possibly_damaging',
      polyphen_score => 0.514,
      protein_end => 104,
      protein_start => 104,
      strand => 1,
      transcript_id => 'ENST00000314040',
      variant_allele => 'T',
      resttestplugin => 'Hello'
    }
  ]
}];

$json = json_GET($vep_plugin_get,'GET consequences with test plugin');
cmp_bag($json, $vep_output, 'VEP plugin test');

# test using transcript_id
my $vep_transcript_id_get = '/vep/homo_sapiens/region/7:86442404-86442404:1/C?content-type=application/json&transcript_id=ENST00000361669';
#my $vep_transcript_id_get = '/vep/homo_sapiens/id/rs955687031?content-type=application/json&transcript_id=ENST00000492223';
$vep_output = [
  {
    allele_string => 'N/C',
    assembly_name => 'GRCh37',
    end => 86442404,
    id => '7_86442404_N/C',
    input => '7 86442404 86442404 N/C 1',
    most_severe_consequence => 'intron_variant',
    seq_region_name => 7,
    start => 86442404,
    strand => 1,
    transcript_consequences => [
      {
        biotype => 'protein_coding',
        consequence_terms => [
          'intron_variant'
        ],
        gene_id => 'ENSG00000198822',
        gene_symbol => 'GRM3',
        gene_symbol_source => 'HGNC',

        impact => 'MODIFIER',
        strand => 1,
        transcript_id => 'ENST00000361669',
        variant_allele => 'C'
      }
    ]
  }
];                                               

$json = json_GET($vep_transcript_id_get,'GET consequences with transcript_id');
cmp_bag($json, $vep_output, 'VEP transcript filter test');

# test using refseq cache
my $vep_refseq_get = '/vep/homo_sapiens/region/7:34097707-34097707:1/C?content-type=application/json&refseq=1';
$json = json_GET($vep_refseq_get,'GET consequences with refseq cache');

is_deeply(
  {map {$_->{transcript_id} => 1} @{$json->[0]->{transcript_consequences}}},
  {
    'NM_133468.4' => 1,
    'XM_005249632.1' => 1,
    'XM_005249633.1' => 1,
    'XM_005249634.1' => 1,
  },
  'refseq transcripts'
);


# test ambiguity flag
$vep_hgvs_get = '/vep/homo_sapiens/hgvs/6:g.1102327G>T?content-type=application/json&ambiguity=1';
$vep_output = [{
  allele_string => 'G/T',
  ambiguity => 'K',
  assembly_name => 'GRCh37',
  end => 1102327,
  id => '6:g.1102327G>T',
  input => '6:g.1102327G>T',
  most_severe_consequence => 'missense_variant',
  seq_region_name => '6',
  start => 1102327,
  strand => 1,
  transcript_consequences => [
    {

      amino_acids => 'W/L',
      biotype => 'protein_coding',
      cdna_end => 581,
      cdna_start => 581,
      cds_end => 311,
      cds_start => 311,
      codons => 'tGg/tTg',
      consequence_terms => [
        'missense_variant'
      ],
      gene_id => 'ENSG00000176515',
      gene_symbol => 'AL033381.1',
      gene_symbol_source => 'Clone_based_ensembl_gene',
      impact => 'MODERATE',
      polyphen_prediction => 'possibly_damaging',
      polyphen_score => 0.514,
      protein_end => 104,
      protein_start => 104,
      strand => 1,
      transcript_id => 'ENST00000314040',
      variant_allele => 'T'
    }
  ]
}];
$json = json_GET($vep_hgvs_get,'GET Ambiguity flag with HGVS notation');
eq_or_diff($json, $vep_output, 'VEP Ambiguity Flag GET');


# test transcript version flag
$vep_hgvs_get = '/vep/homo_sapiens/hgvs/6:g.1102327G>T?content-type=application/json&transcript_version=1';
$json = json_GET($vep_hgvs_get,'GET consequences with transcript_version option');
delete($vep_output->[0]->{ambiguity});
$vep_output->[0]->{transcript_consequences}->[0]->{transcript_id} = 'ENST00000314040.1';
cmp_bag($json, $vep_output, 'VEP transcript version test');


my $body = '{ "blurb" : "stink" }';
# Test malformed messages
action_bad_post($vep_post,$body, qr/key in your POST/, 'Using a bad message format causes an exception');
action_bad_post($vep_id_post,$body, qr/key in your POST/, 'Using a bad message format causes an exception');

# test using vcf_string
my $vep_vcf_string_get = '/vep/homo_sapiens/hgvs/6:g.1102327G>T?content-type=application/json&vcf_string=1';
$vep_output = [{
  allele_string => 'G/T',
  vcf_string => '6-1102327-G-T',
  assembly_name => 'GRCh37',
  end => 1102327,
  id => '6:g.1102327G>T',
  input => '6:g.1102327G>T',
  most_severe_consequence => 'missense_variant',
  seq_region_name => '6',
  start => 1102327,
  strand => 1,
  transcript_consequences => [
    {

      amino_acids => 'W/L',
      biotype => 'protein_coding',
      cdna_end => 581,
      cdna_start => 581,
      cds_end => 311,
      cds_start => 311,
      codons => 'tGg/tTg',
      consequence_terms => [
        'missense_variant'
      ],
      gene_id => 'ENSG00000176515',
      gene_symbol => 'AL033381.1',
      gene_symbol_source => 'Clone_based_ensembl_gene',
      impact => 'MODERATE',
      polyphen_prediction => 'possibly_damaging',
      polyphen_score => 0.514,
      protein_end => 104,
      protein_start => 104,
      strand => 1,
      transcript_id => 'ENST00000314040',
      variant_allele => 'T'
    }
  ]
}];

$json = json_GET($vep_vcf_string_get,'GET vcf_string');
cmp_bag($json, $vep_output, 'VEP alleles in VCF format');

# test return values for motif_feature_consequences and regulatory_feature_consequences 
my $vep_get_regulation = '/vep/homo_sapiens/hgvs/7:g.86689450N>C?content-type=application/json&vcf_string=1';
$json = json_GET($vep_get_regulation,'GET vcf_string');
my $motif_feature_consequences = [
{
  'motif_name' => 'ENSPFM0572',
  'motif_feature_id' => 'ENSM00532703671',
  'variant_allele' => 'C',
  'high_inf_pos' => 'N',
  'consequence_terms' => [
    'TF_binding_site_variant'
  ],
  'motif_pos' => 7,
  'strand' => -1,
  'motif_score_change' => '-0.067',
  'impact' => 'MODIFIER',
  'transcription_factors' => ['TEAD4::PITX1']
},
{
  'motif_name' => 'ENSPFM0546',
  'motif_feature_id' => 'ENSM00531327245',
  'variant_allele' => 'C',
  'high_inf_pos' => 'N',
  'consequence_terms' => [
    'TF_binding_site_variant'
  ],
  'motif_pos' => 1,
  'strand' => 1,
  'motif_score_change' => '-0.044',
  'impact' => 'MODIFIER',
  'transcription_factors' => ['TEAD4::FOXI1']
}];
my $regulatory_feature_consequences = [
{
  'consequence_terms' => [
    'regulatory_region_variant'
  ],
  'variant_allele' => 'C',
  'regulatory_feature_id' => 'ENSR00000214751',
  'impact' => 'MODIFIER',
  'biotype' => 'promoter'
},
{
  'consequence_terms' => [
    'regulatory_region_variant'
  ],
  'variant_allele' => 'C',
  'regulatory_feature_id' => 'ENSR00001402282',
  'impact' => 'MODIFIER',
  'biotype' => 'CTCF_binding_site'
}];

$json = json_GET($vep_get_regulation,'GET vep regulation data');
cmp_bag($json->[0]->{regulatory_feature_consequences}, $regulatory_feature_consequences, 'VEP regulatory_feature_consequences');
cmp_bag($json->[0]->{motif_feature_consequences}, $motif_feature_consequences, 'VEP motif_feature_consequences');

done_testing();
