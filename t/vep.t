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
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;
use Catalyst::Test ();

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');
my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('multi');
Catalyst::Test->import('EnsEMBL::REST');

my $vep_get = '/vep/homo_sapiens/region/7:86442404-86442404:1/G?content-type=application/json';
my $vep_output =
[{
  allele_string => "N/G",
  colocated_variants =>
  [{
    afr_maf => "0.01",
    allele_string => "T/C",
    amr_maf => "0.04",
    asn_maf => "0.09",
    clin_sig => [],
    end => 86442404,
    eur_maf => "0.02",
    id => "rs2299222",
    minor_allele => "C",
    minor_allele_freq => "0.0399",
    pubmed => [],
    somatic => 0,
    start => 86442404,
    strand => 1,
  }],
  end => 86442404,
  id => "temp",
  most_severe_consequence => "intron_variant",
  seq_region_name => "7",
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
      strand => 1,
      transcript_id => 'ENST00000536043',
      variant_allele => 'G'
    },
    {
      biotype => 'protein_coding',
      consequence_terms => [
        'intron_variant'
      ],
      gene_id => 'ENSG00000198822',
      gene_symbol => 'GRM3',
      gene_symbol_source => 'HGNC',
      strand => 1,
      transcript_id => 'ENST00000439827',
      variant_allele => 'G'
    },
    {
      biotype => 'protein_coding',
      consequence_terms => [
        'intron_variant'
      ],
      gene_id => 'ENSG00000198822',
      gene_symbol => 'GRM3',
      gene_symbol_source => 'HGNC',
      strand => 1,
      transcript_id => 'ENST00000361669',
      variant_allele => 'G'
    },
    {
      biotype => 'protein_coding',
      consequence_terms => [
        'intron_variant'
      ],
      gene_id => 'ENSG00000198822',
      gene_symbol => 'GRM3',
      gene_symbol_source => 'HGNC',
      strand => 1,
      transcript_id => 'ENST00000546348',
      variant_allele => 'G'
    },
    {
      biotype => 'protein_coding',
      consequence_terms => [
        'intron_variant'
      ],
      gene_id => 'ENSG00000198822',
      gene_symbol => 'GRM3',
      gene_symbol_source => 'HGNC',
      strand => 1,
      transcript_id => 'ENST00000394720',
      variant_allele => 'G'
    }
  ]}];

my $vep_output_2 =
  { data => [
    {"Consequence" => "intron_variant",
     "GMAF" => "C:0.0399",
     "STRAND" => 1,
     "SYMBOL" => "GRM3",
     "SYMBOL_SOURCE" => "HGNC",
     "BIOTYPE" => 'protein_coding',
     "Feature_type" => "Transcript",
     "Uploaded_variation" => "temp",
     "Existing_variation" => "rs2299222",
     "Allele" => "G",
     "Gene" => "ENSG00000198822",
     "CDS_position" => "-",
     "cDNA_position" => "-",
     "Protein_position" => "-",
     "Amino_acids" => undef,
     "Feature" => "ENST00000536043",
     "Codons" => undef,
     "Location" => "7:86442404"
    },
    {"Consequence" => "intron_variant",
     "GMAF" => "C:0.0399",
     "STRAND" => 1,
     "SYMBOL" => "GRM3",
     "SYMBOL_SOURCE" => "HGNC",
     "BIOTYPE" => "protein_coding",
     "Uploaded_variation" => "temp",
     "Existing_variation" => "rs2299222",
     "Allele" => "G",
     "Gene" => "ENSG00000198822",
     "CDS_position" => "-",
     "cDNA_position" => "-",
     "Protein_position" => "-",
     "Amino_acids" => undef,
     "Feature" => "ENST00000439827",
     "Feature_type" => "Transcript",
     "Codons" => undef,
     "Location" => "7:86442404"
     },
     {"Consequence" => "intron_variant",
      "GMAF" => "C:0.0399",
      "STRAND" => 1,
      "SYMBOL" => "GRM3",
      "SYMBOL_SOURCE" => "HGNC",
      "BIOTYPE" => "protein_coding",
      "Feature_type" => "Transcript",
      "Uploaded_variation" => "temp",
      "Existing_variation" => "rs2299222",
      "Allele" => "G",
      "Gene" => "ENSG00000198822",
      "CDS_position" => "-",
      "cDNA_position" => "-",
      "Protein_position" => "-",
      "Amino_acids" => undef,
      "Feature" => "ENST00000361669",
      "Codons" => undef,
      "Location" => "7:86442404"
      },
      {"Consequence" => "intron_variant",
       "GMAF" => "C:0.0399",
       "STRAND" => 1,
       "SYMBOL" => "GRM3",
       "SYMBOL_SOURCE" => "HGNC",
       "BIOTYPE" => "protein_coding",
       "Feature_type" => "Transcript",
       "Uploaded_variation" => "temp",
       "Existing_variation" => "rs2299222",
       "Allele" => "G",
       "Gene" => "ENSG00000198822",
       "CDS_position" => "-",
       "cDNA_position" => "-",
       "Protein_position" => "-",
       "Amino_acids" => undef,
       "Feature" => "ENST00000546348",
       "Codons" => undef,
       "Location" => "7:86442404"
       },
       {"Consequence" => "intron_variant",
        "GMAF" => "C:0.0399",
        "STRAND" => 1,
        "SYMBOL" => "GRM3",
        "SYMBOL_SOURCE" => "HGNC",
        "BIOTYPE" => "protein_coding",
        "Feature_type" => "Transcript",
        "Uploaded_variation" => "temp",
        "Existing_variation" => "rs2299222",
        "Allele" => "G",
        "Gene" => "ENSG00000198822",
        "CDS_position" => "-",
        "cDNA_position" => "-",
        "Protein_position" => "-",
        "Amino_acids" => undef,
        "Feature" => "ENST00000394720",
        "Codons" => undef,
        "Location" => "7:86442404"}
      ]};

