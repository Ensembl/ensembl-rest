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
use Catalyst::Test ();
use Bio::EnsEMBL::Test::MultiTestDB;

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new();
Catalyst::Test->import('EnsEMBL::REST');

my $basic_id = 'ENSG00000176515';
my $symbol = "AL033381.1";
my $condensed_response = {object_type => 'Gene', db_type => 'core', species => 'homo_sapiens', id => $basic_id, version => 1};

is_json_GET("/lookup/id/$basic_id?format=condensed", $condensed_response, 'Get of a known ID will return a value');
is_json_GET("/lookup/$basic_id?format=condensed", $condensed_response, 'Get of a known ID to the old URL will return a value');

my $full_response = {
  %{$condensed_response},
  start => 1080164, end => 1105181, strand => 1, version => 1, seq_region_name => '6', assembly_name => 'GRCh37',
  biotype => 'protein_coding', display_name => 'AL033381.1', logic_name => 'ensembl', source => 'ensembl', canonical_transcript => 'ENST00000314040.1',
  description => 'Uncharacterized protein; cDNA FLJ34594 fis, clone KIDNE2009109  [Source:UniProtKB/TrEMBL;Acc:Q8NAX6]'
};
cmp_deeply(json_GET("/lookup/$basic_id",'lookup a gene'), $full_response, 'Get of a known ID to the old URL will return a value');

my $expanded_response = {
  %{$condensed_response},
  Transcript => [
                 {object_type => 'Transcript', db_type => 'core', species => 'homo_sapiens', id => 'ENST00000314040',version => 1,
 Translation => {object_type => 'Translation', db_type => 'core', species => 'homo_sapiens', id => 'ENSP00000320396', version => 1},
        Exon =>
                [
                 {object_type => 'Exon', db_type => 'core', species => 'homo_sapiens', id => 'ENSE00001271861', version => 1},
                 {object_type => 'Exon', db_type => 'core', species => 'homo_sapiens', id => 'ENSE00001271874', version => 1},
                 {object_type => 'Exon', db_type => 'core', species => 'homo_sapiens', id => 'ENSE00001271869', version => 1}
                ]
                }]
                };
cmp_deeply(json_GET("/lookup/id/$basic_id?expand=1;format=condensed",'lookup an expanded gene'), $expanded_response, 'Get of a known ID with expanded option will return transcripts as well');

my $id_with_phenotype = 'ENSG00000137273';
my $phenotype_response = {
	object_type => 'Gene', db_type => 'core', species => 'homo_sapiens', id => $id_with_phenotype, version => 3,
	phenotypes => [
    {genes => undef,source => 'GOA',study => 'PMID:8626802',trait => 'positive regulation of transcription from RNA polymerase II promoter', variants => undef},
    {genes => undef,source => 'GOA',study => 'PMID:8626802',trait => 'soft palate development', ontology_accessions => [ 'GO:0060023'], variants => undef}
   ],};
cmp_deeply(json_GET("/lookup/id/$id_with_phenotype?phenotypes=1;format=condensed",'lookup a gene with phenotypes'), $phenotype_response, 'Get of a known gene ID with phenotypes option will return phenotypes as well');

my $utr_response = {
  %{$condensed_response},
  Transcript => [
                 {object_type => 'Transcript', db_type => 'core', species => 'homo_sapiens', id => 'ENST00000314040', version => 1,
 Translation => {object_type => 'Translation', db_type => 'core', species => 'homo_sapiens', id => 'ENSP00000320396', version => 1},
         UTR => [
                {object_type => 'five_prime_UTR', db_type => 'core', species => 'homo_sapiens', id => 'ENST00000314040'},
                {object_type => 'five_prime_UTR', db_type => 'core', species => 'homo_sapiens', id => 'ENST00000314040'},
                {object_type => 'three_prime_UTR', db_type => 'core', species => 'homo_sapiens', id => 'ENST00000314040'}
                ],
        Exon =>
                [
                 {object_type => 'Exon', db_type => 'core', species => 'homo_sapiens', id => 'ENSE00001271861', version => 1},
                 {object_type => 'Exon', db_type => 'core', species => 'homo_sapiens', id => 'ENSE00001271874', version => 1},
                 {object_type => 'Exon', db_type => 'core', species => 'homo_sapiens', id => 'ENSE00001271869', version => 1}
                ]
                }]
                };

