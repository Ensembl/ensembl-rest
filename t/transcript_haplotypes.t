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
use Bio::EnsEMBL::Test::MultiTestDB;
use Data::Dumper;
use Bio::EnsEMBL::Test::TestUtils;
use Catalyst::Test();

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');
my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('multi');
Catalyst::Test->import('EnsEMBL::REST');

my ($th_get, $json, $expected_output);

$th_get = '/transcript_haplotypes/homo_sapiens/ENST00000314040';
$json = json_GET($th_get, 'GET transcript haplotypes for ENST00000314040');
$expected_output = {
  'total_population_counts' => { _all => 4 },
  'protein_haplotypes' => [
    {
      'count' => 2,
      'flags' => [],
      'population_counts' => { _all => 2 },
      'name' => 'ENSP00000320396:REF',
      'other_hexes' => {
        'a4fd92d6dce22c4c419d07b6278c63bd' => 1
      },
      'frequency' => '0.5',
      'type' => 'protein',
      'population_frequencies' => { _all => 0.5 },
      'hex' => '3a9ac3283858fcddbf5935a58e51899e',
      'diffs' => [],
      'contributing_variants' => [],
      'has_indel' => 0
    },
    {
      'count' => 1,
      'flags' => [],
      'population_counts' => { _all => 1 },
      'name' => 'ENSP00000320396:22A>V',
      'other_hexes' => {
        'fd753b22ce52698f9af398b40ec42163' => 1
      },
      'frequency' => '0.25',
      'type' => 'protein',
      'population_frequencies' => { _all => 0.25 },
      'hex' => '31c01f1c180d58287b3f950852d4673f',
      'diffs' => [
        {
          'diff' => '22A>V'
        }
      ],
      'contributing_variants' => [ 'rs147768956' ],
      'has_indel' => 0
    },
    {
      'count' => 1,
      'flags' => [],
      'population_counts' => { _all => 1 },
      'name' => 'ENSP00000320396:101C>Y',
      'other_hexes' => {
        '7b5a799b2ebb572601751cd89c1cacd7' => 1
      },
      'frequency' => '0.25',
      'type' => 'protein',
      'population_frequencies' => { _all => 0.25 },
      'hex' => 'd45b8552801fe8f7e9aa2d9c0ba17961',
      'diffs' => [
        {
          'diff' => '101C>Y'
        }
      ],
      'contributing_variants' => [ 'rs137980927' ],
      'has_indel' => 0
    }
  ],
  'cds_haplotypes' => [
    {
      'count' => 2,
      'population_counts' => { _all => 2 },
      'other_hexes' => {
        '3a9ac3283858fcddbf5935a58e51899e' => 1
      },
      'name' => 'ENST00000314040:REF',
      'frequency' => '0.5',
      'type' => 'cds',
      'hex' => 'a4fd92d6dce22c4c419d07b6278c63bd',
      'population_frequencies' => { _all => 0.5 },
      'diffs' => [],
      'contributing_variants' => [],
      'has_indel' => 0
    },
    {
      'count' => 1,
      'population_counts' => { _all => 1 },
      'other_hexes' => {
        'd45b8552801fe8f7e9aa2d9c0ba17961' => 1
      },
      'name' => 'ENST00000314040:302G>A',
      'frequency' => '0.25',
      'type' => 'cds',
      'hex' => '7b5a799b2ebb572601751cd89c1cacd7',
      'population_frequencies' => { _all => 0.25 },
      'diffs' => [
        {
          'variation_feature' => 'rs137980927',
          'variation_feature_id' => '126836726',
          'diff' => '302G>A'
        }
      ],
      'contributing_variants' => [ 'rs137980927' ],
      'has_indel' => 0
    },
    {
      'count' => 1,
      'population_counts' => { _all => 1 },
      'other_hexes' => {
        '31c01f1c180d58287b3f950852d4673f' => 1
      },
      'name' => 'ENST00000314040:65C>T',
      'frequency' => '0.25',
      'type' => 'cds',
      'hex' => 'fd753b22ce52698f9af398b40ec42163',
      'population_frequencies' => { _all => 0.25 },
      'diffs' => [
        {
          'variation_feature' => 'rs147768956',
          'variation_feature_id' => '135041170',
          'diff' => '65C>T'
        }
      ],
      'contributing_variants' => [ 'rs147768956' ],
      'has_indel' => 0
    }
  ],
  'transcript_id' => 'ENST00000314040',
  'total_haplotype_count' => 4
};

cmp_deeply($json, $expected_output, "Example transcript");

# request sequence
$th_get = '/transcript_haplotypes/homo_sapiens/ENST00000314040?sequence=1';
$json = json_GET($th_get, 'GET sequence for haplotypes');

