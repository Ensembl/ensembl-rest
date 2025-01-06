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
use Data::Dumper;

my $human = Bio::EnsEMBL::Test::MultiTestDB->new("homo_sapiens");
my $mult  = Bio::EnsEMBL::Test::MultiTestDB->new('multi');
my $dba = Bio::EnsEMBL::Test::MultiTestDB->new('homology');
Catalyst::Test->import('EnsEMBL::REST');

my ($json, $xml);

## Data
########

# First a method that nicely wraps the homology content
sub _get_returned_json {
    my $id = shift;
    return { 'data' => [ { 'homologies' => [ @_ ], 'id' => $id, } ] };
}

my $condensed_ortho_ENSG00000139618_gorilla = {
    'taxonomy_level' => 'Homininae',
    'protein_id' => 'ENSGGOP00000015446',
    'type' => 'ortholog_one2one',
    'id' => 'ENSGGOG00000015808',
    'species' => 'gorilla_gorilla',
    'method_link_type' => 'ENSEMBL_ORTHOLOGUES'
};

## "condensed" homologies with target species

is_json_GET(
    '/homology/id/homo_sapiens/ENSG00000139618?compara=homology;format=condensed;target_species=gorilla_gorilla;type=orthologues',
    _get_returned_json('ENSG00000139618', $condensed_ortho_ENSG00000139618_gorilla),
    '"condensed" homologies of human gene with a target species',
);

is_json_GET(
    '/homology/id/homo_sapiens/ENSG00000139618?format=condensed;target_species=gorilla_gorilla;type=orthologues', {data => []},
    'homologies without compara division specified',
);

is_json_GET(
    '/homology/id/homo_sapiens/ENSG00000139618?compara=homology;format=condensed;target_taxon=9595;type=orthologues',
    _get_returned_json('ENSG00000139618', $condensed_ortho_ENSG00000139618_gorilla),
    '"condensed" homologies with a target single-species taxon',
);

is_json_GET(
    '/homology/id/homo_sapiens/ENSG00000139618?compara=homology;format=condensed;target_taxon=9595;target_species=gorilla_gorilla;type=orthologues',
    _get_returned_json('ENSG00000139618', $condensed_ortho_ENSG00000139618_gorilla),
    '"condensed" homologies with overlapping targets',
);

$json = json_GET(
    '/homology/id/homo_sapiens/ENSG00000139618?compara=homology;format=condensed;target_species=pan_troglodytes;target_species=gorilla_gorilla;type=orthologues',
    '"condensed" homologies with non-overlapping targets',
);
is(scalar(@{$json->{data}->[0]->{homologies}}), 2, 'The "target_species" and "target_taxon" arguments are combined');

$json = json_GET(
    '/homology/id/homo_sapiens/ENSG00000139618?compara=homology;format=condensed;target_taxon=207598;type=orthologues',
    '"condensed" homologies with an ancestral taxon',
);
is(scalar(@{$json->{data}->[0]->{homologies}}), 2, 'Found both species under taxon ID 207598');

$json = json_GET(
    '/homology/id/homo_sapiens/ENSG00000139618?compara=homology;format=condensed;target_species=ornithorhynchus_anatinus;type=orthologues',
    '"condensed" homologies with a single target species but one-to-many homologies',
);
is(scalar(@{$json->{data}->[0]->{homologies}}), 2, 'We get all the one-to-many homologies even though there is 1 species');


## Total number of homologies without a filter
$json = json_GET(
    '/homology/id/homo_sapiens/ENSG00000139618?compara=homology;format=condensed;type=orthologues',
    '"condensed" homologies of human gene with no species filter',
);
is(scalar(@{$json->{data}->[0]->{homologies}}), 63, 'Got all the homologies of human gene');

## queries with a versioned gene member stable ID

my $condensed_ortho_ENSGALG00010013238_duck = {
    'id' => 'ENSAPLG00000024671',
    'method_link_type' => 'ENSEMBL_ORTHOLOGUES',
    'protein_id' => 'ENSAPLP00000029370',
    'species' => 'anas_platyrhynchos',
    'taxonomy_level' => 'Aves',
    'type' => 'ortholog_one2one'
};

is_json_GET(
    '/homology/id/meleagris_gallopavo/ENSGALG00010013238.1?compara=homology;format=condensed;target_species=anas_platyrhynchos;type=orthologues',
    _get_returned_json('ENSGALG00010013238.1', $condensed_ortho_ENSGALG00010013238_duck),
    'homologies of gene by species and versioned stable ID',
);

