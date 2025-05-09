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
use Test::Differences;
use Catalyst::Test ();
use Bio::EnsEMBL::Test::MultiTestDB;
use Test::XML::Simple;
use Test::XPath;
use List::Util qw(sum);

my $human = Bio::EnsEMBL::Test::MultiTestDB->new("homo_sapiens");
my $chicken = Bio::EnsEMBL::Test::MultiTestDB->new('gallus_gallus');
my $turkey = Bio::EnsEMBL::Test::MultiTestDB->new('meleagris_gallopavo');
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
    '/cafe/genetree/member/id/homo_sapiens/ENSG00000176515?compara=homology',
    $cafe_species_tree,
    'cafe species-tree using species name and MAOA gene stable id',
);

# Aliases are somehow not loaded yet, so we need to add one here
Bio::EnsEMBL::Registry->add_alias('homo_sapiens', 'human');

is_json_GET(
    '/cafe/genetree/member/symbol/human/AL033381.1?compara=homology',
    $cafe_species_tree,
    'cafe species-tree using MAOA gene stable id ',
);

is_json_GET(
    '/cafe/genetree/member/id/human/ENSG00000176515?compara=homology',
    $cafe_species_tree,
    'cafe species-tree using species alias and MAOA gene stable id',
);

$nh = nh_GET(
    '/cafe/genetree/id/RF01299?compara=homology',
    'Gene-tree (ncRNA) by ID',
);

my $nh_simple = '(((((pan.troglodytes_2_1,homo.sapiens_2_1)Homininae_2_1,callithrix.jacchus_1_1)Simiiformes_1_1,mus.musculus_1_1)Euarchontoglires_1_1,taeniopygia.guttata_1_1)Amniota_1_1,danio.rerio_3_1)Euteleostomi_1_0.5;';
is($nh, $nh_simple, 'Got the correct newick');

## queries with a clashing gene / transcript / translation / exon stable id

my $bird_cafe_tree = {
  'pvalue_avg' => '0.2144',
  'rooted' => 1,
  'tree' => {
    'id' => 4015700100,
    'lambda' => '2.48e-07',
    'pvalue' => '0.5',
    'p_value_lim' => '0.01',
    'tax' => {
      'id' => 8457,
      'common_name' => 'Sauropsids',
      'scientific_name' => 'Sauropsida',
      'timetree_mya' => 0,
    },
    'name' => 'Sauropsida',
    'n_members' => 1,
    'children' => [
      {
        'id' => 4015700101,
        'lambda' => '2.48e-07',
        'name' => 'Aves',
        'n_members' => 1,
        'pvalue' => '0.5',
        'p_value_lim' => '0.01',
        'tax' => {
          'id' => 8782,
          'common_name' => 'Birds',
          'scientific_name' => 'Aves',
          'timetree_mya' => 0,
        },
        'children' => [
          {
            'id' => 4015700103,
            'is_contraction' => 1,
            'is_node_significant' => 1,
            'lambda' => '2.48e-07',
            'name' => 'Gallus gallus',
            'n_members' => 0,
            'pvalue' => '0.0029',
            'p_value_lim' => '0.01',
            'tax' => {
              'id' => 9031,
              'common_name' => 'Chicken',
              'production_name' => 'gallus_gallus',
              'scientific_name' => 'Gallus gallus Galgal4',
              'timetree_mya' => 0,
            }
          },
          {
            'id' => 4015700111,
            'lambda' => '2.48e-07',
            'name' => 'Anas platyrhynchos',
            'n_members' => 1,
            'pvalue' => '0.5',
            'p_value_lim' => '0.01',
            'tax' => {
              'id' => 8839,
              'common_name' => 'Duck',
              'production_name' => 'anas_platyrhynchos',
              'scientific_name' => 'Anas platyrhynchos',
              'timetree_mya' => 0,
            },
          },
          {
            'id' => 4015700113,
            'lambda' => '2.48e-07',
            'name' => 'Meleagris gallopavo',
            'n_members' => 1,
            'pvalue' => '0.5',
            'p_value_lim' => '0.01',
            'tax' => {
              'id' => 9103,
              'common_name' => 'Turkey',
              'production_name' => 'meleagris_gallopavo',
              'scientific_name' => 'Meleagris gallopavo',
              'timetree_mya' => 0,
            },
          },
          {
            'id' => 4015700119,
            'lambda' => '2.48e-07',
            'name' => 'Ficedula albicollis',
            'n_members' => 1,
            'pvalue' => '0.5',
            'p_value_lim' => '0.01',
            'tax' => {
              'id' => 59894,
              'common_name' => 'Flycatcher',
              'production_name' => 'ficedula_albicollis',
              'scientific_name' => 'Ficedula albicollis',
              'timetree_mya' => 0,
            },
          }
        ],
      },
      {
        'id' => 4015700122,
        'lambda' => '2.48e-07',
        'name' => 'Anolis carolinensis',
        'n_members' => 1,
        'pvalue' => '0.5',
        'p_value_lim' => '0.01',
        'tax' => {
          'id' => 28377,
          'common_name' => 'Anole Lizard',
          'production_name' => 'anolis_carolinensis',
          'scientific_name' => 'Anolis carolinensis',
          'timetree_mya' => 0,
        }
      }
    ]
  },
  'type' => 'cafe tree',
};

# Children in "$bird_cafe_tree" are not always returned in the same order, so this function
# can be used to sort them in order to facilitate comparison with the expected value.
sub sort_json_cafe_tree_children {
    my ($cafe_json) = @_;
    my @nodes = ($cafe_json->{'tree'});
    while (my $node = shift @nodes) {
        if (exists $node->{'children'}) {
            $node->{'children'} = [sort { $a->{'id'} <=> $b->{'id'} } @{$node->{'children'}}];
            push(@nodes, @{$node->{'children'}});
        }
    }
    return $json;
}

my @stable_ids = (
    'ENSGALG00010013238',
    'ENSGALT00010013238',
    'ENSGALP00010013238',
    'ENSGALE00010013238_1',
);

my %stable_id_to_object_type = (
    'ENSGALG00010013238' => 'gene',
    'ENSGALT00010013238' => 'transcript',
    'ENSGALP00010013238' => 'translation',
    'ENSGALE00010013238_1' => 'exon',
);

foreach my $stable_id (@stable_ids) {
    my $object_type = $stable_id_to_object_type{$stable_id};

    $json = json_GET(
        "/cafe/genetree/member/id/meleagris_gallopavo/${stable_id}?compara=homology",
        "cafe tree using species and $object_type stable id",
    );
    ;
    eq_or_diff(
        sort_json_cafe_tree_children($json),
        $bird_cafe_tree,
        "Got the correct cafe species-tree by species name and $object_type stable id"
    );
}

done_testing();
