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
use Data::Dumper;

my $human = Bio::EnsEMBL::Test::MultiTestDB->new("homo_sapiens");
my $chicken = Bio::EnsEMBL::Test::MultiTestDB->new('gallus_gallus');
my $turkey = Bio::EnsEMBL::Test::MultiTestDB->new('meleagris_gallopavo');
my $mult  = Bio::EnsEMBL::Test::MultiTestDB->new('multi');
my $dba = Bio::EnsEMBL::Test::MultiTestDB->new('homology');
Catalyst::Test->import('EnsEMBL::REST');

my ($json, $xml, $nh);


# Only getting a sub-tree here because the full tree is too big
my $restricted_RF01299 = {
    'tree' => {
        'branch_length' => 0,
        'events' => {
            'type' => 'speciation'
        },
        'taxonomy' => {
            'scientific_name' => 'Eutheria',
            'common_name' => 'Placental mammals',
            'id' => 9347,
            'timetree_mya' => '104.2'
        },
        'confidence' => {},
        'children' => [
            {
                'sequence' => {
                    'location' => '3:186784796-186784864',
                    'mol_seq' => {
                        'seq' => 'AAGTGAAATGATGGCAATCATCTTTCGGGACTGACCTGAAATGAAGAGAATACTCATTGCTGATCACTT',
                        'is_aligned' => 0
                    },
                    'name' => 'SNORD2-201',
                    'id' => [
                        {
                            'source' => 'EnsEMBL',
                            'accession' => 'ENST00000459163'
                        }
                    ]
                },
                'branch_length' => 0.1,
                'taxonomy' => {
                    'scientific_name' => 'Homo sapiens',
                    'common_name' => 'Human',
                    'id' => 9606
                },
                'confidence' => {},
                'id' => {
                    'source' => 'EnsEMBL',
                    'accession' => 'ENSG00000176515'
                }
            },
            {
                'sequence' => {
                    'location' => '3:188240400-188240468',
                    'mol_seq' => {
                        'seq' => 'AAGTGAAATGATGGCAATCATCTTTCGGGACTGACCTGAAATGAAGAGAATACTCATTGCTGATCACTT',
                        'is_aligned' => 0
                    },
                    'name' => 'SNORD2-201',
                    'id' => [
                        {
                            'source' => 'EnsEMBL',
                            'accession' => 'ENSGGOT00000038576'
                        }
                    ]
                },
                'branch_length' => 0.2,
                'taxonomy' => {
                    'scientific_name' => 'Gorilla gorilla gorilla',
                    'common_name' => 'Gorilla',
                    'id' => 9595
                },
                'confidence' => {},
                'id' => {
                    'source' => 'EnsEMBL',
                    'accession' => 'ENSGGOG00000032407'
                }
            }
        ]
    },
    'rooted' => 1,
    'type' => 'gene tree',
    'id' => 'RF01299'
};

is_json_GET(
    '/genetree/id/RF01299?compara=homology;subtree_node_id=100462673',
    $restricted_RF01299,
    'Gene-tree (ncRNA) by ID pruned to a subtree',
);

is_json_GET(
    '/genetree/member/id/homo_sapiens/ENSG00000176515?compara=homology;subtree_node_id=100462673',
    $restricted_RF01299,
    'Gene-tree (ncRNA) by species name and gene ID, pruned to a subtree',
);

is_json_GET(
    '/genetree/member/id/homo_sapiens/ENST00000314040?compara=homology;subtree_node_id=100462673',
    $restricted_RF01299,
    'Gene-tree (ncRNA) by species name and transcript stable ID, pruned to a subtree',
);

# Aliases are somehow not loaded yet, so we need to add one here
Bio::EnsEMBL::Registry->add_alias('homo_sapiens', 'human');

is_json_GET(
    '/genetree/member/symbol/human/AL033381.1?compara=homology;subtree_node_id=100462673',
    $restricted_RF01299,
    'Gene-tree (ncRNA) by transcript ID pruned to a subtree',
);

is_json_GET(
    '/genetree/member/id/human/ENST00000314040?compara=homology;subtree_node_id=100462673',
    $restricted_RF01299,
    'Gene-tree (ncRNA) by species alias and transcript ID, pruned to a subtree',
);

my $rodents_RF01299 = {
    'tree' => {
        'branch_length' => '0.00724822',
        'events' => {
            'type' => 'speciation'
        },
        'taxonomy' => {
            'scientific_name' => 'Eutheria',
            'common_name' => 'Placental mammals',
            'id' => 9347,
            'timetree_mya' => '104.2'
        },
        'confidence' => {
            'bootstrap' => 33
        },
        'children' => [
            {
                'sequence' => {
                    'location' => '16:23108953-23109021',
                    'mol_seq' => {
                        'seq' => 'AAGTGAAATGATGGCAAATCATCTTTCGGGACTGACCTGAAATGAAGAGAATACTCTTGCTGATCACTT',
                        'is_aligned' => 0
                    },
                    'name' => 'Snord2-201',
                    'id' => [
                        {
                            'source' => 'EnsEMBL',
                            'accession' => 'ENSMUST00000157899'
                        }
                    ]
                },
                'branch_length' => 0,
                'taxonomy' => {
                    'scientific_name' => 'Mus musculus',
                    'common_name' => 'Mouse',
                    'id' => 10090
                },
                'confidence' => {},
                'id' => {
                    'source' => 'EnsEMBL',
                    'accession' => 'ENSMUSG00000088524'
                }
            },
            {
                'sequence' => {
                    'location' => '11:81378396-81378464',
                    'mol_seq' => {
                        'seq' => 'AAGTGAAATGATGGCAATCATCTTTCGGGACTGACCTGAAATGAAGAGAAAACTCTCTGCTGATCACTT',
                        'is_aligned' => 0
                    },
                    'name' => 'SNORD2.1-201',
                    'id' => [
                        {
                            'source' => 'EnsEMBL',
                            'accession' => 'ENSRNOT00000090592'
                        }
                    ]
                },
                'branch_length' => '0.0294118',
                'taxonomy' => {
                    'scientific_name' => 'Rattus norvegicus',
                    'common_name' => 'Rat',
                    'id' => 10116
                },
                'confidence' => {},
                'id' => {
                    'source' => 'EnsEMBL',
                    'accession' => 'ENSRNOG00000053621'
                }
            }
        ]
    },
    'rooted' => 1,
    'type' => 'gene tree',
    'id' => 'RF01299'
};

