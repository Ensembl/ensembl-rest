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

my ($json);

#the normal returned hash with the alignment would have been too big
my $stripped_family_hash= {
  'type' => 'family',
  'id' => 'PTHR11289_SF0',
  'MEMBERS' => {
    'ENSEMBL_gene_members' => {
      'ENSTNIG00000016261' => [
        {
          'protein_stable_id' => 'ENSTNIP00000002435'
        }
      ],
      'ENSXETG00000017011' => [
        {
          'protein_stable_id' => 'ENSXETP00000060681'
        }
      ],
      'ENSSARG00000002755' => [
        {
          'protein_stable_id' => 'ENSSARP00000002541'
        }
      ],
      'ENSAMXG00000013027' => [
        {
          'protein_stable_id' => 'ENSAMXP00000013440'
        }
      ],
      'ENSXMAG00000006974' => [
        {
          'protein_stable_id' => 'ENSXMAP00000006983'
        }
      ],
      'ENSNLEG00000001048' => [
        {
          'protein_stable_id' => 'ENSNLEP00000001277'
        }
      ],
      'ENSLACG00000007788' => [
        {
          'protein_stable_id' => 'ENSLACP00000008815'
        }
      ],
      'ENSDORG00000007049' => [
        {
          'protein_stable_id' => 'ENSDORP00000006609'
        }
      ],
      'ENSPVAG00000000246' => [
        {
          'protein_stable_id' => 'ENSPVAP00000000225'
        }
      ],
      'ENSFCAG00000025587' => [
        {
          'protein_stable_id' => 'ENSFCAP00000019777'
        }
      ],
      'ENSMPUG00000001945' => [
        {
          'protein_stable_id' => 'ENSMPUP00000001928'
        }
      ],
      'ENSGGOG00000015808' => [
        {
          'protein_stable_id' => 'ENSGGOP00000015446'
        }
      ],
      'ENSTSYG00000000478' => [
        {
          'protein_stable_id' => 'ENSTSYP00000000441'
        }
      ],
      'ENSLAFG00000002670' => [
        {
          'protein_stable_id' => 'ENSLAFP00000002234'
        }
      ],
      'ENSCHOG00000008817' => [
        {
          'protein_stable_id' => 'ENSCHOP00000007822'
        }
      ],
      'ENSTBEG00000015907' => [
        {
          'protein_stable_id' => 'ENSTBEP00000013856'
        }
      ],
      'ENSCJAG00000018462' => [
        {
          'protein_stable_id' => 'ENSCJAP00000034250'
        }
      ],
      'ENSOPRG00000015365' => [
        {
          'protein_stable_id' => 'ENSOPRP00000014082'
        }
      ],
      'ENSPTRG00000005766' => [
        {
          'protein_stable_id' => 'ENSPTRP00000009812'
        }
      ],
      'ENSDNOG00000038771' => [
        {
          'protein_stable_id' => 'ENSDNOP00000034947'
        }
      ],
      'ENSONIG00000005522' => [
        {
          'protein_stable_id' => 'ENSONIP00000006940'
        }
      ],
      'ENSVPAG00000000886' => [
        {
          'protein_stable_id' => 'ENSVPAP00000000821'
        }
      ],
      'ENSEEUG00000009739' => [
        {
          'protein_stable_id' => 'ENSEEUP00000008968'
        }
      ],
      'ENSMEUG00000010691' => [
        {
          'protein_stable_id' => 'ENSMEUP00000009812'
        }
      ],
      'ENSETEG00000003989' => [
        {
          'protein_stable_id' => 'ENSETEP00000003277'
        }
      ],
      'ENSSSCG00000020961' => [
        {
          'protein_stable_id' => 'ENSSSCP00000022872'
        }
      ],
      'ENSAMEG00000009390' => [
        {
          'protein_stable_id' => 'ENSAMEP00000009909'
        }
      ],
      'ENSGMOG00000009699' => [
        {
          'protein_stable_id' => 'ENSGMOP00000010385'
        }
      ],
      'ENSAPLG00000007774' => [
        {
          'protein_stable_id' => 'ENSAPLP00000007411'
        }
      ],
      'ENSSHAG00000010421' => [
        {
          'protein_stable_id' => 'ENSSHAP00000012162'
        }
      ],
      'ENSCAFG00000006383' => [
        {
          'protein_stable_id' => 'ENSCAFP00000009557'
        }
      ],
      'ENSMGAG00000015077' => [
        {
          'protein_stable_id' => 'ENSMGAP00000015990'
        }
      ],
      'ENSLOCG00000008205' => [
        {
          'protein_stable_id' => 'ENSLOCP00000009962'
        }
      ],
      'ENSTRUG00000006177' => [
        {
          'protein_stable_id' => 'ENSTRUP00000015030'
        }
      ],
      'ENSSTOG00000005517' => [
        {
          'protein_stable_id' => 'ENSSTOP00000004979'
        }
      ],
      'ENSOANG00000030391' => [
        {
          'protein_stable_id' => 'ENSOANP00000032170'
        }
      ],
      'ENSECAG00000014890' => [
        {
          'protein_stable_id' => 'ENSECAP00000013146'
        }
      ],
      'ENSTGUG00000011763' => [
        {
          'protein_stable_id' => 'ENSTGUP00000012130'
        }
      ],
      'ENSOGAG00000010588' => [
        {
          'protein_stable_id' => 'ENSOGAP00000009477'
        }
      ],
      'ENSBTAG00000000988' => [
        {
          'protein_stable_id' => 'ENSBTAP00000001311'
        }
      ],
      'ENSSSCG00000029039' => [
        {
          'protein_stable_id' => 'ENSSSCP00000028073'
        }
      ],
      'ENSPPYG00000005264' => [
        {
          'protein_stable_id' => 'ENSPPYP00000005997'
        }
      ],
      'ENSMLUG00000013741' => [
        {
          'protein_stable_id' => 'ENSMLUP00000012516'
        }
      ],
      'ENSPANG00000013323' => [
        {
          'protein_stable_id' => 'ENSPANP00000002726'
        }
      ],
      'ENSFALG00000008451' => [
        {
          'protein_stable_id' => 'ENSFALP00000008821'
        }
      ],
      'ENSOANG00000015481' => [
        {
          'protein_stable_id' => 'ENSOANP00000024376'
        }
      ],
      'ENSTTRG00000010541' => [
        {
          'protein_stable_id' => 'ENSTTRP00000010004'
        }
      ],
      'ENSCSAG00000017920' => [
        {
          'protein_stable_id' => 'ENSCSAP00000013938'
        }
      ],
      'ENSGACG00000011490' => [
        {
          'protein_stable_id' => 'ENSGACP00000015199'
        }
      ],
      'ENSPCAG00000000379' => [
        {
          'protein_stable_id' => 'ENSPCAP00000000440'
        }
      ],
      'ENSOCUG00000016878' => [
        {
          'protein_stable_id' => 'ENSOCUP00000014514'
        }
      ],
      'ENSMODG00000009516' => [
        {
          'protein_stable_id' => 'ENSMODP00000033276'
        }
      ],
      'ENSPFOG00000001640' => [
        {
          'protein_stable_id' => 'ENSPFOP00000001575'
        }
      ],
      'ENSOARG00000011179' => [
        {
          'protein_stable_id' => 'ENSOARP00000011988'
        }
      ],
      'ENSPSIG00000011574' => [
        {
          'protein_stable_id' => 'ENSPSIP00000012858'
        }
      ],
      'ENSG00000139618' => [
        {
          'protein_stable_id' => 'ENSP00000369497'
        }
      ],
      'ENSCPOG00000005153' => [
        {
          'protein_stable_id' => 'ENSCPOP00000004635'
        }
      ]
    }
  }
};