# Test vep/region
my $json = json_GET($vep_get,'GET a VEP region');
eq_or_diff($json, $vep_output, 'Example vep region get message');
my $json_2 = json_GET("$vep_get;version=2", "GET a VEP region version 2");
eq_or_diff($json_2, $vep_output_2, "Example vep region in version 2 get message");

my $vep_post = '/vep/homo_sapiens/region';
my $vep_post_body = '{ "variants" : ["7  34381884  var1  C  T  . . .",
                                     "7  86442404  var2  T  C  . . ."]}';
my $vep_post_body_2 = '{ "version" : 2,  "variants" : ["7  34381884  var1  C  T  . . .",
                                     "7  86442404  var2  T  C  . . ."]}';

$vep_output =
[{
     allele_string => 'C/T',
     end => 34381884,
     id => 'var1',
     input => '7  34381884  var1  C  T  . . .',
     most_severe_consequence => 'downstream_gene_variant',
     seq_region_name => '7',
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
    afr_maf => "0.01",
    allele_string => "T/C",
    amr_maf => "0.04",
    asn_maf => "0.09",
    clin_sig => [],
    end => 86442404,
    eur_maf => "0.02",
    id => "rs2299222",
    minor_allele => "C",
    minor_allele_freq => "0.0399",
    pubmed => [],
    somatic => 0,
    start => 86442404,
    strand => 1,
  }],
  end => 86442404,
  id => "var2",
  input => '7  86442404  var2  T  C  . . .',
  most_severe_consequence => "intron_variant",
  seq_region_name => "7",
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
      strand => 1,
      transcript_id => 'ENST00000546348',
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
      strand => 1,
      transcript_id => 'ENST00000394720',
      variant_allele => 'C'
    },
  ]
}];