is_json_GET(
    '/genetree/id/RF01299?compara=homology;prune_taxon=39107',
    $rodents_RF01299,
    'Gene-tree (ncRNA) by ID pruned to a taxon',
);

is_json_GET(
    '/genetree/id/RF01299?compara=homology;prune_species=mus_musculus;prune_species=rattus_norvegicus',
    $rodents_RF01299,
    'Gene-tree (ncRNA) by ID pruned to two species',
);


sub edit_leaf {
    my ($node, $new_value) = @_;
    if (exists $node->{children}) {
        map {edit_leaf($_, $new_value)} @{$node->{children}};
    } elsif (exists $new_value->{$node->{id}->{accession}}) {
        $node->{sequence}->{mol_seq} = $new_value->{$node->{id}->{accession}};
    } else {
        delete $node->{sequence}->{mol_seq};
    }
}

edit_leaf($restricted_RF01299->{tree}, {
        'ENSG00000176515' => {
            'cigar_line' => '6M2D9M2D19M2D3M2D3MDM2D7M11DM4D2M3D4MD8M26D6M',
            'seq' => 'AAGTGAAATGATGGCAATCATCTTTCGGGACTGACCTGAAATGAAGAGAATACTCATTGCTGATCACTT',
            'is_aligned' => 0
        },
        'ENSGGOG00000032407' => {
            'cigar_line' => '6M2D9M2D19M2D3M3D3MDM2D7M11DM4D2M3D4MD8M25D6M',
            'seq' => 'AAGTGAAATGATGGCAATCATCTTTCGGGACTGACCTGAAATGAAGAGAATACTCATTGCTGATCACTT',
            'is_aligned' => 0
        },
    });

is_json_GET(
    '/genetree/id/RF01299?compara=homology;subtree_node_id=100462673;cigar_line=1',
    $restricted_RF01299,
    'Gene-tree (ncRNA) by ID pruned to a subtree, with cigar_line',
);

edit_leaf($restricted_RF01299->{tree}, {
        'ENSG00000176515' => {
            'seq' => 'AAGTGAAATGATGGCAATCATCTTTCGGGACTGACCTGAA-A-TGAAGAG-A-AT-ACTC-ATTGCTGA-TCACTT',
            'is_aligned' => 1
        },
        'ENSGGOG00000032407' => {
            'seq' => 'AAGTGAAATGATGGCAATCATCTTTCGGGACTGACCT-GAA-A-TGAAGAG-A-AT-ACTC-ATTGCTGATCACTT',
            'is_aligned' => 1
        },
    });

is_json_GET(
    '/genetree/id/RF01299?compara=homology;subtree_node_id=100462673;aligned=1',
    $restricted_RF01299,
    'Gene-tree (ncRNA) by ID pruned to a subtree, with aligned sequences',
);


edit_leaf($restricted_RF01299->{tree}, {});
is_json_GET(
    '/genetree/id/RF01299?compara=homology;subtree_node_id=100462673;aligned=1;sequence=none',
    $restricted_RF01299,
    'Gene-tree (ncRNA) by ID pruned to a subtree, with no sequences',
);

$json = json_GET(
    '/genetree/id/RF01299?compara=homology',
    'Gene-tree (ncRNA) by ID',
);


# Going to count the number of sequences;
sub count_leaves {
    my $node = shift;
    if (exists $node->{children}) {
        return sum(map {count_leaves($_)} @{$node->{children}} );
    } else {
        return 1;
    }
}

is(count_leaves($json->{tree}), 69, 'Got all the leaves');

sub find_leaf {
    my ($node, $leaf_name) = @_;
    if (exists $node->{children}) {
        return map {find_leaf($_, $leaf_name)} @{$node->{children}};
    } elsif ($node->{id}->{accession} eq $leaf_name) {
        return ($node,);
    } else {
        return (),
    }
}

my $json3 = json_GET(
    '/genetree/member/id/homo_sapiens/ENSG00000176515?compara=homology&clusterset_id=default',
    'Gene-tree (ncRNA) by species and ID. Explicitly require the default clusterset_id',
);
is(count_leaves($json3->{tree}), 69, 'Got all the leaves (query by species and gene ID)');
my ($human_leaf) = find_leaf($json3->{'tree'}, 'ENSG00000176515');
is($human_leaf->{'branch_length'}, '0.1', 'Got the right branch-length (query by species and gene ID)');

my $json4 = json_GET(
    '/genetree/member/id/homo_sapiens/ENSG00000176515?compara=homology&clusterset_id=ss_it_s16',
    'Gene-tree (ncRNA) by species and ID. Alternative clusterset_id',
);
is(count_leaves($json4->{tree}), 69, 'Got all the leaves (query by species and gene ID)');
($human_leaf) = find_leaf($json4->{'tree'}, 'ENSG00000176515');
is($human_leaf->{'branch_length'}, '2.11826733883463e-06', 'Got the right branch-length (query by species and gene ID)');


