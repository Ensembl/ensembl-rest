# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# Copyright [2016-2017] EMBL-European Bioinformatics Institute
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
use Test::Differences;
use Catalyst::Test ();
use Bio::EnsEMBL::Test::MultiTestDB;
use Test::XML::Simple;
use Test::XPath;
use List::Util qw(sum);

my $human = Bio::EnsEMBL::Test::MultiTestDB->new("homo_sapiens");
my $mult  = Bio::EnsEMBL::Test::MultiTestDB->new('multi');
my $dba = Bio::EnsEMBL::Test::MultiTestDB->new('homology');
Catalyst::Test->import('EnsEMBL::REST');

my ($json, $xml, $nh);


my $cafe_species_tree = {
  'pvalue_avg' => '0.837',
  'tree' => {
    'n_members' => 1,
    'lambda' => '0.00211524',
    'p_value_lim' => '0.01',
    'name' => 'Euteleostomi',
    'tax' => {
      'scientific_name' => 'Euteleostomi',
      'common_name' => 'Bony vertebrates',
      'id' => 117571,
      'timetree_mya' => '441'
    },
    'children' => [
      {
        'n_members' => 1,
        'lambda' => '0.00211524',
        'p_value_lim' => '0.01',
        'name' => 'Amniota',
        'tax' => {
          'scientific_name' => 'Amniota',
          'common_name' => 'Amniotes',
          'id' => 32524,
          'timetree_mya' => '296.0'
        },
        'children' => [
          {
            'n_members' => 1,
            'lambda' => '0.00211524',
            'p_value_lim' => '0.01',
            'name' => 'Euarchontoglires',
            'tax' => {
              'scientific_name' => 'Euarchontoglires',
              'common_name' => 'Primates and Rodents',
              'id' => 314146,
              'timetree_mya' => '92.3'
            },
            'children' => [
              {
                'n_members' => 1,
                'lambda' => '0.00211524',
                'p_value_lim' => '0.01',
                'name' => 'Simiiformes',
                'tax' => {
                  'scientific_name' => 'Simiiformes',
                  'common_name' => 'Simians',
                  'id' => 314293,
                  'timetree_mya' => '42.6'
                },
                'children' => [
                  {
                    'n_members' => 2,
                    'lambda' => '0.00211524',
                    'p_value_lim' => '0.01',
                    'name' => 'Homininae',
                    'tax' => {
                      'scientific_name' => 'Homininae',
                      'common_name' => 'Hominines',
                      'id' => 207598,
                      'timetree_mya' => '8.8'
                    },
                    'children' => [
                      {
                        'n_members' => 2,
                        'lambda' => '0.00211524',
                        'pvalue' => 1,
                        'p_value_lim' => '0.01',
                        'name' => 'pan.troglodytes',
                        'tax' => {
                          'scientific_name' => 'Pan troglodytes',
                          'common_name' => 'Chimpanzee',
                          'production_name' => 'pan_troglodytes',
                          'id' => 9598,
                          'timetree_mya' => 0
                        },
                        'id' => 40102216
                      },
                      {
                        'n_members' => 2,
                        'lambda' => '0.00211524',
                        'pvalue' => 1,
                        'p_value_lim' => '0.01',
                        'name' => 'homo.sapiens',
                        'tax' => {
                          'scientific_name' => 'Homo sapiens',
                          'common_name' => 'Human',
                          'production_name' => 'homo_sapiens',
                          'id' => 9606,
                          'timetree_mya' => 0
                        },
                        'id' => 40102217
                      }
                    ],
                    'is_expansion' => 1,
                    'pvalue' => 1,
                    'id' => 40102215
                  },
                  {
                    'n_members' => 1,
                    'lambda' => '0.00211524',
                    'pvalue' => 1,
                    'p_value_lim' => '0.01',
                    'name' => 'callithrix.jacchus',
                    'tax' => {
                      'scientific_name' => 'Callithrix jacchus',
                      'common_name' => 'Marmoset',
                      'production_name' => 'callithrix_jacchus',
                      'id' => 9483,
                      'timetree_mya' => 0
                    },
                    'id' => 40102218
                  }
                ],
                'pvalue' => 1,
                'id' => 40102214
              },
              {
                'n_members' => 1,
                'lambda' => '0.00211524',
                'pvalue' => 1,
                'p_value_lim' => '0.01',
                'name' => 'mus.musculus',
                'tax' => {
                  'scientific_name' => 'Mus musculus',
                  'common_name' => 'Mouse',
                  'production_name' => 'mus_musculus',
                  'id' => 10090,
                  'timetree_mya' => 0
                },
                'id' => 40102219
              }
            ],
            'pvalue' => 1,
            'id' => 40102213
          },
          {
            'n_members' => 1,
            'lambda' => '0.00211524',
            'pvalue' => 1,
            'p_value_lim' => '0.01',
            'name' => 'taeniopygia.guttata',
            'tax' => {
              'scientific_name' => 'Taeniopygia guttata',
              'common_name' => 'Zebra Finch',
              'production_name' => 'taeniopygia_guttata',
              'id' => 59729,
              'timetree_mya' => 0
            },
            'id' => 40102212
          }
        ],
        'pvalue' => 1,
        'id' => 40102211
      },
      {
        'n_members' => 3,
        'lambda' => '0.00211524',
        'p_value_lim' => '0.01',
        'name' => 'danio.rerio',
        'tax' => {
          'scientific_name' => 'Danio rerio',
          'common_name' => 'Zebrafish',
          'production_name' => 'danio_rerio',
          'id' => 7955,
          'timetree_mya' => 0
        },
        'is_expansion' => 1,
        'pvalue' => 1,
        'id' => 40102220
      }
    ],
    'pvalue' => '0.5',
    'id' => 40102210
  },
  'rooted' => 1,
  'type' => 'cafe tree'
};



is_json_GET(
    '/cafe/genetree/id/RF01299?compara=homology',
    $cafe_species_tree,
    'cafe species-tree for RF01299 gene tree ',
);

is_json_GET(
    '/cafe/genetree/member/id/ENSG00000176515?compara=homology',
    $cafe_species_tree,
    'cafe species-tree using MAOA gene stable id ',
);

# Aliases are somehow not loaded yet, so we need to add one here
Bio::EnsEMBL::Registry->add_alias('homo_sapiens', 'johndoe');

is_json_GET(
    '/cafe/genetree/member/symbol/johndoe/AL033381.1?compara=homology',
    $cafe_species_tree,
    'cafe species-tree using MAOA gene stable id ',
);

$nh = nh_GET(
    '/cafe/genetree/id/RF01299?compara=homology',
    'Gene-tree (ncRNA) by ID',
);

my $nh_simple = '(((((pan.troglodytes_2_1,homo.sapiens_2_1)Homininae_2_1,callithrix.jacchus_1_1)Simiiformes_1_1,mus.musculus_1_1)Euarchontoglires_1_1,taeniopygia.guttata_1_1)Amniota_1_1,danio.rerio_3_1)Euteleostomi_1_0.5;';
is($nh, $nh_simple, 'Got the correct newick');

done_testing();