$vep_output_2 = 
{
  data => [
    {
      Allele => 'T',
      Amino_acids => undef,
      BIOTYPE => "processed_transcript",
      CDS_position => '-',
      Codons => undef,
      Consequence => 'downstream_gene_variant',
      Existing_variation => '-',
      "DISTANCE" => 4240,
      "STRAND" => -1,
      "SYMBOL" => "NPSR1-AS1",
      "SYMBOL_SOURCE" => "HGNC",
      Feature => 'ENST00000419766',
      Feature_type => 'Transcript',
      Gene => 'ENSG00000197085',
      Location => '7:34381884',
      Protein_position => '-',
      Uploaded_variation => 'var1',
      cDNA_position => '-'
    },
    {
      Allele => 'C',
      Amino_acids => undef,
      BIOTYPE => "protein_coding",
      CDS_position => '-',
      Codons => undef,
      Consequence => 'intron_variant',
      Existing_variation => 'rs2299222',
      GMAF => 'C:0.0399',
      STRAND => 1,
      SYMBOL => 'GRM3',
      SYMBOL_SOURCE => 'HGNC',
      Feature => 'ENST00000536043',
      Feature_type => 'Transcript',
      Gene => 'ENSG00000198822',
      Location => '7:86442404',
      Protein_position => '-',
      Uploaded_variation => 'var2',
      cDNA_position => '-'
    },
    {
      Allele => 'C',
      Amino_acids => undef,
      BIOTYPE => "protein_coding",
      CDS_position => '-',
      Codons => undef,
      Consequence => 'intron_variant',
      Existing_variation => 'rs2299222',
      GMAF => 'C:0.0399',
      STRAND => 1,
      SYMBOL => 'GRM3',
      SYMBOL_SOURCE => 'HGNC',
      Feature => 'ENST00000439827',
      Feature_type => 'Transcript',
      Gene => 'ENSG00000198822',
      Location => '7:86442404',
      Protein_position => '-',
      Uploaded_variation => 'var2',
      cDNA_position => '-'
    },
    {
      Allele => 'C',
      Amino_acids => undef,
      BIOTYPE => "protein_coding",
      CDS_position => '-',
      Codons => undef,
      Consequence => 'intron_variant',
      Existing_variation => 'rs2299222',
      GMAF => 'C:0.0399',
      STRAND => 1,
      SYMBOL => 'GRM3',
      SYMBOL_SOURCE => 'HGNC',
      Feature => 'ENST00000361669',
      Feature_type => 'Transcript',
      Gene => 'ENSG00000198822',
      Location => '7:86442404',
      Protein_position => '-',
      Uploaded_variation => 'var2',
      cDNA_position => '-'
    },
    {
      Allele => 'C',
      Amino_acids => undef,
      BIOTYPE => "protein_coding",
      CDS_position => '-',
      Codons => undef,
      Consequence => 'intron_variant',
      Existing_variation => 'rs2299222',
      GMAF => 'C:0.0399',
      STRAND => 1,
      SYMBOL => 'GRM3',
      SYMBOL_SOURCE => 'HGNC',
      Feature => 'ENST00000546348',
      Feature_type => 'Transcript',
      Gene => 'ENSG00000198822',
      Location => '7:86442404',
      Protein_position => '-',
      Uploaded_variation => 'var2',
      cDNA_position => '-'
    },
    {
      Allele => 'C',
      Amino_acids => undef,
      BIOTYPE => "protein_coding",
      CDS_position => '-',
      Codons => undef,
      Consequence => 'intron_variant',
      Existing_variation => 'rs2299222',
      GMAF => 'C:0.0399',
      STRAND => 1,
      SYMBOL => 'GRM3',
      SYMBOL_SOURCE => 'HGNC',
      Feature => 'ENST00000394720',
      Feature_type => 'Transcript',
      Gene => 'ENSG00000198822',
      Location => '7:86442404',
      Protein_position => '-',
      Uploaded_variation => 'var2',
      cDNA_position => '-'
    }
  ]
};

$json = json_POST($vep_post,$vep_post_body,'POST a selection of regions to the VEP');
eq_or_diff($json,$vep_output, "VEP region POST");
$json_2 = json_POST($vep_post, $vep_post_body_2, "POST a selection of regions to the VEP in version 2 format");
eq_or_diff($json_2, $vep_output_2, "VEP region POST version 2");


# test vep/id
my $vep_id_get = '/vep/homo_sapiens/id/rs186950277?content-type=application/json';
$vep_output =
[{
  allele_string => "G/A/T",
  colocated_variants =>
  [{
    afr_maf => 0,
    allele_string => "G/A/T",
    amr_maf => "0.01",
    asn_maf => 0,
    clin_sig => [],
    end => 60403074,
    eur_maf => "0.0013",
    id => "rs186950277",
    minor_allele => "A",
    minor_allele_freq => "0.0014",
    pubmed => [],
    somatic => 0,
    start => 60403074,
    strand => 1,
  }],
  end => 60403074,
  id => 'rs186950277',
  intergenic_consequences => [
    {
      consequence_terms => [
        'intergenic_variant'
      ],
      variant_allele => 'A'
    },
    {
      consequence_terms => [
        'intergenic_variant'
      ],
      variant_allele => 'T'
    }
  ],
  most_severe_consequence => 'intergenic_variant',
  seq_region_name => '8',
  start => 60403074,
  strand => 1
  }];