my $restricted_ENSGT00390000003602 = {
    'tree' => {
        'branch_length' => '0.217419',
        'events' => {
            'type' => 'speciation'
        },
        'taxonomy' => {
            'scientific_name' => 'Tetraodontidae',
            'common_name' => 'Puffers',
            'id' => 31031,
            'timetree_mya' => '69.8'
        },
        'confidence' => {
            'bootstrap' => 100
        },
        'children' => [
            {
                'sequence' => {
                    'location' => 'scaffold_19:196046-199577',
                    'mol_seq' => {
                        'seq' => 'QLARDMQDMRIRKKKRQTIRPLPGSLFQKKSSGVARIPFKAAVNGKPPARYTAKPLCGLGVPLNVLEITSETAESFRFSLQHFVKLESLIDKGGIQLADGGWLIPTNDGTAGKEEFYRALCDTPGVDPKLMSEEWVYNHYRWIVWKQASMERSFPEEMGSLCLTPEQVLLQLKYRYDIEVDHSRRPALRKIMEKDDTAAKTLVLCVCGVVFRGSSPKNKSFGDISTPGADPKVENPCAVVWLTDGWYSIKAQLDGPLTSMLHRGRLPVGGKLIIHGAQLVGSENACSPLEAPVSLMLKICANSSRPARWDSKLGFHRDPRPFLLPVSSLYSSGGPVGCVDIIILRSYPILWMERKPEGGTVFRSGRAEEKEARRYNIHKEKAMEILFDKIKAEFEKEEKGNRKPQCRRTINGQNITSLQDGEELYEAVGDDPAFLEAHLTEKQVEVLQNYKRLVMEKQQAELQDRYRRAVESAEDGVGGCPKRDVAPVWRLCIADSMGHSGRVYQLSLWRPPSELQALLKEGCRYKVYNLTTLDSKKQGGNATVQLTATKKTQFEHLQGSEEWLSKHFQPRVATNFVRLQDPEFNPLCSEVDLTGYVITIIDGQGFSPAFYLADGKQNFVKVRCFSSFAQSGLEDVIKPRVLLALSNLQLRGQSTSPTPVVYAGDLTVFSTNPKEVHLQESFSQLKTLVQGQENFFVHAEEKLSQLMSDGLSAIASPAGQIQTPASTVKRRGDMTDVSSNIMVINKTSKVTCQQPGRSHRFSTPINRNSTAHSSAERNPSTIKKRKALDYLSHIPSPPPLSCLSTLSSPSVKKIFIPPRRTEIPGTLKTVKTPNQKPSNTPVDDQWVNDEELAMIDTQAL',
                        'is_aligned' => 0
                    },
                    'name' => 'brca2-201',
                    'id' => [
                        {
                            'source' => 'EnsEMBL',
                            'accession' => 'ENSTRUP00000015030'
                        }
                    ]
                },
                'branch_length' => '0.072273',
                'taxonomy' => {
                    'scientific_name' => 'Takifugu rubripes',
                    'common_name' => 'Fugu',
                    'id' => 31033
                },
                'confidence' => {},
                'id' => {
                    'source' => 'EnsEMBL',
                    'accession' => 'ENSTRUG00000006177'
                }
            },
            {
                'sequence' => {
                    'location' => '16:4700614-4705074',
                    'mol_seq' => {
                        'seq' => 'VSFSSDTPRKPKAGSLSSEFTDRFLAQEALDCTKALLEDERLVDDPHMTGECLHRCPQFSLLVNLFVKPHTAVLIPEQPPLKRRLLEEFDRTDGSSRGSALNPEKCSPNGIMGDRRVFKCSVSFQPNITTPHRICSQKAERPVSFLSRRSGTNYVETSLPNTTPTKVSALRDSNEARLQKSNFIPPFIKNVKLDTPNSKTASTFVPPFKKSRNSSKTEEEEPKHHFIPPFTNPCATSSTKKHTAGHLHNVELARDMQGMRIRKKKRQTILPLPGSLFLKKSSGVTRIPLKSAVNGKPPARYTPKQLYGLGVPLNVLEITSETAGSFRFSLQQFVKLESLTDKGGIQLADGGWLIPRNDGTAGKEEFYRALCDTTGVDPKLISEEWVYNHYRWIVWKQASMERSFPEQLGSLCLTPEQVLLQLKYRYDIEVDQSRRPALRKIMERDDTAAKTLILCVCGVVSRGSSPQKQGLGGVAAPSSDPQVENPFAVVWLTDGWYSIKAQLDGPLTSMLNRGRLPVGGKLIIHGAQLVGSQDACSPLEAPESIMLKIFANSSRRARWDAKLGFYRDPRPFLLPVSSLYNSGGPVGCVDIIILRSYPTLWMERKPEGGTVFRSGRAEEKEARRYNVHKEKAMEILFDKIQAEFEKEERDNRKPRSRRRTIGDQDIKSLQDGEELYEAVGDDPAYLEAHLTEQQAETLQNYKRLLIEKKQAELQDRYRRAVETAEDGTGSCPKRDVAPVWRLSIADFMEKPGSVYQLNIWRPPSELQSLLKEGCRYKVYNLTTTDSKKQGGNTTVQLSGTKKTQFEDLQASEELLSTYFQPRVSATFIDLQDPEFHSLCGEVDLTGYVISIIDGQGFSPAFYLTDGKQNFVKVRCFSSFAQSGLEDVIKPSVLLALSNLQLRGQATSPTPVLYAGDLTVFSTNPKEVHLQESFSQLKTLVQ',
                        'is_aligned' => 0
                    },
                    'name' => 'brca2-201',
                    'id' => [
                        {
                            'source' => 'EnsEMBL',
                            'accession' => 'ENSTNIP00000002435'
                        }
                    ]
                },
                'branch_length' => '0.113355',
                'taxonomy' => {
                    'scientific_name' => 'Tetraodon nigroviridis',
                    'common_name' => 'Tetraodon',
                    'id' => 99883
                },
                'confidence' => {},
                'id' => {
                    'source' => 'EnsEMBL',
                    'accession' => 'ENSTNIG00000016261'
                }
            }
        ]
    },
    'rooted' => 1,
    'type' => 'gene tree',
    'id' => 'ENSGT00390000003602'
};

