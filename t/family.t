# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# Copyright [2016-2018] EMBL-European Bioinformatics Institute
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

my ($json);

#the normal returned hash with the alignment would have been too big
my $stripped_family_hash= {
  'members' => [
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSTNIP00000002435',
      'gene_stable_id' => 'ENSTNIG00000016261',
      'genome' => 'tetraodon_nigroviridis',
      'description' => 'breast cancer 2, early onset [Source:ZFIN;Acc:ZDB-GENE-060510-3]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSTRUP00000015030',
      'gene_stable_id' => 'ENSTRUG00000006177',
      'genome' => 'takifugu_rubripes',
      'description' => 'breast cancer 2, early onset [Source:ZFIN;Acc:ZDB-GENE-060510-3]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSXMAP00000006983',
      'gene_stable_id' => 'ENSXMAG00000006974',
      'genome' => 'xiphophorus_maculatus',
      'description' => 'breast cancer 2, early onset [Source:ZFIN;Acc:ZDB-GENE-060510-3]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSTGUP00000012130',
      'gene_stable_id' => 'ENSTGUG00000011763',
      'genome' => 'taeniopygia_guttata',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSXETP00000060681',
      'gene_stable_id' => 'ENSXETG00000017011',
      'genome' => 'xenopus_tropicalis',
      'description' => 'breast cancer 2, early onset [Source:Xenbase;Acc:XB-GENE-6453899]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSLAFP00000002234',
      'gene_stable_id' => 'ENSLAFG00000002670',
      'genome' => 'loxodonta_africana',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSAMEP00000009909',
      'gene_stable_id' => 'ENSAMEG00000009390',
      'genome' => 'ailuropoda_melanoleuca',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSOCUP00000014514',
      'gene_stable_id' => 'ENSOCUG00000016878',
      'genome' => 'oryctolagus_cuniculus',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSMGAP00000015990',
      'gene_stable_id' => 'ENSMGAG00000015077',
      'genome' => 'meleagris_gallopavo',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSLOCP00000009962',
      'gene_stable_id' => 'ENSLOCG00000008205',
      'genome' => 'lepisosteus_oculatus',
      'description' => 'breast cancer 2, early onset [Source:ZFIN;Acc:ZDB-GENE-060510-3]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSSTOP00000004979',
      'gene_stable_id' => 'ENSSTOG00000005517',
      'genome' => 'ictidomys_tridecemlineatus',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSBTAP00000001311',
      'gene_stable_id' => 'ENSBTAG00000000988',
      'genome' => 'bos_taurus',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSMODP00000033276',
      'gene_stable_id' => 'ENSMODG00000009516',
      'genome' => 'monodelphis_domestica',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSFCAP00000019777',
      'gene_stable_id' => 'ENSFCAG00000025587',
      'genome' => 'felis_catus',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSGGOP00000015446',
      'gene_stable_id' => 'ENSGGOG00000015808',
      'genome' => 'gorilla_gorilla',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSCAFP00000009557',
      'gene_stable_id' => 'ENSCAFG00000006383',
      'genome' => 'canis_familiaris',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSCJAP00000034250',
      'gene_stable_id' => 'ENSCJAG00000018462',
      'genome' => 'callithrix_jacchus',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSFALP00000008821',
      'gene_stable_id' => 'ENSFALG00000008451',
      'genome' => 'ficedula_albicollis',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSAPLP00000007411',
      'gene_stable_id' => 'ENSAPLG00000007774',
      'genome' => 'anas_platyrhynchos',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSPFOP00000001575',
      'gene_stable_id' => 'ENSPFOG00000001640',
      'genome' => 'poecilia_formosa',
      'description' => 'breast cancer 2, early onset [Source:ZFIN;Acc:ZDB-GENE-060510-3]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSP00000369497',
      'gene_stable_id' => 'ENSG00000139618',
      'genome' => 'homo_sapiens',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSLACP00000008815',
      'gene_stable_id' => 'ENSLACG00000007788',
      'genome' => 'latimeria_chalumnae',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSECAP00000013146',
      'gene_stable_id' => 'ENSECAG00000014890',
      'genome' => 'equus_caballus',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSOANP00000032170',
      'gene_stable_id' => 'ENSOANG00000030391',
      'genome' => 'ornithorhynchus_anatinus',
      'description' => 'Uncharacterized protein  [Source:UniProtKB/TrEMBL;Acc:K7EF63]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSPTRP00000009812',
      'gene_stable_id' => 'ENSPTRG00000005766',
      'genome' => 'pan_troglodytes',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSTBEP00000013856',
      'gene_stable_id' => 'ENSTBEG00000015907',
      'genome' => 'tupaia_belangeri',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSGACP00000015199',
      'gene_stable_id' => 'ENSGACG00000011490',
      'genome' => 'gasterosteus_aculeatus',
      'description' => 'breast cancer 2, early onset [Source:ZFIN;Acc:ZDB-GENE-060510-3]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSPANP00000002726',
      'gene_stable_id' => 'ENSPANG00000013323',
      'genome' => 'papio_anubis',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSNLEP00000001277',
      'gene_stable_id' => 'ENSNLEG00000001048',
      'genome' => 'nomascus_leucogenys',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSMLUP00000012516',
      'gene_stable_id' => 'ENSMLUG00000013741',
      'genome' => 'myotis_lucifugus',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSONIP00000006940',
      'gene_stable_id' => 'ENSONIG00000005522',
      'genome' => 'oreochromis_niloticus',
      'description' => 'breast cancer 2, early onset [Source:ZFIN;Acc:ZDB-GENE-060510-3]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSCPOP00000004635',
      'gene_stable_id' => 'ENSCPOG00000005153',
      'genome' => 'cavia_porcellus',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSPPYP00000005997',
      'gene_stable_id' => 'ENSPPYG00000005264',
      'genome' => 'pongo_abelii',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSPSIP00000012858',
      'gene_stable_id' => 'ENSPSIG00000011574',
      'genome' => 'pelodiscus_sinensis',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSOARP00000011988',
      'gene_stable_id' => 'ENSOARG00000011179',
      'genome' => 'ovis_aries',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSOPRP00000014082',
      'gene_stable_id' => 'ENSOPRG00000015365',
      'genome' => 'ochotona_princeps',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSSHAP00000012162',
      'gene_stable_id' => 'ENSSHAG00000010421',
      'genome' => 'sarcophilus_harrisii',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSOGAP00000009477',
      'gene_stable_id' => 'ENSOGAG00000010588',
      'genome' => 'otolemur_garnettii',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSCSAP00000013938',
      'gene_stable_id' => 'ENSCSAG00000017920',
      'genome' => 'chlorocebus_sabaeus',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSMPUP00000001928',
      'gene_stable_id' => 'ENSMPUG00000001945',
      'genome' => 'mustela_putorius_furo',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSSARP00000002541',
      'gene_stable_id' => 'ENSSARG00000002755',
      'genome' => 'sorex_araneus',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSPVAP00000000225',
      'gene_stable_id' => 'ENSPVAG00000000246',
      'genome' => 'pteropus_vampyrus',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSTTRP00000010004',
      'gene_stable_id' => 'ENSTTRG00000010541',
      'genome' => 'tursiops_truncatus',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSSSCP00000022872',
      'gene_stable_id' => 'ENSSSCG00000020961',
      'genome' => 'sus_scrofa',
      'description' => undef
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSSSCP00000028073',
      'gene_stable_id' => 'ENSSSCG00000029039',
      'genome' => 'sus_scrofa',
      'description' => undef
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSDNOP00000034947',
      'gene_stable_id' => 'ENSDNOG00000038771',
      'genome' => 'dasypus_novemcinctus',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSAMXP00000013440',
      'gene_stable_id' => 'ENSAMXG00000013027',
      'genome' => 'astyanax_mexicanus',
      'description' => 'breast cancer 2, early onset [Source:ZFIN;Acc:ZDB-GENE-060510-3]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSEEUP00000008968',
      'gene_stable_id' => 'ENSEEUG00000009739',
      'genome' => 'erinaceus_europaeus',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSETEP00000003277',
      'gene_stable_id' => 'ENSETEG00000003989',
      'genome' => 'echinops_telfairi',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSPCAP00000000440',
      'gene_stable_id' => 'ENSPCAG00000000379',
      'genome' => 'procavia_capensis',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSOANP00000024376',
      'gene_stable_id' => 'ENSOANG00000015481',
      'genome' => 'ornithorhynchus_anatinus',
      'description' => 'Uncharacterized protein  [Source:UniProtKB/TrEMBL;Acc:F7B8W7]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSDORP00000006609',
      'gene_stable_id' => 'ENSDORG00000007049',
      'genome' => 'dipodomys_ordii',
      'description' => 'breast cancer 2, early onset [Source:MGI Symbol;Acc:MGI:109337]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSVPAP00000000821',
      'gene_stable_id' => 'ENSVPAG00000000886',
      'genome' => 'vicugna_pacos',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSTSYP00000000441',
      'gene_stable_id' => 'ENSTSYG00000000478',
      'genome' => 'tarsius_syrichta',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSCHOP00000007822',
      'gene_stable_id' => 'ENSCHOG00000008817',
      'genome' => 'choloepus_hoffmanni',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSGMOP00000010385',
      'gene_stable_id' => 'ENSGMOG00000009699',
      'genome' => 'gadus_morhua',
      'description' => 'breast cancer 2, early onset [Source:ZFIN;Acc:ZDB-GENE-060510-3]'
    },
    {
      'source_name' => 'ENSEMBLPEP',
      'protein_stable_id' => 'ENSMEUP00000009812',
      'gene_stable_id' => 'ENSMEUG00000010691',
      'genome' => 'macropus_eugenii',
      'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
    }
  ],
  'description' => 'BREAST CANCER TYPE 2 SUSCEPTIBILITY HOMOLOG FANCONI ANEMIA GROUP D1 HOMOLOG',
  'family_stable_id' => 'PTHR11289_SF0'
};