$vep_output_2 = 
{
  data => [
    {
      Allele => 'A',
      Consequence => 'intergenic_variant',
      Existing_variation => 'rs186950277',
      GMAF => 'A:0.0014',
      Location => '8:60403074',
      Uploaded_variation => 'rs186950277'
    },
    {
      Allele => 'T',
      Consequence => 'intergenic_variant',
      Existing_variation => 'rs186950277',
      GMAF => 'A:0.0014',
      Location => '8:60403074',
      Uploaded_variation => 'rs186950277'
    }
  ]
};

$json = json_GET($vep_id_get,'GET consequences for Variation ID');
eq_or_diff($json, $vep_output, 'VEP id GET');
$json_2 = json_GET("$vep_id_get;version=2", "GET consequences for variation ID in version 2");
eq_or_diff($json_2, $vep_output_2, "VEP id GET version 2");


my $vep_id_post = '/vep/homo_sapiens/id';
my $vep_id_body = '{ "ids" : ["rs186950277", "rs17081232" ]}';
my $vep_id_body_2 = '{ "version" : 2,  "ids" : ["rs186950277", "rs17081232" ]}';
$vep_output =
[{
  allele_string => "G/A/T",
  colocated_variants =>
  [{
    afr_maf => 0,
    allele_string => "G/A/T",
    amr_maf => "0.01",
    asn_maf => 0,
    clin_sig => [],
    end => 60403074,
    eur_maf => "0.0013",
    id => "rs186950277",
    minor_allele => "A",
    minor_allele_freq => "0.0014",
    pubmed => [],
    somatic => 0,
    start => 60403074,
    strand => 1,
  }],
  end => 60403074,
  id => 'rs186950277',
  input => 'rs186950277',
  intergenic_consequences => [
    {
      consequence_terms => [
        'intergenic_variant'
      ],
      variant_allele => 'A'
    },
    {
      consequence_terms => [
        'intergenic_variant'
      ],
      variant_allele => 'T'
    }
  ],
  most_severe_consequence => 'intergenic_variant',
  seq_region_name => '8',
  start => 60403074,
  strand => 1,
  },
  {
    allele_string => 'G/A',
    colocated_variants => [
      {
        afr_maf => '0.45',
        allele_string => 'G/A',
        amr_maf => '0.25',
        asn_maf => '0.24',
        clin_sig => [],
        end => 32305409,
        eur_maf => '0.11',
        id => 'rs17081232',
        minor_allele => 'A',
        minor_allele_freq => '0.2443',
        pubmed => [],
        somatic => 0,
        start => 32305409,
        strand => 1
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
        variant_allele => 'A'
      }
    ],
    most_severe_consequence => 'intergenic_variant',
    seq_region_name => '4',
    start => 32305409,
    strand => 1
  }];

$vep_output_2 =
{
  data => [
    {
      Allele => 'A',
      Consequence => 'intergenic_variant',
      Existing_variation => 'rs17081232',
      GMAF => 'A:0.2443',
      Location => '4:32305409',
      Uploaded_variation => 'rs17081232'
    },
    {
      Allele => 'A',
      Consequence => 'intergenic_variant',
      Existing_variation => 'rs186950277',
      GMAF => 'A:0.0014',
      Location => '8:60403074',
      Uploaded_variation => 'rs186950277'
    },
    {
      Allele => 'T',
      Consequence => 'intergenic_variant',
      Existing_variation => 'rs186950277',
      GMAF => 'A:0.0014',
      Location => '8:60403074',
      Uploaded_variation => 'rs186950277'
    }
  ]
};

$json = json_POST($vep_id_post,$vep_id_body,'VEP ID list POST');
eq_or_diff($json, $vep_output, 'VEP id POST');
$json_2 = json_POST($vep_id_post, $vep_id_body_2, "VEP ID list POST version 2");
eq_or_diff($json_2, $vep_output_2, "VEP id POST version 2");


my $body = '{ "blurb" : "stink" }';
# Test malformed messages
action_bad_post($vep_post,$body, qr/key in your POST/, 'Using a bad message format causes an exception');
action_bad_post($vep_id_post,$body, qr/key in your POST/, 'Using a bad message format causes an exception');

done_testing();