my $stripped_family_by_gene_member ={
  '1' => {
    'type' => 'family',
    'id' => 'PTHR11289_SF0',
    'MEMBERS' => {
      'ENSEMBL_gene_members' => {
        'ENSTNIG00000016261' => [
          {
            'protein_stable_id' => 'ENSTNIP00000002435'
          }
        ],
        'ENSXETG00000017011' => [
          {
            'protein_stable_id' => 'ENSXETP00000060681'
          }
        ],
        'ENSSARG00000002755' => [
          {
            'protein_stable_id' => 'ENSSARP00000002541'
          }
        ],
        'ENSAMXG00000013027' => [
          {
            'protein_stable_id' => 'ENSAMXP00000013440'
          }
        ],
        'ENSXMAG00000006974' => [
          {
            'protein_stable_id' => 'ENSXMAP00000006983'
          }
        ],
        'ENSNLEG00000001048' => [
          {
            'protein_stable_id' => 'ENSNLEP00000001277'
          }
        ],
        'ENSLACG00000007788' => [
          {
            'protein_stable_id' => 'ENSLACP00000008815'
          }
        ],
        'ENSDORG00000007049' => [
          {
            'protein_stable_id' => 'ENSDORP00000006609'
          }
        ],
        'ENSPVAG00000000246' => [
          {
            'protein_stable_id' => 'ENSPVAP00000000225'
          }
        ],
        'ENSFCAG00000025587' => [
          {
            'protein_stable_id' => 'ENSFCAP00000019777'
          }
        ],
        'ENSMPUG00000001945' => [
          {
            'protein_stable_id' => 'ENSMPUP00000001928'
          }
        ],
        'ENSGGOG00000015808' => [
          {
            'protein_stable_id' => 'ENSGGOP00000015446'
          }
        ],
        'ENSTSYG00000000478' => [
          {
            'protein_stable_id' => 'ENSTSYP00000000441'
          }
        ],
        'ENSLAFG00000002670' => [
          {
            'protein_stable_id' => 'ENSLAFP00000002234'
          }
        ],
        'ENSCHOG00000008817' => [
          {
            'protein_stable_id' => 'ENSCHOP00000007822'
          }
        ],
        'ENSTBEG00000015907' => [
          {
            'protein_stable_id' => 'ENSTBEP00000013856'
          }
        ],
        'ENSCJAG00000018462' => [
          {
            'protein_stable_id' => 'ENSCJAP00000034250'
          }
        ],
        'ENSOPRG00000015365' => [
          {
            'protein_stable_id' => 'ENSOPRP00000014082'
          }
        ],
        'ENSPTRG00000005766' => [
          {
            'protein_stable_id' => 'ENSPTRP00000009812'
          }
        ],
        'ENSDNOG00000038771' => [
          {
            'protein_stable_id' => 'ENSDNOP00000034947'
          }
        ],
        'ENSONIG00000005522' => [
          {
            'protein_stable_id' => 'ENSONIP00000006940'
          }
        ],
        'ENSVPAG00000000886' => [
          {
            'protein_stable_id' => 'ENSVPAP00000000821'
          }
        ],
        'ENSEEUG00000009739' => [
          {
            'protein_stable_id' => 'ENSEEUP00000008968'
          }
        ],
        'ENSMEUG00000010691' => [
          {
            'protein_stable_id' => 'ENSMEUP00000009812'
          }
        ],
        'ENSETEG00000003989' => [
          {
            'protein_stable_id' => 'ENSETEP00000003277'
          }
        ],
        'ENSSSCG00000020961' => [
          {
            'protein_stable_id' => 'ENSSSCP00000022872'
          }
        ],
        'ENSAMEG00000009390' => [
          {
            'protein_stable_id' => 'ENSAMEP00000009909'
          }
        ],
        'ENSGMOG00000009699' => [
          {
            'protein_stable_id' => 'ENSGMOP00000010385'
          }
        ],
        'ENSAPLG00000007774' => [
          {
            'protein_stable_id' => 'ENSAPLP00000007411'
          }
        ],
        'ENSSHAG00000010421' => [
          {
            'protein_stable_id' => 'ENSSHAP00000012162'
          }
        ],
        'ENSCAFG00000006383' => [
          {
            'protein_stable_id' => 'ENSCAFP00000009557'
          }
        ],
        'ENSMGAG00000015077' => [
          {
            'protein_stable_id' => 'ENSMGAP00000015990'
          }
        ],
        'ENSLOCG00000008205' => [
          {
            'protein_stable_id' => 'ENSLOCP00000009962'
          }
        ],
        'ENSTRUG00000006177' => [
          {
            'protein_stable_id' => 'ENSTRUP00000015030'
          }
        ],
        'ENSSTOG00000005517' => [
          {
            'protein_stable_id' => 'ENSSTOP00000004979'
          }
        ],
        'ENSOANG00000030391' => [
          {
            'protein_stable_id' => 'ENSOANP00000032170'
          }
        ],
        'ENSECAG00000014890' => [
          {
            'protein_stable_id' => 'ENSECAP00000013146'
          }
        ],
        'ENSTGUG00000011763' => [
          {
            'protein_stable_id' => 'ENSTGUP00000012130'
          }
        ],
        'ENSOGAG00000010588' => [
          {
            'protein_stable_id' => 'ENSOGAP00000009477'
          }
        ],
        'ENSBTAG00000000988' => [
          {
            'protein_stable_id' => 'ENSBTAP00000001311'
          }
        ],
        'ENSSSCG00000029039' => [
          {
            'protein_stable_id' => 'ENSSSCP00000028073'
          }
        ],
        'ENSPPYG00000005264' => [
          {
            'protein_stable_id' => 'ENSPPYP00000005997'
          }
        ],
        'ENSMLUG00000013741' => [
          {
            'protein_stable_id' => 'ENSMLUP00000012516'
          }
        ],
        'ENSPANG00000013323' => [
          {
            'protein_stable_id' => 'ENSPANP00000002726'
          }
        ],
        'ENSFALG00000008451' => [
          {
            'protein_stable_id' => 'ENSFALP00000008821'
          }
        ],
        'ENSOANG00000015481' => [
          {
            'protein_stable_id' => 'ENSOANP00000024376'
          }
        ],
        'ENSTTRG00000010541' => [
          {
            'protein_stable_id' => 'ENSTTRP00000010004'
          }
        ],
        'ENSCSAG00000017920' => [
          {
            'protein_stable_id' => 'ENSCSAP00000013938'
          }
        ],
        'ENSGACG00000011490' => [
          {
            'protein_stable_id' => 'ENSGACP00000015199'
          }
        ],
        'ENSPCAG00000000379' => [
          {
            'protein_stable_id' => 'ENSPCAP00000000440'
          }
        ],
        'ENSOCUG00000016878' => [
          {
            'protein_stable_id' => 'ENSOCUP00000014514'
          }
        ],
        'ENSMODG00000009516' => [
          {
            'protein_stable_id' => 'ENSMODP00000033276'
          }
        ],
        'ENSPFOG00000001640' => [
          {
            'protein_stable_id' => 'ENSPFOP00000001575'
          }
        ],
        'ENSOARG00000011179' => [
          {
            'protein_stable_id' => 'ENSOARP00000011988'
          }
        ],
        'ENSPSIG00000011574' => [
          {
            'protein_stable_id' => 'ENSPSIP00000012858'
          }
        ],
        'ENSG00000139618' => [
          {
            'protein_stable_id' => 'ENSP00000369497'
          }
        ],
        'ENSCPOG00000005153' => [
          {
            'protein_stable_id' => 'ENSCPOP00000004635'
          }
        ]
      }
    }
  }
};