my $stripped_family_by_gene_member ={
  '1' => {
    'members' => [
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSTNIP00000002435',
        'gene_stable_id' => 'ENSTNIG00000016261',
        'genome' => 'tetraodon_nigroviridis',
        'description' => 'breast cancer 2, early onset [Source:ZFIN;Acc:ZDB-GENE-060510-3]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSTRUP00000015030',
        'gene_stable_id' => 'ENSTRUG00000006177',
        'genome' => 'takifugu_rubripes',
        'description' => 'breast cancer 2, early onset [Source:ZFIN;Acc:ZDB-GENE-060510-3]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSXMAP00000006983',
        'gene_stable_id' => 'ENSXMAG00000006974',
        'genome' => 'xiphophorus_maculatus',
        'description' => 'breast cancer 2, early onset [Source:ZFIN;Acc:ZDB-GENE-060510-3]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSTGUP00000012130',
        'gene_stable_id' => 'ENSTGUG00000011763',
        'genome' => 'taeniopygia_guttata',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSXETP00000060681',
        'gene_stable_id' => 'ENSXETG00000017011',
        'genome' => 'xenopus_tropicalis',
        'description' => 'breast cancer 2, early onset [Source:Xenbase;Acc:XB-GENE-6453899]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSLAFP00000002234',
        'gene_stable_id' => 'ENSLAFG00000002670',
        'genome' => 'loxodonta_africana',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSAMEP00000009909',
        'gene_stable_id' => 'ENSAMEG00000009390',
        'genome' => 'ailuropoda_melanoleuca',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSOCUP00000014514',
        'gene_stable_id' => 'ENSOCUG00000016878',
        'genome' => 'oryctolagus_cuniculus',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSMGAP00000015990',
        'gene_stable_id' => 'ENSMGAG00000015077',
        'genome' => 'meleagris_gallopavo',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSLOCP00000009962',
        'gene_stable_id' => 'ENSLOCG00000008205',
        'genome' => 'lepisosteus_oculatus',
        'description' => 'breast cancer 2, early onset [Source:ZFIN;Acc:ZDB-GENE-060510-3]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSSTOP00000004979',
        'gene_stable_id' => 'ENSSTOG00000005517',
        'genome' => 'ictidomys_tridecemlineatus',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSBTAP00000001311',
        'gene_stable_id' => 'ENSBTAG00000000988',
        'genome' => 'bos_taurus',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSMODP00000033276',
        'gene_stable_id' => 'ENSMODG00000009516',
        'genome' => 'monodelphis_domestica',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSFCAP00000019777',
        'gene_stable_id' => 'ENSFCAG00000025587',
        'genome' => 'felis_catus',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSGGOP00000015446',
        'gene_stable_id' => 'ENSGGOG00000015808',
        'genome' => 'gorilla_gorilla',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSCAFP00000009557',
        'gene_stable_id' => 'ENSCAFG00000006383',
        'genome' => 'canis_familiaris',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSCJAP00000034250',
        'gene_stable_id' => 'ENSCJAG00000018462',
        'genome' => 'callithrix_jacchus',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSFALP00000008821',
        'gene_stable_id' => 'ENSFALG00000008451',
        'genome' => 'ficedula_albicollis',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSAPLP00000007411',
        'gene_stable_id' => 'ENSAPLG00000007774',
        'genome' => 'anas_platyrhynchos',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSPFOP00000001575',
        'gene_stable_id' => 'ENSPFOG00000001640',
        'genome' => 'poecilia_formosa',
        'description' => 'breast cancer 2, early onset [Source:ZFIN;Acc:ZDB-GENE-060510-3]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSP00000369497',
        'gene_stable_id' => 'ENSG00000139618',
        'genome' => 'homo_sapiens',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSLACP00000008815',
        'gene_stable_id' => 'ENSLACG00000007788',
        'genome' => 'latimeria_chalumnae',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSECAP00000013146',
        'gene_stable_id' => 'ENSECAG00000014890',
        'genome' => 'equus_caballus',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSOANP00000032170',
        'gene_stable_id' => 'ENSOANG00000030391',
        'genome' => 'ornithorhynchus_anatinus',
        'description' => 'Uncharacterized protein  [Source:UniProtKB/TrEMBL;Acc:K7EF63]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSPTRP00000009812',
        'gene_stable_id' => 'ENSPTRG00000005766',
        'genome' => 'pan_troglodytes',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSTBEP00000013856',
        'gene_stable_id' => 'ENSTBEG00000015907',
        'genome' => 'tupaia_belangeri',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSGACP00000015199',
        'gene_stable_id' => 'ENSGACG00000011490',
        'genome' => 'gasterosteus_aculeatus',
        'description' => 'breast cancer 2, early onset [Source:ZFIN;Acc:ZDB-GENE-060510-3]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSPANP00000002726',
        'gene_stable_id' => 'ENSPANG00000013323',
        'genome' => 'papio_anubis',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSNLEP00000001277',
        'gene_stable_id' => 'ENSNLEG00000001048',
        'genome' => 'nomascus_leucogenys',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSMLUP00000012516',
        'gene_stable_id' => 'ENSMLUG00000013741',
        'genome' => 'myotis_lucifugus',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSONIP00000006940',
        'gene_stable_id' => 'ENSONIG00000005522',
        'genome' => 'oreochromis_niloticus',
        'description' => 'breast cancer 2, early onset [Source:ZFIN;Acc:ZDB-GENE-060510-3]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSCPOP00000004635',
        'gene_stable_id' => 'ENSCPOG00000005153',
        'genome' => 'cavia_porcellus',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSPPYP00000005997',
        'gene_stable_id' => 'ENSPPYG00000005264',
        'genome' => 'pongo_abelii',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSPSIP00000012858',
        'gene_stable_id' => 'ENSPSIG00000011574',
        'genome' => 'pelodiscus_sinensis',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSOARP00000011988',
        'gene_stable_id' => 'ENSOARG00000011179',
        'genome' => 'ovis_aries',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSOPRP00000014082',
        'gene_stable_id' => 'ENSOPRG00000015365',
        'genome' => 'ochotona_princeps',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSSHAP00000012162',
        'gene_stable_id' => 'ENSSHAG00000010421',
        'genome' => 'sarcophilus_harrisii',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSOGAP00000009477',
        'gene_stable_id' => 'ENSOGAG00000010588',
        'genome' => 'otolemur_garnettii',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSCSAP00000013938',
        'gene_stable_id' => 'ENSCSAG00000017920',
        'genome' => 'chlorocebus_sabaeus',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSMPUP00000001928',
        'gene_stable_id' => 'ENSMPUG00000001945',
        'genome' => 'mustela_putorius_furo',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSSARP00000002541',
        'gene_stable_id' => 'ENSSARG00000002755',
        'genome' => 'sorex_araneus',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSPVAP00000000225',
        'gene_stable_id' => 'ENSPVAG00000000246',
        'genome' => 'pteropus_vampyrus',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSTTRP00000010004',
        'gene_stable_id' => 'ENSTTRG00000010541',
        'genome' => 'tursiops_truncatus',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSSSCP00000022872',
        'gene_stable_id' => 'ENSSSCG00000020961',
        'genome' => 'sus_scrofa',
        'description' => undef
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSSSCP00000028073',
        'gene_stable_id' => 'ENSSSCG00000029039',
        'genome' => 'sus_scrofa',
        'description' => undef
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSDNOP00000034947',
        'gene_stable_id' => 'ENSDNOG00000038771',
        'genome' => 'dasypus_novemcinctus',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSAMXP00000013440',
        'gene_stable_id' => 'ENSAMXG00000013027',
        'genome' => 'astyanax_mexicanus',
        'description' => 'breast cancer 2, early onset [Source:ZFIN;Acc:ZDB-GENE-060510-3]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSEEUP00000008968',
        'gene_stable_id' => 'ENSEEUG00000009739',
        'genome' => 'erinaceus_europaeus',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSETEP00000003277',
        'gene_stable_id' => 'ENSETEG00000003989',
        'genome' => 'echinops_telfairi',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSPCAP00000000440',
        'gene_stable_id' => 'ENSPCAG00000000379',
        'genome' => 'procavia_capensis',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSOANP00000024376',
        'gene_stable_id' => 'ENSOANG00000015481',
        'genome' => 'ornithorhynchus_anatinus',
        'description' => 'Uncharacterized protein  [Source:UniProtKB/TrEMBL;Acc:F7B8W7]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSDORP00000006609',
        'gene_stable_id' => 'ENSDORG00000007049',
        'genome' => 'dipodomys_ordii',
        'description' => 'breast cancer 2, early onset [Source:MGI Symbol;Acc:MGI:109337]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSVPAP00000000821',
        'gene_stable_id' => 'ENSVPAG00000000886',
        'genome' => 'vicugna_pacos',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSTSYP00000000441',
        'gene_stable_id' => 'ENSTSYG00000000478',
        'genome' => 'tarsius_syrichta',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSCHOP00000007822',
        'gene_stable_id' => 'ENSCHOG00000008817',
        'genome' => 'choloepus_hoffmanni',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSGMOP00000010385',
        'gene_stable_id' => 'ENSGMOG00000009699',
        'genome' => 'gadus_morhua',
        'description' => 'breast cancer 2, early onset [Source:ZFIN;Acc:ZDB-GENE-060510-3]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSMEUP00000009812',
        'gene_stable_id' => 'ENSMEUG00000010691',
        'genome' => 'macropus_eugenii',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      }
    ],
    'description' => 'BREAST CANCER TYPE 2 SUSCEPTIBILITY HOMOLOG FANCONI ANEMIA GROUP D1 HOMOLOG',
    'family_stable_id' => 'PTHR11289_SF0'
  }
};