cmp_deeply(json_GET("/lookup/id/$basic_id?expand=1;utr=1;format=condensed",'lookup gene with UTRs'), $utr_response, 'Get of a known ID with utr option will return UTRs as well');

cmp_deeply(json_GET("/lookup/symbol/homo_sapiens/$symbol?expand=1;format=condensed",'lookup symbol with expand'), $expanded_response, 'Get of a known symbol returns the same result as with stable id');
json_GET("/lookup/symbol/homo_sapiens/$symbol?expand=1", "Extended response works");

action_bad("/lookup/id/${basic_id}extra", 'ID should not be found. Fail');

# Test with a transcript

$basic_id = 'ENST00000314040';
$condensed_response = {object_type => 'Transcript', db_type => 'core', species => 'homo_sapiens', id => $basic_id, version => 1};

cmp_deeply(json_GET("/lookup/id/$basic_id?format=condensed",'lookup transcript in condensed format'), $condensed_response, 'Get of a known ID will return a value');
cmp_deeply(json_GET("/lookup/$basic_id?format=condensed", 'lookup transcript via old URL'), $condensed_response, 'Get of a known ID to the old URL will return a value');

$full_response = {
  %{$condensed_response},
  Parent => 'ENSG00000176515', start => 1080164, end => 1105181, strand => 1, version => 1, seq_region_name => '6', assembly_name => 'GRCh37',
  biotype => 'protein_coding', display_name => 'AL033381.1-201', logic_name => 'ensembl', source => 'ensembl',
  is_canonical => 1, length => 3435, gencode_primary => 0,
};
cmp_deeply(json_GET("/lookup/$basic_id",'lookup transcript'), $full_response, 'Full response contains all Transcript information');

$expanded_response = {
  %{$condensed_response},
 Translation => {object_type => 'Translation', db_type => 'core', species => 'homo_sapiens', id => 'ENSP00000320396', version => 1},
        Exon =>
                [
                 {object_type => 'Exon', db_type => 'core', species => 'homo_sapiens', id => 'ENSE00001271861', version => 1},
                 {object_type => 'Exon', db_type => 'core', species => 'homo_sapiens', id => 'ENSE00001271874', version => 1},
                 {object_type => 'Exon', db_type => 'core', species => 'homo_sapiens', id => 'ENSE00001271869', version => 1}
                ]
                };
cmp_deeply(json_GET("/lookup/id/$basic_id?expand=1;format=condensed",'Expanded transcript by ID'), $expanded_response, 'Get of a known ID with expanded option will return transcripts as well');

$utr_response = {
  %{$condensed_response},
 Translation => {object_type => 'Translation', db_type => 'core', species => 'homo_sapiens', id => 'ENSP00000320396', version => 1},
         UTR => [
                {object_type => 'five_prime_UTR', db_type => 'core', species => 'homo_sapiens', id => 'ENST00000314040'},
                {object_type => 'five_prime_UTR', db_type => 'core', species => 'homo_sapiens', id => 'ENST00000314040'},
                {object_type => 'three_prime_UTR', db_type => 'core', species => 'homo_sapiens', id => 'ENST00000314040'}
                ],
        Exon =>
                [
                 {object_type => 'Exon', db_type => 'core', species => 'homo_sapiens', id => 'ENSE00001271861', version => 1},
                 {object_type => 'Exon', db_type => 'core', species => 'homo_sapiens', id => 'ENSE00001271874', version => 1},
                 {object_type => 'Exon', db_type => 'core', species => 'homo_sapiens', id => 'ENSE00001271869', version => 1}
                ]
                };

cmp_deeply(json_GET("/lookup/id/$basic_id?expand=1;utr=1;format=condensed",'Transcript by ID with UTR'), $utr_response, 'Get of a known ID with utr option will return UTRs as well');

# Test with MANE
$basic_id = 'ENST00000296839';
$condensed_response = {object_type => 'Transcript', db_type => 'core', species => 'homo_sapiens', id => $basic_id, version => 1};

