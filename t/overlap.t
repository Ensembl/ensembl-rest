# Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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
use Bio::EnsEMBL::Test::TestUtils;

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');
my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('multi');
Catalyst::Test->import('EnsEMBL::REST');

my $base = '/overlap/region/homo_sapiens';

#Null based queries
{
  my $region = '6:1000000..2000000';
  is_json_GET("$base/$region?feature=none", [], 'Using feature type none returns nothing');
  action_bad_regex("$base/$region?feature=wibble", qr/wibble/, 'Using a bad feature type causes an exception');
}

#Get basic features overlapping
{
  my $region = '6:1000000..2000000';
  my $expected = 9;
  my $json = json_GET("$base/$region?feature=gene", '10 genes from chr 6');
  is(scalar(@{$json}), $expected, 'Genes in the basic region');
  
  is(
    @{json_GET("$base/$region?feature=gene;logic_name=ensembl", 'Ensembl logic name genes')}, 
    1, '1 genes from chr 6 of logic name ensembl');
  
  is(
    @{json_GET("$base/$region?feature=gene;logic_name=wibble", 'Wibble logic name genes')}, 
    0, '0 genes from chr 6 of logic name wibble');
  
  is(
    @{json_GET("$base/$region?feature=gene;logic_name=ensembl;db_type=core", 'Ensembl logic name genes from enforced core DB')}, 
    1, '1 genes from chr 6 of logic name ensembl from enforced core db');
  
  warns_like(sub {
    is_json_GET("$base/$region?feature=gene;db_type=wibble",[], 'Bad db type given');
  }, qr/No adaptor.+ object type Gene/s, 'Checking for internal warnings when bad DB type given');
}

#Inspect the first feature
{
  my $region = '6:1078245-1108340';
  my $json = json_GET("$base/$region?feature=gene;feature=transcript;feature=cds;feature=exon", 'Gene models');
  is(scalar(@{$json}), 7, '7 features representing gene models');
  
  my ($gene) = grep { $_->{feature_type} eq 'gene' } @{$json};
  eq_or_diff_data($gene, {
    id => 'ENSG00000176515',
    biotype => 'protein_coding',
    description => 'Uncharacterized protein; cDNA FLJ34594 fis, clone KIDNE2009109  [Source:UniProtKB/TrEMBL;Acc:Q8NAX6]',
    end => 1105181,
    external_name => 'AL033381.1',
    feature_type => 'gene',
    logic_name => 'ensembl',
    seq_region_name => '6',
    source => 'ensembl',
    start => 1080164,
    strand => 1,
    assembly_name => 'GRCh37',
  }, 'Checking structure of gene model as expected');
  
  my ($transcript) = grep { $_->{feature_type} eq 'transcript' } @{$json};
  is($transcript->{Parent}, $gene->{id}, 'Transcript parent is previous gene');
  
  my ($cds) = sort { $a->{start} <=> $b->{start} } grep { $_->{feature_type} eq 'cds'} @{$json};
  is($cds->{id}, 'ENSP00000320396', 'CDS ID is a protein ID');
  is($cds->{Parent}, $transcript->{id}, 'CDS parent is the previous transcript');
  is($cds->{start}, 1101508, 'First CDS starts at first coding point in the second exon');
  is($cds->{end}, 1101531, 'First CDS ends at the second exon');
  is($cds->{source}, 'ensembl', 'CDS has source ensembl');
}