my $fake_family = {
  '1' => {
    'type' => 'family',
    'id' => 'PTHR11289_SF0',
    'MEMBERS' => {
      'ENSEMBL_gene_members' => {
        'ENSTNIG00000016261' => [
          {
            'protein_stable_id' => 'ENSTNIP00000002435'
          }
        ],
        'ENSXETG00000017011' => [
          {
            'protein_stable_id' => 'ENSXETP00000060681'
          }
        ],
        'ENSSARG00000002755' => [
          {
            'protein_stable_id' => 'ENSSARP00000002541'
          }
        ],
        'ENSAMXG00000013027' => [
          {
            'protein_stable_id' => 'ENSAMXP00000013440'
          }
        ],
        'ENSXMAG00000006974' => [
          {
            'protein_stable_id' => 'ENSXMAP00000006983'
          }
        ],
        'ENSNLEG00000001048' => [
          {
            'protein_stable_id' => 'ENSNLEP00000001277'
          }
        ],
        'ENSLACG00000007788' => [
          {
            'protein_stable_id' => 'ENSLACP00000008815'
          }
        ],
        'ENSDORG00000007049' => [
          {
            'protein_stable_id' => 'ENSDORP00000006609'
          }
        ],
        'ENSPVAG00000000246' => [
          {
            'protein_stable_id' => 'ENSPVAP00000000225'
          }
        ],
        'ENSFCAG00000025587' => [
          {
            'protein_stable_id' => 'ENSFCAP00000019777'
          }
        ],
        'ENSMPUG00000001945' => [
          {
            'protein_stable_id' => 'ENSMPUP00000001928'
          }
        ],
        'ENSGGOG00000015808' => [
          {
            'protein_stable_id' => 'ENSGGOP00000015446'
          }
        ],
        'ENSTSYG00000000478' => [
          {
            'protein_stable_id' => 'ENSTSYP00000000441'
          }
        ],
        'ENSLAFG00000002670' => [
          {
            'protein_stable_id' => 'ENSLAFP00000002234'
          }
        ],
        'ENSCHOG00000008817' => [
          {
            'protein_stable_id' => 'ENSCHOP00000007822'
          }
        ],
        'ENSTBEG00000015907' => [
          {
            'protein_stable_id' => 'ENSTBEP00000013856'
          }
        ],
        'ENSCJAG00000018462' => [
          {
            'protein_stable_id' => 'ENSCJAP00000034250'
          }
        ],
        'ENSOPRG00000015365' => [
          {
            'protein_stable_id' => 'ENSOPRP00000014082'
          }
        ],
        'ENSPTRG00000005766' => [
          {
            'protein_stable_id' => 'ENSPTRP00000009812'
          }
        ],
        'ENSDNOG00000038771' => [
          {
            'protein_stable_id' => 'ENSDNOP00000034947'
          }
        ],
        'ENSONIG00000005522' => [
          {
            'protein_stable_id' => 'ENSONIP00000006940'
          }
        ],
        'ENSVPAG00000000886' => [
          {
            'protein_stable_id' => 'ENSVPAP00000000821'
          }
        ],
        'ENSEEUG00000009739' => [
          {
            'protein_stable_id' => 'ENSEEUP00000008968'
          }
        ],
        'ENSMEUG00000010691' => [
          {
            'protein_stable_id' => 'ENSMEUP00000009812'
          }
        ],
        'ENSETEG00000003989' => [
          {
            'protein_stable_id' => 'ENSETEP00000003277'
          }
        ],
        'ENSSSCG00000020961' => [
          {
            'protein_stable_id' => 'ENSSSCP00000022872'
          }
        ],
        'ENSAMEG00000009390' => [
          {
            'protein_stable_id' => 'ENSAMEP00000009909'
          }
        ],
        'ENSGMOG00000009699' => [
          {
            'protein_stable_id' => 'ENSGMOP00000010385'
          }
        ],
        'ENSAPLG00000007774' => [
          {
            'protein_stable_id' => 'ENSAPLP00000007411'
          }
        ],
        'ENSSHAG00000010421' => [
          {
            'protein_stable_id' => 'ENSSHAP00000012162'
          }
        ],
        'ENSCAFG00000006383' => [
          {
            'protein_stable_id' => 'ENSCAFP00000009557'
          }
        ],
        'ENSMGAG00000015077' => [
          {
            'protein_stable_id' => 'ENSMGAP00000015990'
          }
        ],
        'ENSLOCG00000008205' => [
          {
            'protein_stable_id' => 'ENSLOCP00000009962'
          }
        ],
        'ENSTRUG00000006177' => [
          {
            'protein_stable_id' => 'ENSTRUP00000015030'
          }
        ],
        'ENSSTOG00000005517' => [
          {
            'protein_stable_id' => 'ENSSTOP00000004979'
          }
        ],
        'ENSOANG00000030391' => [
          {
            'protein_stable_id' => 'ENSOANP00000032170'
          }
        ],
        'ENSECAG00000014890' => [
          {
            'protein_stable_id' => 'ENSECAP00000013146'
          }
        ],
        'ENSTGUG00000011763' => [
          {
            'protein_stable_id' => 'ENSTGUP00000012130'
          }
        ],
        'ENSOGAG00000010588' => [
          {
            'protein_stable_id' => 'ENSOGAP00000009477'
          }
        ],
        'ENSBTAG00000000988' => [
          {
            'protein_stable_id' => 'ENSBTAP00000001311'
          }
        ],
        'ENSSSCG00000029039' => [
          {
            'protein_stable_id' => 'ENSSSCP00000028073'
          }
        ],
        'ENSPPYG00000005264' => [
          {
            'protein_stable_id' => 'ENSPPYP00000005997'
          }
        ],
        'ENSMLUG00000013741' => [
          {
            'protein_stable_id' => 'ENSMLUP00000012516'
          }
        ],
        'ENSPANG00000013323' => [
          {
            'protein_stable_id' => 'ENSPANP00000002726'
          }
        ],
        'ENSFALG00000008451' => [
          {
            'protein_stable_id' => 'ENSFALP00000008821'
          }
        ],
        'ENSOANG00000015481' => [
          {
            'protein_stable_id' => 'ENSOANP00000024376'
          }
        ],
        'ENSTTRG00000010541' => [
          {
            'protein_stable_id' => 'ENSTTRP00000010004'
          }
        ],
        'ENSCSAG00000017920' => [
          {
            'protein_stable_id' => 'ENSCSAP00000013938'
          }
        ],
        'ENSGACG00000011490' => [
          {
            'protein_stable_id' => 'ENSGACP00000015199'
          }
        ],
        'ENSPCAG00000000379' => [
          {
            'protein_stable_id' => 'ENSPCAP00000000440'
          }
        ],
        'ENSOCUG00000016878' => [
          {
            'protein_stable_id' => 'ENSOCUP00000014514'
          }
        ],
        'ENSMODG00000009516' => [
          {
            'protein_stable_id' => 'ENSMODP00000033276'
          }
        ],
        'ENSPFOG00000001640' => [
          {
            'protein_stable_id' => 'ENSPFOP00000001575'
          }
        ],
        'ENSOARG00000011179' => [
          {
            'protein_stable_id' => 'ENSOARP00000011988'
          }
        ],
        'ENSPSIG00000011574' => [
          {
            'protein_stable_id' => 'ENSPSIP00000012858'
          }
        ],
        'ENSG00000139618' => [
          {
            'protein_stable_id' => 'ENSP00000369497'
          }
        ],
        'ENSCPOG00000005153' => [
          {
            'protein_stable_id' => 'ENSCPOP00000004635'
          }
        ]
      }
    }
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