## queries with a clashing gene member stable ID

is_json_GET(
    '/homology/id/meleagris_gallopavo/ENSGALG00010013238?compara=homology;format=condensed;target_species=anas_platyrhynchos;type=orthologues',
    _get_returned_json('ENSGALG00010013238', $condensed_ortho_ENSGALG00010013238_duck),
    '"condensed" homologies using species name and gene stable ID',
);

## Only 1 target species in "full" mode

my $full_ortho_ENSG00000139618_gorilla = {
    'dn_ds' => undef,
    'source' => {
        'perc_pos' => 95,
        'perc_id' => 94,
        'protein_id' => 'ENSP00000369497',
        'taxon_id' => 9606,
        'id' => 'ENSG00000139618',
        'cigar_line' => '22MD3396M',
        'species' => 'homo_sapiens'
    },
    'taxonomy_level' => 'Homininae',
    'target' => {
        'perc_pos' => 98,
        'perc_id' => 97,
        'protein_id' => 'ENSGGOP00000015446',
        'taxon_id' => 9595,
        'id' => 'ENSGGOG00000015808',
        'cigar_line' => '98M7D563M4D615MD560M7D606M19D891M48D',
        'species' => 'gorilla_gorilla'
    },
    'type' => 'ortholog_one2one',
    'method_link_type' => 'ENSEMBL_ORTHOLOGUES'
};


is_json_GET(
    '/homology/id/homo_sapiens/ENSG00000139618?compara=homology;format=full;target_species=gorilla_gorilla;type=orthologues;sequence=none;aligned=0',
    _get_returned_json('ENSG00000139618', $full_ortho_ENSG00000139618_gorilla),
    '"full" homologies with a target species and no sequences at all',
);

$json = json_GET(
    '/homology/id/homo_sapiens/ENSG00000139618?target_species=gorilla_gorilla;format=full;type=orthologues;compara=homology;cigar_line=0',
    '"full" homologies with a target taxon (aligned protein)'
);
ok(!$json->{data}->[0]->{homologies}->[0]->{source}->{cigar_line}, 'No cigar_line');
like($json->{data}->[0]->{homologies}->[0]->{source}->{align_seq}, qr/^MPIGSKERPTFFEIFKTRCNKA-DLGPISLNW[A-Z]*TITTKKYI$/, 'Aligned human sequence');
like($json->{data}->[0]->{homologies}->[0]->{target}->{align_seq}, qr/^MPIGSKERPT[A-Z]*QSPVKE-------LGRNV[A-Z]*GTIL----RNETC[A-Z]*SEK-NKCQLI[A-Z]*FRIA-------SDETIKK[A-Z]*FNKN-------------------LITSLQ[A-Z]*ESTR------------------------------------------------$/, 'Aligned gorilla sequence');
ok(!$json->{data}->[0]->{homologies}->[0]->{source}->{seq}, 'No "seq" key since we asked for the alignment');

$json = json_GET(
    '/homology/id/homo_sapiens/ENSG00000139618?target_species=gorilla_gorilla;format=full;type=orthologues;compara=homology;aligned=0',
    '"full" homologies with a target taxon (unaligned protein)'
);
ok($json->{data}->[0]->{homologies}->[0]->{source}->{cigar_line}, 'Human cigar_line still there');
ok(!$json->{data}->[0]->{homologies}->[0]->{source}->{align_seq}, 'Human "align_seq" has gone');
like($json->{data}->[0]->{homologies}->[0]->{source}->{seq}, qr/^MPIGSKER[A-Z]*TITTKKYI$/, 'Human protein sequence');
like($json->{data}->[0]->{homologies}->[0]->{target}->{seq}, qr/^MPIGSKE[A-Z]*ESTR$/, 'Gorilla protein sequence');

$json = json_GET(
    '/homology/id/homo_sapiens/ENSG00000139618?target_species=gorilla_gorilla;format=full;type=orthologues;compara=homology;aligned=0;cigar_line=0',
    '"full" homologies with a target taxon (unaligned protein)'
);
ok(!$json->{data}->[0]->{homologies}->[0]->{source}->{cigar_line}, 'Human cigar_line has gone');
ok(!$json->{data}->[0]->{homologies}->[0]->{source}->{align_seq}, 'Human "align_seq" has gone');
ok($json->{data}->[0]->{homologies}->[0]->{source}->{seq}, 'The sequence is still there');