# Biotype queries
{
  my $region = '6:1078245-1108340';
  my $json = json_GET("$base/$region?feature=gene;biotype=protein_coding", 'Fetching protein coding genes');
  is(scalar(@{$json}), 1, '1 protein coding gene models expected');

  $json = json_GET("$base/$region?feature=gene;biotype=wibble", 'Fetching wibble biotype genes');
  is(scalar(@{$json}), 0, '0 wibble biotype gene models expected');

  $json = json_GET("$base/$region?feature=gene;biotype=protein_coding;logic_name=wibble", 'Fetching protein coding genes logic name wibble');
  is(scalar(@{$json}), 0, '0 protein coding logic name wibble gene models');

  $json = json_GET("$base/$region?feature=gene;biotype=protein_coding;source=wibble", 'Fetching protein coding genes source wibble');
  is(scalar(@{$json}), 0, '0 protein coding source wibble gene models');

  $json = json_GET("$base/$region?feature=gene;biotype=wibble;biotype=protein_coding", 'Fetching protein coding and wibble biotype genes');
  is(scalar(@{$json}), 1, '1 protein coding and wibble biotype gene models expected');

  #DO transcript checks
  $json = json_GET("$base/$region?feature=transcript;biotype=protein_coding", 'Fetching protein coding biotype transcripts');
  is(scalar(@{$json}), 1, '1 protein coding transcript models');

  $json = json_GET("$base/$region?feature=transcript;biotype=wibble", 'Fetching wibble biotype transcripts');
  is(scalar(@{$json}), 0, '0 biotype wibble transcript models');

  $json = json_GET("$base/$region?feature=transcript;biotype=wibble;biotype=protein_coding", 'Fetching wibble & protein_coding biotype transcripts');
  is(scalar(@{$json}), 1, '1 biotype wibble and protein_coding transcript models');
}

#trim_(upstream|downstream) queries
{
  # positive strand, trim 5'
  my $region = '6:1081000-1108340';
  my $json = json_GET("$base/$region?feature=gene;trim_upstream=0", 'Positive strand, no upstream trimming');
  is(scalar(@{$json}), 1, '1 protein coding gene models expected');

  $json = json_GET("$base/$region?feature=gene;trim_upstream=1", 'Positive stramd, trim upstream');
  is(scalar(@{$json}), 0, '0 gene models expected');
  
  # positive strand, trim 3'
  $region = '6:1080000-1104000';
  $json = json_GET("$base/$region?feature=gene;trim_downstream=0", 'Positive strand, no downstream trimming');
  is(scalar(@{$json}), 1, '1 protein coding gene models expected');

  $json = json_GET("$base/$region?feature=gene;trim_downstream=1", 'Positive strand, trim downstream');
  is(scalar(@{$json}), 0, '0 gene models expected');

  # positive strand, trim both
  $region = '6:1081000-1104000';
  $json = json_GET("$base/$region?feature=gene;trim_upstream=1;trim_downstream=1", 'Positive strand, trim up-downstream');
  is(scalar(@{$json}), 0, '0 gene models expected');

  $region = '6:1080000-1108000';
  $json = json_GET("$base/$region?feature=gene;trim_upstream=1;trim_downstream=1", 'Positive strand, trim up-downstream');
  is(scalar(@{$json}), 1, '1 gene models expected');
  
  # negative strand, trim 5'
  $region = '6:1510000-1515000:-1';
  $json = json_GET("$base/$region?feature=gene;trim_upstream=0", 'Negative strand, no upstream trimming');
  is(scalar(@{$json}), 1, '1 protein coding gene models expected');

  $json = json_GET("$base/$region?feature=gene;trim_upstream=1", 'Negative strand, trim upstream');
  is(scalar(@{$json}), 0, '0 gene models expected');

  # negative strand, trim 3'
  $region = '6:1514000-1516000:-1';
  $json = json_GET("$base/$region?feature=gene;trim_downstream=0", 'Negative strand, no downstream trimming');
  is(scalar(@{$json}), 1, '1 protein coding gene models expected');

  $json = json_GET("$base/$region?feature=gene;trim_downstream=1", 'Negative strand, trim downstream');
  is(scalar(@{$json}), 0, '0 gene models expected');

  # negative strand, trim both
  $region = '6:1514000-1515000';
  $json = json_GET("$base/$region?feature=gene;trim_upstream=1;trim_downstream=1", 'Negative strand, trim up-downstream');
  is(scalar(@{$json}), 0, '0 gene models expected');

  $region = '6:1513000-1516000';
  $json = json_GET("$base/$region?feature=gene;trim_upstream=1;trim_downstream=1", 'Negative strand, trim up-downstream');
  is(scalar(@{$json}), 1, '1 gene models expected');
  
}


