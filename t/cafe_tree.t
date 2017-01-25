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
use Data::Dumper;

my $human = Bio::EnsEMBL::Test::MultiTestDB->new("homo_sapiens");
my $mult  = Bio::EnsEMBL::Test::MultiTestDB->new('multi');
my $dba = Bio::EnsEMBL::Test::MultiTestDB->new('homology');
Catalyst::Test->import('EnsEMBL::REST');

my ($json, $xml, $nh);


my $cafe_species_tree = {
  'pvalue_avg' => '0.8370',
  'tree' => {
    'n_members' => 1,
    'lambda' => '0.00211524',
    'name' => 'Euteleostomi',
    'p_value_lim' => '0.01',
    'children' => [
      {
        'n_members' => 1,
        'lambda' => '0.00211524',
        'name' => 'Amniota',
        'p_value_lim' => '0.01',
        'children' => [
          {
            'n_members' => 1,
            'lambda' => '0.00211524',
            'name' => 'Euarchontoglires',
            'p_value_lim' => '0.01',
            'children' => [
              {
                'n_members' => 1,
                'lambda' => '0.00211524',
                'name' => 'Simiiformes',
                'p_value_lim' => '0.01',
                'children' => [
                  {
                    'n_members' => 2,
                    'lambda' => '0.00211524',
                    'name' => 'Homininae',
                    'p_value_lim' => '0.01',
                    'children' => [
                      {
                        'n_members' => 2,
                        'lambda' => '0.00211524',
                        'name' => 'pan.troglodytes',
                        'p_value_lim' => '0.01',
                        'pvalue' => 1,
                        'id' => 40102216,
                        'tax' => {
                          'alias_name' => 'Chimpanzee',
                          'scientific_name' => 'Pan troglodytes',
                          'production_name' => 'pan_troglodytes',
                          'timetree_mya' => 0,
                          'id' => 9598
                        }
                      },
                      {
                        'n_members' => 2,
                        'lambda' => '0.00211524',
                        'name' => 'homo.sapiens',
                        'p_value_lim' => '0.01',
                        'pvalue' => 1,
                        'id' => 40102217,
                        'tax' => {
                          'alias_name' => 'Human',
                          'scientific_name' => 'Homo sapiens',
                          'production_name' => 'homo_sapiens',
                          'timetree_mya' => 0,
                          'id' => 9606
                        }
                      }
                    ],
                    'tax' => {
                      'alias_name' => 'Hominines',
                      'scientific_name' => 'Homininae',
                      'timetree_mya' => '8.8',
                      'id' => 207598
                    },
                    'is_expansion' => 1,
                    'pvalue' => 1,
                    'id' => 40102215
                  },
                  {
                    'n_members' => 1,
                    'lambda' => '0.00211524',
                    'name' => 'callithrix.jacchus',
                    'p_value_lim' => '0.01',
                    'pvalue' => 1,
                    'id' => 40102218,
                    'tax' => {
                      'alias_name' => 'Marmoset',
                      'scientific_name' => 'Callithrix jacchus',
                      'production_name' => 'callithrix_jacchus',
                      'timetree_mya' => 0,
                      'id' => 9483
                    }
                  }
                ],
                'tax' => {
                  'alias_name' => 'Simians',
                  'scientific_name' => 'Simiiformes',
                  'timetree_mya' => '42.6',
                  'id' => 314293
                },
                'pvalue' => 1,
                'id' => 40102214
              },
              {
                'n_members' => 1,
                'lambda' => '0.00211524',
                'name' => 'mus.musculus',
                'p_value_lim' => '0.01',
                'pvalue' => 1,
                'id' => 40102219,
                'tax' => {
                  'alias_name' => 'Mouse',
                  'scientific_name' => 'Mus musculus',
                  'production_name' => 'mus_musculus',
                  'timetree_mya' => 0,
                  'id' => 10090
                }
              }
            ],
            'tax' => {
              'alias_name' => 'Primates and Rodents',
              'scientific_name' => 'Euarchontoglires',
              'timetree_mya' => '92.3',
              'id' => 314146
            },
            'pvalue' => 1,
            'id' => 40102213
          },
          {
            'n_members' => 1,
            'lambda' => '0.00211524',
            'name' => 'taeniopygia.guttata',
            'p_value_lim' => '0.01',
            'pvalue' => 1,
            'id' => 40102212,
            'tax' => {
              'alias_name' => 'Zebra Finch',
              'scientific_name' => 'Taeniopygia guttata',
              'production_name' => 'taeniopygia_guttata',
              'timetree_mya' => 0,
              'id' => 59729
            }
          }
        ],
        'tax' => {
          'alias_name' => 'Amniotes',
          'scientific_name' => 'Amniota',
          'timetree_mya' => '296.0',
          'id' => 32524
        },
        'pvalue' => 1,
        'id' => 40102211
      },
      {
        'n_members' => 3,
        'lambda' => '0.00211524',
        'name' => 'danio.rerio',
        'p_value_lim' => '0.01',
        'tax' => {
          'alias_name' => 'Zebrafish',
          'scientific_name' => 'Danio rerio',
          'production_name' => 'danio_rerio',
          'timetree_mya' => 0,
          'id' => 7955
        },
        'is_expansion' => 1,
        'pvalue' => 1,
        'id' => 40102220
      }
    ],
    'tax' => {
      'alias_name' => 'Bony vertebrates',
      'scientific_name' => 'Euteleostomi',
      'timetree_mya' => '441',
      'id' => 117571
    },
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

my $nh_simple = '(((((pan.troglodytes_2_1.0000,homo.sapiens_2_1.0000)Homininae_2_1.0000,callithrix.jacchus_1_1.0000)Simiiformes_1_1.0000,mus.musculus_1_1.0000)Euarchontoglires_1_1.0000,taeniopygia.guttata_1_1.0000)Amniota_1_1.0000,danio.rerio_3_1.0000)Euteleostomi_1_0.5000;';
is($nh, $nh_simple, 'Got the correct newick');

done_testing();