$json = json_GET(
    '/homology/id/homo_sapiens/ENSG00000139618?target_species=gorilla_gorilla;format=full;type=orthologues;compara=homology;aligned=0;sequence=cdna',
    '"full" homologies with a target taxon (unaligned transcript sequence)'
);
ok($json->{data}->[0]->{homologies}->[0]->{source}->{cigar_line}, 'Human cigar_line still there');
ok(!$json->{data}->[0]->{homologies}->[0]->{source}->{align_seq}, 'Human "align_seq" has gone');
like($json->{data}->[0]->{homologies}->[0]->{source}->{seq}, qr/^ATGCCTAT[ACGT]*AATATATCTAA$/, 'Human transcript sequence');
like($json->{data}->[0]->{homologies}->[0]->{target}->{seq}, qr/^ATGCCTAT[ACGT]*AATCCACTAGG$/, 'Gorilla transcript sequence');



my $condensed_para_ENSG00000238707 = {
    'taxonomy_level' => 'Eutheria',
    'protein_id' => 'ENST00000459163',
    'type' => 'within_species_paralog',
    'id' => 'ENSG00000176515',
    'species' => 'homo_sapiens',
    'method_link_type' => 'ENSEMBL_PARALOGUES'
};

is_json_GET(
    '/homology/id/homo_sapiens/ENSG00000238707?format=condensed;type=paralogues;compara=homology',
    _get_returned_json('ENSG00000238707', $condensed_para_ENSG00000238707),
    '"condensed" human paralogues'
);

# Aliases are somehow not loaded yet, so we need to add one here
Bio::EnsEMBL::Registry->add_alias('homo_sapiens', 'human');

my $condensed_para_ENSG00000176515 = {
    'taxonomy_level' => 'Eutheria',
    'protein_id' => 'ENST00000458762',
    'type' => 'within_species_paralog',
    'id' => 'ENSG00000238707',
    'species' => 'homo_sapiens',
    'method_link_type' => 'ENSEMBL_PARALOGUES'
};

is_json_GET(
    '/homology/symbol/human/AL033381.1?format=condensed;type=paralogues;compara=homology',
    _get_returned_json('ENSG00000176515', $condensed_para_ENSG00000176515),
    'paralogues via the gene symbol'
);

is_json_GET(
    '/homology/id/human/ENSG00000176515?format=condensed;type=paralogues;compara=homology',
    _get_returned_json('ENSG00000176515', $condensed_para_ENSG00000176515),
    'paralogues via the species alias and gene stable ID'
);

my $full_ortho_ENSG00000238707_zebrafish = {
    'dn_ds' => undef,
    'source' => {
        'perc_pos' => 62,
        'protein_id' => 'ENST00000458762',
        'taxon_id' => 9606,
        'species' => 'homo_sapiens',
        'cigar_line' => '15MD54M',
        'perc_id' => 62,
        'align_seq' => 'TGATGAATTGATGAC-AGTCATCTTTTGAGAGTGACCCAAAATGAAAAGAATACTCATTGCTGATCACTT',
        'id' => 'ENSG00000238707'
    },
    'taxonomy_level' => 'Eutheria',
    'target' => {
        'perc_pos' => 70,
        'protein_id' => 'ENSDORT00000020200',
        'taxon_id' => 10020,
        'species' => 'dipodomys_ordii',
        'cigar_line' => '9D61M',
        'perc_id' => 70,
        'align_seq' => '---------AAGAGTACATAATACTTTGGAACTGACCTAAAATAAAGAGAATATTCATTGCTGATCACTT',
        'id' => 'ENSDORG00000020862'
    },
    'type' => 'ortholog_one2one',
    'method_link_type' => 'ENSEMBL_ORTHOLOGUES'
};

is_json_GET(
    '/homology/id/homo_sapiens/ENSG00000238707?target_species=dipodomys_ordii;format=full;type=orthologues;compara=homology',
    _get_returned_json('ENSG00000238707', $full_ortho_ENSG00000238707_zebrafish),
    'one2one ncRNA orthologue with aligned sequence',
);

$full_ortho_ENSG00000238707_zebrafish->{source}->{seq} = $full_ortho_ENSG00000238707_zebrafish->{source}->{align_seq};
$full_ortho_ENSG00000238707_zebrafish->{source}->{seq} =~ s/-//g;
delete $full_ortho_ENSG00000238707_zebrafish->{source}->{align_seq};

$full_ortho_ENSG00000238707_zebrafish->{target}->{seq} = $full_ortho_ENSG00000238707_zebrafish->{target}->{align_seq};
$full_ortho_ENSG00000238707_zebrafish->{target}->{seq} =~ s/-//g;
delete $full_ortho_ENSG00000238707_zebrafish->{target}->{align_seq};