is_json_GET(
    '/genetree/id/ENSGT00390000003602?compara=homology;subtree_node_id=14115075',
    $restricted_ENSGT00390000003602,
    'Gene-tree (protein-coding) by ID pruned to a subtree',
);

edit_leaf($restricted_ENSGT00390000003602->{tree}, {
        'ENSTRUG00000006177' => {
            'seq' => 'CAGCTGGCACGGGATATGCAGGATATGCGAATCAGAAAAAAGAAACGCCAGACCATTCGTCCATTACCGGGAAGTTTGTTTCAGAAGAAGTCCTCTGGAGTCGCCAGGATTCCATTTAAAGCTGCAGTAAACGGAAAGCCACCTGCACGCTACACTGCCAAACCGCTGTGTGGCCTCGGGGTTCCTCTGAATGTGTTGGAGATCACCAGTGAGACTGCAGAATCTTTTCGCTTCAGCTTGCAGCACTTTGTTAAGCTGGAGTCTCTCATAGATAAAGGTGGCATACAGCTCGCTGATGGAGGATGGCTGATTCCCACGAATGACGGGACAGCGGGAAAAGAAGAGTTTTATCGAGCATTGTGTGATACCCCGGGGGTTGATCCTAAACTAATGAGTGAGGAGTGGGTGTATAATCACTACCGATGGATTGTATGGAAACAAGCTTCCATGGAAAGGTCATTTCCAGAAGAGATGGGCAGCCTCTGTCTCACCCCAGAGCAGGTTCTCCTACAACTTAAGTACAGATATGACATAGAGGTTGACCACAGTCGCAGACCAGCTCTCAGAAAAATTATGGAAAAGGATGACACGGCAGCTAAAACCCTGGTCCTCTGTGTTTGTGGGGTTGTCTTCAGAGGCAGCTCCCCAAAAAACAAGAGTTTTGGGGACATCAGTACTCCAGGAGCTGACCCAAAGGTTGAAAACCCCTGTGCTGTCGTTTGGCTGACCGATGGATGGTATTCAATTAAAGCGCAACTGGATGGACCGTTGACCTCAATGCTTCACAGAGGTCGACTACCAGTCGGCGGGAAGCTGATTATCCATGGTGCTCAGCTAGTCGGATCAGAGAATGCTTGTTCCCCCCTGGAGGCCCCTGTGTCTTTAATGCTAAAGATTTGCGCCAACAGCAGCAGACCAGCTCGATGGGATTCTAAACTAGGATTTCACAGGGACCCGCGGCCATTCCTGCTTCCTGTCTCTTCTTTGTACAGCAGTGGAGGACCAGTAGGATGTGTGGATATTATTATACTGAGAAGCTATCCCATATTGTGGATGGAGAGGAAACCAGAAGGAGGCACTGTGTTCCGTTCAGGCAGAGCAGAAGAGAAGGAGGCGAGACGATACAACATTCACAAAGAAAAAGCTATGGAAATCCTGTTTGACAAGATTAAAGCAGAATTTGAAAAGGAAGAAAAAGGTAACAGGAAACCGCAGTGCAGAAGGACAATCAATGGTCAAAATATTACAAGTCTTCAAGATGGAGAGGAGCTGTACGAAGCAGTGGGCGATGACCCAGCTTTCCTTGAGGCGCATCTGACTGAGAAGCAGGTGGAGGTTCTTCAGAACTACAAACGTCTGGTGATGGAGAAGCAGCAGGCAGAGCTGCAGGATCGCTACCGGCGAGCTGTAGAAAGTGCAGAGGACGGCGTGGGGGGCTGCCCCAAGCGAGATGTCGCACCTGTGTGGAGACTGTGCATTGCTGACTCCATGGGCCATTCTGGCCGTGTTTACCAGCTGAGTCTTTGGCGGCCCCCCTCAGAGCTCCAGGCATTACTGAAGGAAGGCTGTCGTTATAAAGTGTATAATCTCACCACTTTAGATTCAAAGAAACAGGGTGGAAATGCAACGGTTCAGCTAACTGCAACAAAAAAAACACAGTTTGAGCACCTACAGGGATCTGAGGAGTGGTTATCAAAACATTTTCAGCCGAGGGTTGCAACCAATTTTGTGAGACTCCAAGATCCAGAATTCAACCCATTGTGTAGCGAGGTTGATCTCACAGGATATGTCATTACTATAATAGATGGGCAAGGTTTCTCTCCTGCATTTTACCTGGCTGATGGGAAACAGAATTTTGTAAAAGTTCGGTGTTTCAGCAGCTTCGCCCAATCTGGCTTGGAAGATGTAATAAAGCCACGTGTCCTTTTGGCCCTAAGCAACCTGCAGCTGAGGGGTCAGTCGACATCACCTACTCCAGTCGTGTATGCTGGAGATTTAACCGTCTTCTCCACAAACCCCAAAGAGGTTCATCTGCAGGAATCCTTCAGCCAGCTCAAAACTCTGGTTCAGGGCCAGGAGAACTTTTTTGTGCACGCTGAAGAGAAGCTTTCTCAGTTGATGTCTGATGGCCTGAGCGCTATCGCTTCTCCAGCTGGGCAAATACAAACCCCAGCTTCCACAGTAAAGAGAAGAGGAGACATGACGGATGTGAGCTCAAATATAATGGTTATTAACAAGACTTCTAAGGTCACATGTCAGCAGCCAGGCAGAAGCCACAGATTCTCAACGCCTATAAACAGGAACTCTACTGCTCACAGTTCAGCAGAGAGAAACCCAAGCACTATTAAGAAGAGGAAAGCTCTCGACTATCTGTCCCACATCCCGTCTCCACCGCCTCTGTCCTGTCTGAGTACACTATCTTCTCCCAGCGTAAAAAAGATATTTATTCCGCCTCGCCGAACTGAAATACCTGGTACTTTAAAAACTGTAAAGACTCCAAATCAAAAACCTTCCAATACACCTGTGGATGATCAGTGGGTGAATGATGAGGAACTGGCTATGATCGACACTCAGGCATTA',
            'is_aligned' => 0
        },
        'ENSTNIG00000016261' => {
            'seq' => 'GTGTCATTTTCATCTGACACCCCCAGGAAGCCAAAAGCTGGAAGTCTGAGTTCAGAGTTCACAGATAGGTTTCTTGCCCAAGAAGCTCTGGACTGCACAAAAGCTTTATTGGAGGATGAAAGGTTGGTGGATGACCCTCATATGACCGGTGAGTGTTTGCACAGATGCCCTCAGTTTTCTCTCTTAGTAAATTTATTTGTAAAACCTCACACTGCTGTTTTAATTCCAGAACAACCTCCTCTGAAAAGACGTTTGCTAGAAGAATTTGACAGAACAGATGGCAGTTCTAGAGGTTCAGCTCTCAATCCGGAAAAATGCAGTCCCAATGGCATAATGGGAGACAGGAGGGTTTTTAAGTGCAGTGTGTCTTTTCAGCCCAACATCACCACACCCCACAGAATATGTTCTCAGAAGGCTGAACGTCCTGTTTCTTTTTTATCACGTAGAAGTGGGACAAATTACGTGGAAACCAGCCTGCCGAATACTACACCAACAAAAGTGTCAGCTCTGAGAGACAGCAATGAGGCACGTCTGCAGAAATCAAACTTTATTCCACCATTTATAAAGAATGTAAAGTTGGACACTCCTAACAGCAAGACTGCATCTACATTTGTTCCCCCATTCAAAAAATCGAGAAATTCTTCCAAAACAGAGGAAGAGGAGCCTAAACATCACTTTATACCCCCTTTTACTAACCCCTGTGCTACGTCTTCTACCAAAAAACACACTGCCGGTCATCTTCACAACGTTGAGCTGGCTCGGGATATGCAGGGCATGCGAATCAGGAAAAAGAAACGCCAGACCATTCTTCCATTACCGGGAAGTTTGTTTCTGAAAAAATCCTCCGGAGTGACCAGGATTCCACTTAAGTCTGCAGTGAACGGAAAACCCCCTGCACGTTACACCCCCAAACAGCTGTATGGCCTCGGGGTTCCTCTGAATGTGTTGGAGATCACCAGTGAGACTGCAGGATCTTTTCGCTTCAGTTTACAGCAGTTTGTTAAACTGGAGTCTCTCACAGATAAAGGCGGCATACAGCTGGCGGATGGAGGATGGTTGATTCCCAGGAATGATGGGACAGCAGGAAAAGAAGAGTTTTATCGAGCATTATGTGATACCACGGGGGTTGATCCTAAACTAATAAGTGAGGAGTGGGTGTATAATCACTACCGATGGATTGTGTGGAAACAAGCTTCCATGGAGAGATCATTTCCAGAACAGCTGGGCAGCCTCTGTCTCACGCCTGAGCAGGTTCTCCTCCAACTTAAGTACAGATATGACATAGAGGTGGACCAGAGTCGCAGGCCAGCTCTCAGAAAAATAATGGAAAGGGATGACACAGCAGCTAAAACCCTGATCCTGTGTGTTTGTGGAGTTGTCTCAAGAGGCAGCTCCCCACAAAAACAGGGTCTGGGGGGCGTCGCTGCTCCAAGTTCTGACCCACAGGTGGAAAATCCCTTTGCGGTGGTTTGGCTGACTGATGGATGGTATTCCATTAAGGCGCAGCTGGATGGACCTTTGACCTCCATGCTTAACAGGGGTCGACTGCCAGTTGGCGGGAAGCTGATTATTCATGGTGCTCAGCTAGTCGGTTCACAGGATGCTTGTTCTCCTTTGGAGGCCCCTGAGTCTATCATGCTAAAGATTTTTGCCAACAGCAGCAGGCGAGCACGATGGGATGCTAAACTGGGATTTTATAGGGACCCACGGCCATTCCTGCTCCCTGTCTCTTCTTTGTACAACAGTGGGGGACCTGTAGGATGTGTGGATATTATTATATTAAGAAGCTATCCCACATTATGGATGGAGAGAAAACCAGAAGGAGGCACTGTGTTCCGGTCAGGCCGAGCAGAAGAAAAGGAGGCTAGACGGTACAACGTCCACAAGGAAAAAGCTATGGAGATTCTGTTTGACAAGATTCAAGCGGAATTTGAAAAGGAAGAGAGGGATAACAGGAAACCTCGGAGCAGAAGACGGACAATCGGTGATCAAGATATCAAAAGTCTTCAAGATGGAGAGGAGCTGTACGAAGCAGTGGGCGATGACCCAGCTTACCTTGAGGCACATTTGACTGAGCAGCAGGCAGAGACTCTACAGAACTACAAACGTCTGCTGATAGAAAAGAAGCAAGCAGAGCTGCAGGATCGCTACCGGCGAGCTGTAGAAACTGCAGAGGATGGCACAGGCAGCTGTCCCAAGCGAGATGTAGCACCTGTATGGAGACTCAGCATTGCTGACTTCATGGAAAAGCCAGGCAGTGTTTACCAGCTGAACATTTGGCGGCCTCCCTCAGAGCTCCAGTCTTTACTAAAAGAAGGCTGTCGATATAAGGTGTATAATCTCACCACAACAGATTCAAAGAAACAAGGTGGAAACACAACCGTTCAGCTAAGTGGAACAAAAAAAACACAATTTGAGGACCTTCAGGCATCCGAGGAATTGTTGTCAACATATTTTCAGCCAAGGGTCTCGGCCACATTCATCGATCTCCAAGATCCAGAATTCCATTCGTTGTGTGGTGAGGTTGATCTCACAGGATACGTCATCAGTATAATAGATGGACAAGGTTTCTCACCTGCTTTTTACCTAACTGATGGGAAACAAAATTTTGTAAAAGTGCGTTGTTTCAGCAGCTTCGCTCAGTCAGGCTTGGAAGATGTAATAAAGCCAAGTGTCCTTTTAGCTTTAAGCAACCTCCAACTGAGAGGTCAGGCAACATCACCCACTCCAGTCTTGTACGCTGGAGATCTAACCGTCTTCTCCACAAACCCCAAAGAAGTTCATCTGCAGGAATCCTTCAGCCAGCTCAAAACCCTGGTTCAG',
            'is_aligned' => 0
        },
});