$expected_output = {
  '3a9ac3283858fcddbf5935a58e51899e' => 'MLSPLWLQISKRPRPEVSVSNACFSSALPTSNPTSLTLKHHNIFVLRVALEIIQYSVHGGRNRKPLEVTSLAYSCPENWWQKQIGVQPPDVHASALSPKPCVSWSRPLSLLSSTILFWKTHDERADFSKLHS*',
  'd45b8552801fe8f7e9aa2d9c0ba17961' => 'MLSPLWLQISKRPRPEVSVSNACFSSALPTSNPTSLTLKHHNIFVLRVALEIIQYSVHGGRNRKPLEVTSLAYSCPENWWQKQIGVQPPDVHASALSPKPYVSWSRPLSLLSSTILFWKTHDERADFSKLHS*',
  '31c01f1c180d58287b3f950852d4673f' => 'MLSPLWLQISKRPRPEVSVSNVCFSSALPTSNPTSLTLKHHNIFVLRVALEIIQYSVHGGRNRKPLEVTSLAYSCPENWWQKQIGVQPPDVHASALSPKPCVSWSRPLSLLSSTILFWKTHDERADFSKLHS*'
};

cmp_deeply({map {$_->{hex} => $_->{seq}} @{$json->{protein_haplotypes}}}, $expected_output, "Example transcript with sequence");

# request aligned sequences
$th_get = '/transcript_haplotypes/homo_sapiens/ENST00000314040?aligned_sequences=1';
$json = json_GET($th_get, 'GET aligned_sequences for haplotypes');

$expected_output = {
  '3a9ac3283858fcddbf5935a58e51899e' => [
    'MLSPLWLQISKRPRPEVSVSNACFSSALPTSNPTSLTLKHHNIFVLRVALEIIQYSVHGGRNRKPLEVTSLAYSCPENWWQKQIGVQPPDVHASALSPKPCVSWSRPLSLLSSTILFWKTHDERADFSKLHS*',
    'MLSPLWLQISKRPRPEVSVSNACFSSALPTSNPTSLTLKHHNIFVLRVALEIIQYSVHGGRNRKPLEVTSLAYSCPENWWQKQIGVQPPDVHASALSPKPCVSWSRPLSLLSSTILFWKTHDERADFSKLHS*'
  ],
  'd45b8552801fe8f7e9aa2d9c0ba17961' => [
    'MLSPLWLQISKRPRPEVSVSNACFSSALPTSNPTSLTLKHHNIFVLRVALEIIQYSVHGGRNRKPLEVTSLAYSCPENWWQKQIGVQPPDVHASALSPKPCVSWSRPLSLLSSTILFWKTHDERADFSKLHS*',
    'MLSPLWLQISKRPRPEVSVSNACFSSALPTSNPTSLTLKHHNIFVLRVALEIIQYSVHGGRNRKPLEVTSLAYSCPENWWQKQIGVQPPDVHASALSPKPYVSWSRPLSLLSSTILFWKTHDERADFSKLHS*'
  ],
  '31c01f1c180d58287b3f950852d4673f' => [
    'MLSPLWLQISKRPRPEVSVSNACFSSALPTSNPTSLTLKHHNIFVLRVALEIIQYSVHGGRNRKPLEVTSLAYSCPENWWQKQIGVQPPDVHASALSPKPCVSWSRPLSLLSSTILFWKTHDERADFSKLHS*',
    'MLSPLWLQISKRPRPEVSVSNVCFSSALPTSNPTSLTLKHHNIFVLRVALEIIQYSVHGGRNRKPLEVTSLAYSCPENWWQKQIGVQPPDVHASALSPKPCVSWSRPLSLLSSTILFWKTHDERADFSKLHS*'
  ]
};

cmp_deeply({map {$_->{hex} => $_->{aligned_sequences}} @{$json->{protein_haplotypes}}}, $expected_output, "Example transcript with aligned_sequences");


# request samples
$th_get = '/transcript_haplotypes/homo_sapiens/ENST00000314040?samples=1';
$json = json_GET($th_get, 'GET samples for haplotypes');

$expected_output = {
  'a4fd92d6dce22c4c419d07b6278c63bd' => {
    'NA18499' => 1,
    'NA12003' => 1
  },
  '7b5a799b2ebb572601751cd89c1cacd7' => {
    'NA12003' => 1
  },
  'fd753b22ce52698f9af398b40ec42163' => {
    'NA18499' => 1
  }
};

cmp_deeply({map {$_->{hex} => $_->{samples}} @{$json->{cds_haplotypes}}}, $expected_output, "Example transcript with samples");


done_testing();