#Query variation DB
{
  my $region = '6:1000000-1003000';
  my $expected_count = 2;
  my $json = json_GET("$base/$region?feature=variation", 'Fetching variations at '.$region);
  is(scalar(@{$json}), $expected_count, 'Expected variations at '.$region);
  eq_or_diff_data($json->[0],{
    start => 1001893,
    assembly_name => 'GRCh37',
    end => 1001893,
    strand => 1,
    id => 'tmp__',
    consequence_type => 'intergenic_variant',
    feature_type => 'variation',
    seq_region_name => '6',
    alt_alleles => [ qw/T -/]
  }, 'Checking one variation format');
  
  my $somatic_json = json_GET("$base/$region?feature=somatic_variation", 'Fetching somatic variations at '.$region);
  is(scalar(@{$somatic_json}), 1, 'Expected somatic variations at '.$region);
  
  #SO:0001650 inframe_variant which has no entries
  is_json_GET("$base/$region?feature=variation;so_term=inframe_variant", [], 'SO term querying');
  is_json_GET("$base/$region?feature=variation;so_term=SO:0001650", [], 'SO accession querying');
  
  #Normal SO querying
  my $intergenic = 'intergenic_variant';
  my $json_so = json_GET("$base/$region?feature=variation;so_term=$intergenic", 'SO term querying with known type');
  is(scalar(@{$json}), $expected_count, 'Expected '.$intergenic.' variations at '.$region);
}

#Query for other objects
{
  my $region = '6:1000000..1010000';
  my $json = json_GET("$base/$region?feature=repeat", 'Getting RepeatFeature JSON');
  is(22, scalar(@{$json}), 'Searching for 22 repeats');
  eq_or_diff_data($json->[0], {
    start => 1000732,
    assembly_name => 'GRCh37',
    end => 1000776,
    strand => 0, # YES DON'T CHANGE THIS; THEY DO NOT HAVE A STRAND
    description => 'dust',
    seq_region_name => '6',
    feature_type => 'repeat',
  }, 'Checking one repeat');
}

#Simple feature testing
{
  my $region = '6:1020000..1030000';
  is_json_GET("$base/$region?feature=simple", [{
    start => 1026863,
    assembly_name => 'GRCh37',
    end => 1027454,
    strand => -1,
    feature_type => 'simple',
    score => 0.925,
    external_name => 'rank = 1',
    seq_region_name => '6',
    logic_name => 'firstef'
  }], 'Getting simple_feature as JSON');
  
  is_json_GET("$base/$region?feature=simple;logic_name=bogus", 
    [], 'Getting simple_feature no entries with bogus logic_name as JSON');
}

#Misc feature
{
  my $region = '6:1070000..1080000';
  my $thirty_k_feature = {
    start => 1040974,
    assembly_name => 'GRCh37',
    end => 1216597,
    strand => 1,
    id => '',
    feature_type => 'misc',
    seq_region_name => '6',
    
    clone_name => 'RP11-550K21',
    misc_set_code => [qw/cloneset_30k/],
    misc_set_name => ['30k clone set'],
    type => 'arrayclone',
    alt_well_name => 'ChrtpXtra-384-4L20',
    bacend_well_nam => 'Chr6tp-M-1G12', #Not a typo; well not here as the attrib code is bacend_well_nam
    sanger_project => 'bA550K21',
    well_name => 'Chr6tp-3D12',
  };
  is_json_GET("$base/$region?feature=misc", [
  {
    start => 1072318,
    assembly_name => 'GRCh37',
    end => 1248050,
    strand => 1,
    id => '',
    feature_type => 'misc',
    seq_region_name => '6',
    
    clone_name => 'RP11-488J04',
    misc_set_code => [qw/cloneset_32k/],
    misc_set_name => ['32k clone set'],
    type => 'arrayclone',
  },
  $thirty_k_feature  
  ], 'Getting misc_feature as JSON with no limits');
  
  is_json_GET("$base/$region?feature=misc;misc_set=cloneset_30k",
     [$thirty_k_feature], 'Getting misc_feature as JSON with misc_set limit of cloneset_30k');
}