is_json_GET(
    '/genetree/id/ENSGT00390000003602?compara=homology;subtree_node_id=14115075;sequence=cdna',
    $restricted_ENSGT00390000003602,
    'Gene-tree (protein-coding) by ID pruned to a subtree',
);

edit_leaf($restricted_ENSGT00390000003602->{tree}, {
        'ENSTRUG00000006177' => {
            'seq' => '----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------QLARDMQDMRIRKKKRQTIRPLPGSLFQKKSSGVARIPFKAAVNGKPPARYTAKPLCGLGVPLNVLEITSETAESFRFSLQHFVKLESLIDKGGIQLADGGWLIPTNDGTAGKEEFYRALCDTPGVDPKLMSEEWVYNHYRWIVWKQASMERSFPEEMGSLCLTPEQVLLQLKYRYDIEVDHSRRPALRKIMEKDDTAAKTLVLCVCGVVFRGSSPKNKSFGDISTPGADPKVENPCAVVWLTDGWYSIKAQLDGPLTSMLHRGRLPVGGKLIIHGAQLVGSENACSPLEAPVSLMLKICANSSRPARWDSKLGFHRDPRPFLLPVSSLYSSGGPVGCVDIIILRSYPILWMERKPEGGTVFRSGRAEEKEARRYNIHKEKAMEILFDKIKAEFEKE-EKGNRKPQCRRTINGQNITSLQDGEELYEAVGDDPAFLEAHLTEKQVEVLQNYKRLVMEKQQAELQDRYRRAVESAEDGVGGCPKRDVAPVWRLCIADSMGHSGRVYQLSLWRPPSELQALLKEGCRYKVYNLTTLDSKKQGGNATVQLTATKKTQFEHLQGSEEWLSKHFQPRVATNFVRLQDPEFNPLCSEVDLTGYVITIIDGQGFSPAFYLADGKQNFVKVRCFSSFAQSGLEDVIKPRVLLALSNLQLRGQSTSPTPVVYAGDLTVFSTNPKEVHLQESFSQLKTLVQGQENFFVHAEEKLSQLMSDGLSAIASPAGQIQTPASTVKRRGDMTDVSSNIMVINKTSKVTCQQPGRSHRFSTPINRNSTAHSSAERNPSTIKKRKALDYLSHIPSPPPLSCLSTLSSPSVKKIFIPPRRTEIPGTLKTVKTPNQKPSNTPVDDQWVNDEELAMIDTQAL',
            'is_aligned' => 1
        },
        'ENSTNIG00000016261' => {
            'seq' => 'VSFSSDTPRKPKAGSLSSEFTDRFLAQEALDCTKALLEDERLVDDPHMTGECLHRCPQFSLLVNLFVKPHTAVLIPEQPPLKRRLLEEFDRTDGSSRGSALNPEKCSPNGIMGDRRVFKCSVSFQPNITTPHRICSQKAERPVSFLSRRSGTNYVETSLPNTTPTKVSALRDSNEARLQKSNFIPPFIKNVKLDTPNSKTASTFVPPFKKSRNSSKTEEEEPKHHFIPPFTNPCATSSTKKHTAGHLHNVELARDMQGMRIRKKKRQTILPLPGSLFLKKSSGVTRIPLKSAVNGKPPARYTPKQLYGLGVPLNVLEITSETAGSFRFSLQQFVKLESLTDKGGIQLADGGWLIPRNDGTAGKEEFYRALCDTTGVDPKLISEEWVYNHYRWIVWKQASMERSFPEQLGSLCLTPEQVLLQLKYRYDIEVDQSRRPALRKIMERDDTAAKTLILCVCGVVSRGSSPQKQGLGGVAAPSSDPQVENPFAVVWLTDGWYSIKAQLDGPLTSMLNRGRLPVGGKLIIHGAQLVGSQDACSPLEAPESIMLKIFANSSRRARWDAKLGFYRDPRPFLLPVSSLYNSGGPVGCVDIIILRSYPTLWMERKPEGGTVFRSGRAEEKEARRYNVHKEKAMEILFDKIQAEFEKEERDNRKPRSRRRTIGDQDIKSLQDGEELYEAVGDDPAYLEAHLTEQQAETLQNYKRLLIEKKQAELQDRYRRAVETAEDGTGSCPKRDVAPVWRLSIADFMEKPGSVYQLNIWRPPSELQSLLKEGCRYKVYNLTTTDSKKQGGNTTVQLSGTKKTQFEDLQASEELLSTYFQPRVSATFIDLQDPEFHSLCGEVDLTGYVISIIDGQGFSPAFYLTDGKQNFVKVRCFSSFAQSGLEDVIKPSVLLALSNLQLRGQATSPTPVLYAGDLTVFSTNPKEVHLQESFSQLKTLVQ--------------------------------------------------------------------------------------------------------------------------------------------------------------------------',
            'is_aligned' => 1
        },
});