my $fake_family =  {
  '1' => {
    'members' => [
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSTNIP00000002435',
        'gene_stable_id' => 'ENSTNIG00000016261',
        'genome' => 'tetraodon_nigroviridis',
        'description' => 'breast cancer 2, early onset [Source:ZFIN;Acc:ZDB-GENE-060510-3]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSTRUP00000015030',
        'gene_stable_id' => 'ENSTRUG00000006177',
        'genome' => 'takifugu_rubripes',
        'description' => 'breast cancer 2, early onset [Source:ZFIN;Acc:ZDB-GENE-060510-3]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSXMAP00000006983',
        'gene_stable_id' => 'ENSXMAG00000006974',
        'genome' => 'xiphophorus_maculatus',
        'description' => 'breast cancer 2, early onset [Source:ZFIN;Acc:ZDB-GENE-060510-3]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSTGUP00000012130',
        'gene_stable_id' => 'ENSTGUG00000011763',
        'genome' => 'taeniopygia_guttata',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSXETP00000060681',
        'gene_stable_id' => 'ENSXETG00000017011',
        'genome' => 'xenopus_tropicalis',
        'description' => 'breast cancer 2, early onset [Source:Xenbase;Acc:XB-GENE-6453899]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSLAFP00000002234',
        'gene_stable_id' => 'ENSLAFG00000002670',
        'genome' => 'loxodonta_africana',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSAMEP00000009909',
        'gene_stable_id' => 'ENSAMEG00000009390',
        'genome' => 'ailuropoda_melanoleuca',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSOCUP00000014514',
        'gene_stable_id' => 'ENSOCUG00000016878',
        'genome' => 'oryctolagus_cuniculus',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSMGAP00000015990',
        'gene_stable_id' => 'ENSMGAG00000015077',
        'genome' => 'meleagris_gallopavo',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSLOCP00000009962',
        'gene_stable_id' => 'ENSLOCG00000008205',
        'genome' => 'lepisosteus_oculatus',
        'description' => 'breast cancer 2, early onset [Source:ZFIN;Acc:ZDB-GENE-060510-3]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSSTOP00000004979',
        'gene_stable_id' => 'ENSSTOG00000005517',
        'genome' => 'ictidomys_tridecemlineatus',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSBTAP00000001311',
        'gene_stable_id' => 'ENSBTAG00000000988',
        'genome' => 'bos_taurus',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSMODP00000033276',
        'gene_stable_id' => 'ENSMODG00000009516',
        'genome' => 'monodelphis_domestica',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSFCAP00000019777',
        'gene_stable_id' => 'ENSFCAG00000025587',
        'genome' => 'felis_catus',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSGGOP00000015446',
        'gene_stable_id' => 'ENSGGOG00000015808',
        'genome' => 'gorilla_gorilla',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSCAFP00000009557',
        'gene_stable_id' => 'ENSCAFG00000006383',
        'genome' => 'canis_familiaris',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSCJAP00000034250',
        'gene_stable_id' => 'ENSCJAG00000018462',
        'genome' => 'callithrix_jacchus',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSFALP00000008821',
        'gene_stable_id' => 'ENSFALG00000008451',
        'genome' => 'ficedula_albicollis',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSAPLP00000007411',
        'gene_stable_id' => 'ENSAPLG00000007774',
        'genome' => 'anas_platyrhynchos',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSPFOP00000001575',
        'gene_stable_id' => 'ENSPFOG00000001640',
        'genome' => 'poecilia_formosa',
        'description' => 'breast cancer 2, early onset [Source:ZFIN;Acc:ZDB-GENE-060510-3]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSP00000369497',
        'gene_stable_id' => 'ENSG00000139618',
        'genome' => 'homo_sapiens',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSLACP00000008815',
        'gene_stable_id' => 'ENSLACG00000007788',
        'genome' => 'latimeria_chalumnae',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSECAP00000013146',
        'gene_stable_id' => 'ENSECAG00000014890',
        'genome' => 'equus_caballus',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSOANP00000032170',
        'gene_stable_id' => 'ENSOANG00000030391',
        'genome' => 'ornithorhynchus_anatinus',
        'description' => 'Uncharacterized protein  [Source:UniProtKB/TrEMBL;Acc:K7EF63]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSPTRP00000009812',
        'gene_stable_id' => 'ENSPTRG00000005766',
        'genome' => 'pan_troglodytes',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSTBEP00000013856',
        'gene_stable_id' => 'ENSTBEG00000015907',
        'genome' => 'tupaia_belangeri',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSGACP00000015199',
        'gene_stable_id' => 'ENSGACG00000011490',
        'genome' => 'gasterosteus_aculeatus',
        'description' => 'breast cancer 2, early onset [Source:ZFIN;Acc:ZDB-GENE-060510-3]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSPANP00000002726',
        'gene_stable_id' => 'ENSPANG00000013323',
        'genome' => 'papio_anubis',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSNLEP00000001277',
        'gene_stable_id' => 'ENSNLEG00000001048',
        'genome' => 'nomascus_leucogenys',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSMLUP00000012516',
        'gene_stable_id' => 'ENSMLUG00000013741',
        'genome' => 'myotis_lucifugus',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSONIP00000006940',
        'gene_stable_id' => 'ENSONIG00000005522',
        'genome' => 'oreochromis_niloticus',
        'description' => 'breast cancer 2, early onset [Source:ZFIN;Acc:ZDB-GENE-060510-3]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSCPOP00000004635',
        'gene_stable_id' => 'ENSCPOG00000005153',
        'genome' => 'cavia_porcellus',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSPPYP00000005997',
        'gene_stable_id' => 'ENSPPYG00000005264',
        'genome' => 'pongo_abelii',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSPSIP00000012858',
        'gene_stable_id' => 'ENSPSIG00000011574',
        'genome' => 'pelodiscus_sinensis',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSOARP00000011988',
        'gene_stable_id' => 'ENSOARG00000011179',
        'genome' => 'ovis_aries',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSOPRP00000014082',
        'gene_stable_id' => 'ENSOPRG00000015365',
        'genome' => 'ochotona_princeps',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSSHAP00000012162',
        'gene_stable_id' => 'ENSSHAG00000010421',
        'genome' => 'sarcophilus_harrisii',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSOGAP00000009477',
        'gene_stable_id' => 'ENSOGAG00000010588',
        'genome' => 'otolemur_garnettii',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSCSAP00000013938',
        'gene_stable_id' => 'ENSCSAG00000017920',
        'genome' => 'chlorocebus_sabaeus',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSMPUP00000001928',
        'gene_stable_id' => 'ENSMPUG00000001945',
        'genome' => 'mustela_putorius_furo',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSSARP00000002541',
        'gene_stable_id' => 'ENSSARG00000002755',
        'genome' => 'sorex_araneus',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSPVAP00000000225',
        'gene_stable_id' => 'ENSPVAG00000000246',
        'genome' => 'pteropus_vampyrus',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSTTRP00000010004',
        'gene_stable_id' => 'ENSTTRG00000010541',
        'genome' => 'tursiops_truncatus',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSSSCP00000022872',
        'gene_stable_id' => 'ENSSSCG00000020961',
        'genome' => 'sus_scrofa',
        'description' => undef
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSSSCP00000028073',
        'gene_stable_id' => 'ENSSSCG00000029039',
        'genome' => 'sus_scrofa',
        'description' => undef
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSDNOP00000034947',
        'gene_stable_id' => 'ENSDNOG00000038771',
        'genome' => 'dasypus_novemcinctus',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSAMXP00000013440',
        'gene_stable_id' => 'ENSAMXG00000013027',
        'genome' => 'astyanax_mexicanus',
        'description' => 'breast cancer 2, early onset [Source:ZFIN;Acc:ZDB-GENE-060510-3]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSEEUP00000008968',
        'gene_stable_id' => 'ENSEEUG00000009739',
        'genome' => 'erinaceus_europaeus',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSETEP00000003277',
        'gene_stable_id' => 'ENSETEG00000003989',
        'genome' => 'echinops_telfairi',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSPCAP00000000440',
        'gene_stable_id' => 'ENSPCAG00000000379',
        'genome' => 'procavia_capensis',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSOANP00000024376',
        'gene_stable_id' => 'ENSOANG00000015481',
        'genome' => 'ornithorhynchus_anatinus',
        'description' => 'Uncharacterized protein  [Source:UniProtKB/TrEMBL;Acc:F7B8W7]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSDORP00000006609',
        'gene_stable_id' => 'ENSDORG00000007049',
        'genome' => 'dipodomys_ordii',
        'description' => 'breast cancer 2, early onset [Source:MGI Symbol;Acc:MGI:109337]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSVPAP00000000821',
        'gene_stable_id' => 'ENSVPAG00000000886',
        'genome' => 'vicugna_pacos',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSTSYP00000000441',
        'gene_stable_id' => 'ENSTSYG00000000478',
        'genome' => 'tarsius_syrichta',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSCHOP00000007822',
        'gene_stable_id' => 'ENSCHOG00000008817',
        'genome' => 'choloepus_hoffmanni',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSGMOP00000010385',
        'gene_stable_id' => 'ENSGMOG00000009699',
        'genome' => 'gadus_morhua',
        'description' => 'breast cancer 2, early onset [Source:ZFIN;Acc:ZDB-GENE-060510-3]'
      },
      {
        'source_name' => 'ENSEMBLPEP',
        'protein_stable_id' => 'ENSMEUP00000009812',
        'gene_stable_id' => 'ENSMEUG00000010691',
        'genome' => 'macropus_eugenii',
        'description' => 'breast cancer 2 [Source:HGNC Symbol;Acc:HGNC:1101]'
      }
    ],
    'description' => 'BREAST CANCER TYPE 2 SUSCEPTIBILITY HOMOLOG FANCONI ANEMIA GROUP D1 HOMOLOG',
    'family_stable_id' => 'PTHR11289_SF0'
  }
};
is_json_GET(
    '/family/id/PTHR11289_SF0?compara=homology;member_source=ensembl;sequence=none;aligned=0',
    $stripped_family_hash,
    'family for PTHR11289_SF0 stable id reduced to only ensembl members and no seq or alignments ',
);

is_json_GET(
    '/family/member/id/ENSG00000139618?compara=homology;member_source=ensembl;sequence=none;aligned=0',
    $stripped_family_by_gene_member,
    'Family by by gene ID reduced to only ensembl members and no seq or alignments',
);

is_json_GET(
    '/family/member/id/ENSP00000369497?compara=homology;member_source=ensembl;sequence=none;aligned=0',
    $stripped_family_hash,
    'Family by by transcript stable ID reduced to only ensembl members and no seq or alignments',
);

# Aliases are somehow not loaded yet, so we need to add one here
Bio::EnsEMBL::Registry->add_alias('homo_sapiens', 'johndoe');

#the family retured here is the brac2 family that I modified to include AL033381.1 as a member. This was done because brca2 is not in the symbol table of core's text db and I didnt want to modify that db.
is_json_GET(
    '/family/member/symbol/johndoe/AL033381.1?compara=homology;member_source=ensembl;sequence=none;aligned=0',
    $fake_family,
    'fake brac2 family returned using the symbol AL033381.1. The returned hash has been reduced to only ensembl members and no seq or alignments',
);
done_testing();