#Ask for a region too big
action_bad_regex(
  "$base/6:1..2000000?feature=gene",
  qr/maximum allowed length/, 
  'Too large a region means no data'
);

########### GFF Testing

{
  my $region = '6:1078245-1108340';
  my $gff = gff_GET("$base/$region?feature=gene", 'Getting single gene');
  my @lines = filter_gff($gff);
  is(scalar(@lines), 1, '1 GFF line with 1 gene in this region');
  
  my $gff_line = qq{6\tensembl\tgene\t1080164\t1105181\t.\t+\t.\tID=gene:ENSG00000176515;assembly_name=GRCh37;biotype=protein_coding;description=Uncharacterized protein%3B cDNA FLJ34594 fis%2C clone KIDNE2009109  [Source:UniProtKB/TrEMBL%3BAcc:Q8NAX6];external_name=AL033381.1;logic_name=ensembl};
  eq_or_diff($lines[0], $gff_line, 'Expected output gene line from GFF');
}

{
  my $region = '6:1079386-1079387';
  my $gff = gff_GET("$base/$region?feature=repeat", 'Getting a single repeat');
  my @lines = filter_gff($gff);
  is(scalar(@lines), 1, '1 GFF line with 1 repeat in this region');
  
  my $gff_line = qq{6\twibble\trepeat_region\t1079386\t1079387\t.\t+\t.\tassembly_name=GRCh37;description=AluSq};
  eq_or_diff($lines[0], $gff_line, 'Expected output repeat feature line from GFF');
}