is_json_GET(
    '/genetree/id/ENSGT00390000003602?compara=homology;subtree_node_id=14115075;aligned=1',
    $restricted_ENSGT00390000003602,
    'Gene-tree (protein-coding) by ID pruned to a subtree',
);

$nh = nh_GET(
    '/genetree/id/RF01299?compara=homology;subtree_node_id=100462639',
    'Gene-tree (ncRNA) by ID',
);

my $restricted_RF01299_nh_simple = '(ENSORLT00000026615:0.0716974,ENSPFOT00000021580:0.0877229);';
is($nh, $restricted_RF01299_nh_simple, 'Got the correct newick');


$xml = orthoxml_GET(
    '/genetree/id/RF01299?compara=homology;subtree_node_id=100462639',
    'Gene-tree (ncRNA) by ID',
);

subtest 'OrthoXML file', sub {
    my $tx = Test::XPath->new(xml => $xml, xmlns => { x => "http://www.w3.org/2001/XMLSchema-instance", o => "http://orthoXML.org/2011/"});

    $tx->is('count(//o:species)', 2, "number of species");
    $tx->is('count(//o:database)', 2, "number of databases");
    $tx->is('count(//o:gene)', 2, "number of genes");
    $tx->is('count(//o:gene[@geneId="ENSPFOG00000021430"])', 1, "gene is found");
    $tx->ok('//o:gene[@geneId="ENSPFOG00000021430"]', sub {
            my $node = shift->node;
            is($node->getAttribute('transcriptId'), 'ENSPFOT00000021580', 'transcript is correct');
            is($node->getAttribute('id'), '100244304', 'dbID is correct');
        }, "gene entry is complete");
    $tx->is('count(//o:orthologGroup)', 1, "number of orthologies");
    my $expected_orthoxml_properties = {
        'taxon_name' => 'Clupeocephala',
        'taxon_id' => 186625,
        'common_name' => 'Teleost fishes',
        'timetree_mya' => '265.5',
    };
    $tx->ok('//o:orthologGroup', sub {
            $_->ok('./o:property', sub {
                    my $node = shift->node;
                    ok(exists $expected_orthoxml_properties->{$node->getAttribute('name')}, 'the property '.$node->getAttribute('name').' is expected');
                    is($expected_orthoxml_properties->{$node->getAttribute('name')}, $node->getAttribute('value'), 'the property '.$node->getAttribute('name').' has the correct value');
                }, 'orthologGroup properties');
            $_->is('count(./o:geneRef)', 2, "number of genes in the orthology");
            $_->is('count(./o:geneRef[@id="100244304"])', 1, "ENSPFOG00000021430 is found");
        }, "orthologGroup entry is complete");
};