is_json_GET(
    '/homology/id/homo_sapiens/ENSG00000238707?target_species=dipodomys_ordii;format=full;aligned=0;type=orthologues;compara=homology',
    _get_returned_json('ENSG00000238707', $full_ortho_ENSG00000238707_zebrafish),
    'one2one ncRNA orthologue with unaligned sequence (but still a cigar_line)',
);

# sequence=cdna still works for ncRNAs
is_json_GET(
    '/homology/id/homo_sapiens/ENSG00000238707?target_species=dipodomys_ordii;format=full;aligned=0;type=orthologues;compara=homology;sequence=cdna',
    _get_returned_json('ENSG00000238707', $full_ortho_ENSG00000238707_zebrafish),
    'one2one ncRNA orthologue with unaligned sequence (but still a cigar_line)',
);

# sequence=protein is ignored for ncRNAs
is_json_GET(
    '/homology/id/homo_sapiens/ENSG00000238707?target_species=dipodomys_ordii;format=full;aligned=0;type=orthologues;compara=homology;sequence=protein',
    _get_returned_json('ENSG00000238707', $full_ortho_ENSG00000238707_zebrafish),
    'one2one ncRNA orthologue with unaligned sequence (but still a cigar_line)',
);

$xml = orthoxml_GET(
    '/homology/id/homo_sapiens/ENSG00000238707?target_species=dipodomys_ordii;type=orthologues;compara=homology',
    'orthoxml with 1 target species',
);
subtest 'OrthoXML file', sub {
    my $tx = Test::XPath->new(xml => $xml, xmlns => { x => "http://www.w3.org/2001/XMLSchema-instance", o => "http://orthoXML.org/2011/"});

    $tx->is('count(//o:species)', 2, "number of species");
    $tx->is('count(//o:database)', 2, "number of databases");
    $tx->is('count(//o:gene)', 2, "number of genes");
    $tx->is('count(//o:gene[@geneId="ENSG00000238707"])', 1, "gene is found");
    $tx->ok('//o:gene[@geneId="ENSG00000238707"]', sub {
            my $node = shift->node;
            is($node->getAttribute('transcriptId'), 'ENST00000458762', 'transcript is correct');
            is($node->getAttribute('id'), '100178494', 'dbID is correct');
        }, "gene entry is complete");
    $tx->is('count(//o:orthologGroup)', 1, "number of orthologies");
    my $expected_orthoxml_properties = {
        'taxon_name' => 'Eutheria',
        'taxon_id' => 9347,
        'common_name' => 'Placental mammals',
        'description' => 'ortholog_one2one',
        'is_tree_compliant' => 0,
        'timetree_mya' => '104.2',
    };
    $tx->ok('//o:orthologGroup', sub {
            $_->ok('./o:property', sub {
                    my $node = shift->node;
                    ok(exists $expected_orthoxml_properties->{$node->getAttribute('name')}, 'the property '.$node->getAttribute('name').' is expected');
                    is($expected_orthoxml_properties->{$node->getAttribute('name')}, $node->getAttribute('value'), 'the property '.$node->getAttribute('name').' has the correct value');
                }, 'orthologGroup properties');
            $_->is('count(./o:geneRef)', 2, "number of genes in the orthology");
            $_->ok('./o:geneRef[@id="100178494"]', sub {
                    $_->ok('./o:score[@id="perc_identity"]', sub {
                            is(shift->node->getAttribute('value'), 62, '%id');
                        }, 'perc_identity key');
                }, "human gene is complete");
        }, "orthologGroup entry is complete");
};

$xml = orthoxml_GET(
    '/homology/id/homo_sapiens/ENSG00000139618?compara=homology;format=condensed;type=orthologues',
    'orthoxml with many homologies',
);
subtest 'OrthoXML file', sub {
    my $tx = Test::XPath->new(xml => $xml, xmlns => { x => "http://www.w3.org/2001/XMLSchema-instance", o => "http://orthoXML.org/2011/"});
    $tx->is('count(//o:orthologGroup)', 63, 'Got all the homologies');
    $tx->is('count(//o:species)', 62, 'Some species have paralogs, so there are fewer species than orthologies');
    $tx->is('count(//o:gene)', 64, 'n_homologies+1');
};

#action_bad("/taxonomyid/-1", 'ID should not be found.');
#action_bad("/taxonomy/classification?A;content-type=application/json", 'Classification in bad data case');

done_testing();