sub filter_gff {
  my ($gff) = @_;
  return unless $gff;
  return grep { $_ !~ /^#/ && $_ ne q{} } split(/\n/, $gff);
}

########### BED Testing
{
  my $region = '6:1078245-1108340';
  my $bed = bed_GET("$base/$region?feature=gene", 'Getting single gene'); 
  my $expected_bed = qq{chr6\t1080163\t1105181\tENSG00000176515\t0\t+\n};
  eq_or_diff($bed, $expected_bed, 'Expected output gene line from BED');
}

{
  my $region = '6:1078245-1108340';
  my $bed = bed_GET("$base/$region?feature=transcript", 'Getting a set of transcripts from both strands');
  my $expected_bed = qq{chr6\t1080163\t1105181\tENST00000314040\t0\t+\t1101507\t1102415\t0\t3\t66,228,3141,\t0,21140,21877,\n};
  eq_or_diff($bed, $expected_bed, 'Expected output transcript line from BED with exons and their offsets');
}

{
  my $region = '6:1078245-1108340';
  my $transcript_bed = bed_GET("$base/$region?feature=transcript", 'Getting BED transcript features'); 
  my $cds_bed = bed_GET("$base/$region?feature=cds", 'Getting BED cds features'); 
  eq_or_diff($transcript_bed, $cds_bed, 'When serialising with BED feature=transcript and feature=cds returns the same data');
}


########### ID endpoint testing

$base = '/overlap/id';

#Null based queries
{
  my $id = 'ENSG00000176515';
  is_json_GET("$base/$id?feature=none", [], 'Using feature type none returns nothing');
  action_bad_regex("$base/$id?feature=wibble", qr/wibble/, 'Using a bad feature type causes an exception');
}

#Get basic features overlapping
{
  my $id = 'ENSG00000176515';
  is(
    @{json_GET("$base/$id?feature=exon", 'Ensembl exons')},
    3, '3 exons for gene ENSG00000176515');
  
  is(
    @{json_GET("$base/$id?feature=repeat;logic_name=repeatmask", 'Ensembl logic name repeats')}, 
    67, '67 repeats overlapping ENSG00000176515 of logic name repeatmask');
  
  is(
    @{json_GET("$base/$id?feature=misc;misc_set=cloneset_30k", 'Ensembl cloneset misc features')}, 
    1, '1 misc feature for cloneset_30k overlapping ENSG00000176515');
  
  is(
    @{json_GET("$base/$id?feature=transcript;biotype=protein_coding", 'Ensembl biotype transcripts')}, 
    1, '1 transcript for gene ENSG00000176515');

  is(
    @{json_GET("$base/$id?feature=variation;so_term=intergenic_variant", 'Ensembl variation with so term')},
    5, '5 intergenic variants overlapping ENSG00000176515');
  
  # retriving features a -ve feature still ensures we report it on the -ve strand
  my $negative_id = 'ENSG00000261730'; #fetch features from a -ve stranded feature
  my $negative_json = json_GET("$base/$negative_id?feature=gene", 'Retriving negative stranded features from a negative stranded feature'); 
  cmp_ok(scalar(@{$negative_json}), '>', 0, 'We got features back');
  is($negative_json->[0]->{id}, $negative_id, 'Feature ID was the submitted one to the service');
  is($negative_json->[0]->{strand}, -1, 'The strand of the feature must be negative');
}

########### Translation endpoint testing

$base = '/overlap/translation';

#Null based queries
{
  my $id = 'ENSP00000371073';
  action_bad_regex("$base/$id?feature=wibble", qr/wibble/, 'Using a bad feature type causes an exception');
}

#Get protein and variation features
{
  my $id = 'ENSP00000371073';
  is(
    @{json_GET("$base/$id", 'Protein domains for ENSP00000371073')},
    4, "4 protein domains for $id");

  is(
    @{json_GET("$base/$id?feature=protein_feature;type=Superfamily", 'Ensembl superfamily domains')}, 
    1, '1 superfamily domains fetched via logic _name and feature type');
  
  is(
    @{json_GET("$base/$id?feature=transcript_variation", 'Ensembl transcript variation')}, 
    3, "3 variation feature for $id");
  
  is(
    @{json_GET("$base/$id?feature=transcript_variation;feature=protein_feature", 'Ensembl biotype transcripts')}, 
    7, "7 features for protein $id");

  is(
    @{json_GET("$base/$id?feature=transcript_variation;so_term=intron_variant", 'Ensembl variation with so term')},
    3, "3 intron variants for $id");
  is(
    @{json_GET("$base/$id?feature=somatic_transcript_variation", 'Ensembl variation with somatic data')},
    2, "2 somatic variations overlapping $id");
}

#Check can we get the splice sites and exon boundaries of a translation
{
  my $id = 'ENSP00000371073';
  my $json = json_GET("$base/$id?feature=translation_exon", 'Getting exon information from a translation');
  cmp_ok(scalar(@{$json}), '==', 6, 'Expect 6 translatable exons');
  my $expected_exon_one = { start => 1, end => 43, rank => 1, id => 'ENSE00002753423', feature_type => 'translation_exon', seq_region_name => $id };
  eq_or_diff($json->[0], $expected_exon_one, 'Checking that the 1st exon has the expected location');

  my $expected_exon_two = { start => 43, end => 88, rank => 2, id => 'ENSE00002909822', feature_type => 'translation_exon', seq_region_name => $id };
  eq_or_diff($json->[1], $expected_exon_two, 'Checking that the 2nd exon has the expected location');
}

#Retriving splice site overlaps like the one mentioned between exons 1 & 2
{
  my $id = 'ENSP00000371073';
  my $json = json_GET("$base/$id?feature=residue_overlap", 'Getting residue_overlap information from a translation');
  cmp_ok(scalar(@{$json}), '==', 2, 'Expect 2 overlaps');
  my $expected = { start => 43, end => 43, feature_type => 'residue_overlap', seq_region_name => $id };
  eq_or_diff($json->[0], $expected, 'Checking that the overlap is at the expected location');
}


done_testing();