$xml = orthoxml_GET(
    '/genetree/id/RF01299?compara=homology',
    'orthoxml with the whole tree',
);
subtest 'OrthoXML file', sub {
    my $tx = Test::XPath->new(xml => $xml, xmlns => { x => "http://www.w3.org/2001/XMLSchema-instance", o => "http://orthoXML.org/2011/"});
    $tx->is('count(//o:orthologGroup)', 57, 'Got all the homologies');
    $tx->is('count(//o:species)', 38, 'Some species have paralogs, so there are fewer species than orthologies');
    $tx->is('count(//o:gene)', 69, 'Got all the genes');
};


$xml = phyloxml_GET(
    '/genetree/id/RF01299?compara=homology;subtree_node_id=100462639',
    'Gene-tree (ncRNA) by ID',
);

subtest 'PhyloXML file', sub {
    my $tx = Test::XPath->new(xml => $xml, xmlns => { x => "http://www.w3.org/2001/XMLSchema-instance", p => "http://www.phyloxml.org"});

    $tx->is('count(//p:phylogeny)', 1, "root phylogeny");
    $tx->is('count(//p:clade)', 3, "3 nodes = 2 leaves + 1 internal node");
    $tx->ok('/p:phyloxml/p:phylogeny/p:clade/p:taxonomy', sub {
            $_->is('./p:scientific_name', 'Clupeocephala', 'scientific_name');
            $_->is('./p:id', 186625, 'id');
            $_->is('./p:common_name', 'Teleost fishes', 'common_name');
        }, "taxonomy entry is complete");
    $tx->ok('/p:phyloxml/p:phylogeny/p:clade/p:clade[@branch_length="0.0716974"]', sub {
            $_->is('./p:name', 'ENSORLG00000021634', 'found 1 gene');
            $_->is('./p:property[@ref="Compara:genome_db_name"]', 'oryzias_latipes', 'of the right species');
            $_->ok('./p:taxonomy', sub {
                    $_->is('./p:scientific_name', 'Oryzias latipes', 'scientific_name');
                    $_->is('./p:id', 8090, 'id');
                    $_->is('./p:common_name', 'Medaka', 'common_name');
                }, "taxonomy entry is complete");
            $_->ok('./p:sequence', sub {
                    $_->is('./p:accession[@source="Ensembl"]', 'ENSORLT00000026615', 'Transcript ID');
                    $_->is('./p:name', 'SNORD2-201', 'Display name');
                    $_->is('./p:location', '17:14654245-14654320', 'Location');
                    $_->is('./p:mol_seq[@is_aligned="0"]', 'GAGTGATATGATGGCATACCATCTTTCGGGACTGACTGAAACATGGAGAGTCCTTTTATTGTTGTACTGATCACTC', 'Unaligned sequence');
                }, "sequence entry is complete");
        }, 'first gene is complete');
    $tx->ok('/p:phyloxml/p:phylogeny/p:clade/p:clade[@branch_length="0.0877229"]', sub {
            $_->is('./p:name', 'ENSPFOG00000021430', 'found 1 gene');
            $_->is('./p:property[@ref="Compara:genome_db_name"]', 'poecilia_formosa', 'of the right species');
            $_->ok('./p:taxonomy', sub {
                    $_->is('./p:scientific_name', 'Poecilia formosa', 'scientific_name');
                    $_->is('./p:id', 48698, 'id');
                    $_->is('./p:common_name', 'Amazon molly', 'common_name');
                }, "taxonomy entry is complete");
            $_->ok('./p:sequence', sub {
                    $_->is('./p:accession[@source="Ensembl"]', 'ENSPFOT00000021580', 'Transcript ID');
                    $_->is('./p:name', 'SNORD2-201', 'Display name');
                    $_->is('./p:location', 'KI519677.1:381062-381137', 'Location');
                    $_->is('./p:mol_seq[@is_aligned="0"]', 'GAGTGATGTGATGGTATACCATCTTTCGGGACTGACTCTTGAGATGGAGAGTTCCTTTCTGACTTACTGATCACTG', 'Unaligned sequence');
                }, "sequence entry is complete");
        }, 'second gene is complete');
};