$full_response = {
  %{$condensed_response},
  Parent => 'ENSG00000164379', start => 1312675, end => 1314992, strand => 1, version => 2, seq_region_name => '6', assembly_name => 'GRCh37',
  biotype => 'protein_coding', display_name => 'FOXQ1-001', logic_name => 'ensembl_havana_transcript', source => 'ensembl',
  is_canonical => 1, length => 2318, gencode_primary => 1,
};
cmp_deeply(json_GET("/lookup/$basic_id",'lookup transcript'), $full_response, 'Full response contains all Transcript information');

$expanded_response = {
  %{$full_response},
 Translation => {object_type => 'Translation', db_type => 'core', species => 'homo_sapiens', id => 'ENSP00000296839', version => 2,
                 start => 1312940, end => 1314151, length => 403, Parent => 'ENST00000296839'},
        MANE => [ {object_type => 'mane', db_type => 'core', species => 'homo_sapiens', id => 'ENST00000296839', version => 5,
                 start => 1312675, end => 1314992, strand => 1, version => 2, seq_region_name => '6', Parent => 'ENSG00000164379', assembly_name => 'GRCh37',
                  type => 'MANE_Select', refseq_match => 'NM_033260.4'}],
        Exon =>
                [
                 {object_type => 'Exon', db_type => 'core', species => 'homo_sapiens', id => 'ENSE00001083937', version => 3,
                  assembly_name => 'GRCh37', start => 1312675, end => 1314992, seq_region_name => 6, strand => 1},
                ]
                };
cmp_deeply(json_GET("/lookup/id/$basic_id?expand=1;mane=1",'Expanded transcript by ID'), $expanded_response, 'Get of a known ID with expanded option will return transcripts as well');



# Test POST endpoints


my $id_body = qq{
 {
    "ids" : [
              "ENSG00000167393"
            ] 
 }
};

my $id_response = {
  ENSG00000167393 => {
    source => "ensembl",
    object_type => "Gene",
    logic_name => "ensembl_havana_gene",
    species => "homo_sapiens",
    description => "protein phosphatase 2, regulatory subunit B'', beta [Source:HGNC Symbol;Acc:13417]",
    display_name => "PPP2R3B",
    biotype => "protein_coding",
    end => 347690,
    seq_region_name => "X",
    db_type => "core",
    strand => -1,
    version => 12,
    id => "ENSG00000167393",
    assembly_name => 'GRCh37',
    start => 294698,
    canonical_transcript => 'ENST00000390665.3'
  }
};
# use Data::Dumper;
# my $tribble = do_POST("/lookup/id",$id_body);
# note('trouble at mill:'.Dumper $tribble);
cmp_deeply(json_POST("/lookup/id",$id_body,'POST lookup by ID'),$id_response,"Try to do an ID post query");

my $symbol_response = {
    'AL033381.1' => {                                                                                                         
    biotype => 'protein_coding',
    db_type => 'core',
    description => 'Uncharacterized protein; cDNA FLJ34594 fis, clone KIDNE2009109  [Source:UniProtKB/TrEMBL;Acc:Q8NAX6]',
    display_name => 'AL033381.1',
    end => 1105181,
    id => 'ENSG00000176515',
    logic_name => 'ensembl',
    object_type => 'Gene',
    seq_region_name => '6',
    source => 'ensembl',
    species => 'homo_sapiens',
    start => 1080164,
    assembly_name => 'GRCh37',
    strand => 1,
    version => 1,
    canonical_transcript => 'ENST00000314040.1'
  },

  snoU13 => {
    biotype => 'snoRNA',
    db_type => 'core',
    description => 'Small nucleolar RNA U13 [Source:RFAM;Acc:RF01210]',
    display_name => 'snoU13',
    end => 1186855,
    id => 'ENSG00000238438',
    logic_name => 'ncrna',
    object_type => 'Gene',
    seq_region_name => '6',
    source => 'ensembl',
    species => 'homo_sapiens',
    start => 1186753,
    assembly_name => 'GRCh37',
    strand => 1,
    version => 1,
    canonical_transcript => 'ENST00000459140.1'
  } 
};
my $symbol_body = qq{ 
{
  "symbols" : [ "snoU13","AL033381.1","falsetest" ]
}
};

cmp_deeply(json_POST("/lookup/symbol/homo_sapiens",$symbol_body,'POST lookup by symbol'),$symbol_response,"Try to POST symbol query");

done_testing();