$xml = phyloxml_GET(
    '/genetree/id/RF01299?compara=homology;subtree_node_id=100462639;aligned=1',
    'Gene-tree (ncRNA) by ID',
);

# Here we only check that we get the aligned sequence
subtest 'PhyloXML file', sub {
    my $tx = Test::XPath->new(xml => $xml, xmlns => { x => "http://www.w3.org/2001/XMLSchema-instance", p => "http://www.phyloxml.org"});

    $tx->ok('/p:phyloxml/p:phylogeny/p:clade/p:clade[@branch_length="0.0716974"]', sub {
            $_->ok('./p:sequence', sub {
                    $_->is('./p:accession[@source="Ensembl"]', 'ENSORLT00000026615', 'Transcript ID');
                    $_->is('./p:mol_seq[@is_aligned="1"]', 'GAGTGATATGATGGCATACCATCTTTCGGGACTGA--CTGAAACATGGAGAGTCCTTTTATTGTTGTACTGATCACTC', 'Aligned sequence');
                }, "sequence entry is complete");
        }, 'first gene is complete');
    $tx->ok('/p:phyloxml/p:phylogeny/p:clade/p:clade[@branch_length="0.0877229"]', sub {
            $_->ok('./p:sequence', sub {
                    $_->is('./p:accession[@source="Ensembl"]', 'ENSPFOT00000021580', 'Transcript ID');
                    $_->is('./p:mol_seq[@is_aligned="1"]', 'GAGTGATGTGATGGTATACCATCTTTCGGGACTGACTCTTGAG-ATGGAGAGTTCCTTTCTGA-CTTACTGATCACTG', 'Aligned sequence');
                }, "sequence entry is complete");
        }, 'second gene is complete');
};

## queries with a clashing gene / transcript / translation stable ID

my $bird_subtree = {
  'id' => 'aves_PTHR08128',
  'type' => 'gene tree',
  'rooted' => 1,
  'tree' => {
    'taxonomy' => {
      'id' => 59894,
      'scientific_name' => 'Ficedula albicollis',
      'common_name' => 'Flycatcher',
    },
    'branch_length' => 0,
    'confidence' => {},
    'id' => {
      'accession' => 'ENSFALG00000116138',
      'source' => 'EnsEMBL',
    },
    'sequence' => {
      'id' => [
        {
          'accession' => 'ENSFALP00000039910',
          'source' => 'EnsEMBL',
        }
      ],
      'location' => 'JH603207.1:6605665-6608045',
      'mol_seq' => {
        'seq' => 'MWPPSGAVRNLALVLARSQRARTCSGVERVSYTQGQSPEPRTREYFYYVDHQGQLFLDDSKMKNFITCFKDLQFLVTFFSRLRPNHSGRYEASFPFLSLCGRERNFLRCEDRPVVFTHLLASDSESPRLSYCGGGEALAIPFEPARLLPLAANGRLYHPAPERAGGVGLVRSALAFELSACFEYGPSSPTVPSHVHWQGRRIALTMDLAPLLPAAPPP',
        'is_aligned' => 0,
      }
    }
  },
};

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
        "/genetree/member/id/meleagris_gallopavo/${stable_id}?compara=homology;subtree_node_id=1800121321",
        "gene tree using species name and $object_type stable ID",
    );
    eq_or_diff(
      $json,
      $bird_subtree,
      "Got the correct gene tree by species name and $object_type stable ID",
    );
}

done_testing();

