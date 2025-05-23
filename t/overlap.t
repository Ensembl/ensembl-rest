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
use Test::Deep;
use Catalyst::Test ();
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');
my $dba2 = Bio::EnsEMBL::Test::MultiTestDB->new('meleagris_gallopavo');
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
  cmp_deeply($gene, {
    id => 'ENSG00000176515',
    gene_id => 'ENSG00000176515',
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
    version => '1',
    canonical_transcript => 'ENST00000314040.1',
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
  cmp_deeply($json->[0],{
    start => 1001893,
    assembly_name => 'GRCh37',
    clinical_significance => [], 
    end => 1001893,
    strand => 1,
    id => 'tmp__',
    consequence_type => 'intergenic_variant',
    feature_type => 'variation',
    seq_region_name => '6',
    alleles => [ qw/T -/],
    source  => 'dbSNP'
  }, 'Checking one variation format');
  
  my $somatic_json = json_GET("$base/$region?feature=somatic_variation", 'Fetching somatic variations at '.$region);
  is(scalar(@{$somatic_json}), 1, 'Expected somatic variations at '.$region);
  
  #SO:0001650 inframe_variant which has no entries
  is_json_GET("$base/$region?feature=variation;so_term=inframe_variant", [], 'SO term querying');
  is_json_GET("$base/$region?feature=variation;so_term=SO:0001650", [], 'SO accession querying');
  
  #Normal SO querying
  my $intergenic = 'intergenic_variant';
  my $json_so = json_GET("$base/$region?feature=variation;so_term=$intergenic", 'SO term querying with known type');
  is(scalar(@{$json_so}), $expected_count, 'Expected '.$intergenic.' variations at '.$region);

  #Query by both SO & set
  my $set = '1kg_com';
  my $json_so_set= json_GET("$base/$region?feature=variation;so_term=$intergenic;variant_set=$set", 'SO term & variation set querying');
  is(scalar(@{$json_so_set}), $expected_count, 'Expected '.$intergenic.' variants in set '. $set .'at '.$region);

  # Error given if set does not exist
  my $bad_set = 'not_a_set';
  action_bad_regex( "$base/$region?feature=variation;so_term=$intergenic;variant_set=$bad_set", qr/No VariationSet found/, 'Throw if no set of this name' );
}

#Query for other objects
{
  my $region = '6:1000000..1010000';
  my $json = json_GET("$base/$region?feature=repeat", 'Getting RepeatFeature JSON');
  is(22, scalar(@{$json}), 'Searching for 22 repeats');
  cmp_deeply($json->[0], {
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
  cmp_deeply(json_GET("$base/$region?feature=simple","fetch simple_feature"), [{
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

#Band information testing
{
  my $region = '6:1020000..1030000';
  cmp_deeply(json_GET("$base/$region?feature=band", "fetch band"), [{
    start => 1026863,
    assembly_name => 'GRCh37',
    end => 1027454,
    strand => 0,
    feature_type => 'band',
    id => 'q11.21',
    stain => 'gneg',
    seq_region_name => '6',
  }], 'Getting band as JSON');

}

#MANE feature testing
{
  my $region = '6:1312098..1314758';
  cmp_deeply(json_GET("$base/$region?feature=mane", "Get MANE feature"), [{
    id => 'ENST00000296839',
    Parent => 'ENSG00000164379',
    assembly_name => 'GRCh37',
    start => 1312675,
    end => 1314992,
    strand => 1,
    seq_region_name => '6',
    feature_type => 'mane',
    refseq_match => 'NM_033260.4',
    type => 'MANE_Select',
    version => 2
  }], 'Getting MANE feature as JSON');
}

#Regulatory feature testing
{
  my $region = '1:76429380..76430144';
  cmp_deeply(json_GET("$base/$region?feature=regulatory", 'Get regulatory_feature'), [{
    id => 'ENSR00000105157',
    bound_end => 76430144,
    bound_start => 76429380,
    description => 'Open chromatin region',
    end => 76430144,
    feature_type => 'regulatory',
    seq_region_name => 1,
    source => 'Regulatory_Build',
    start => 76429380,
    strand => 0
  }], 'Getting regulatory_feature as JSON');
}

#Motif feature testing 
{
  my $region = '1:23034888..23034896';
  cmp_deeply(json_GET("$base/$region?feature=motif","Get motif_feature"), [{
    binding_matrix_stable_id => 'ENSPFM0001',
    end => 23034896,
    feature_type => 'motif',
    score => '7.391',
    seq_region_name => 1,
    start => 23034888,
    transcription_factor_complex => 'IRF8,IRF9,IRF5,IRF4',
    strand => -1,
    stable_id => 'ENSM00000000001'
  }], 'Getting motif_feature as JSON');
}

##Misc feature
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
  cmp_deeply(json_GET("$base/$region?feature=misc","Get misc_feature"), [
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
  
  cmp_deeply(json_GET("$base/$region?feature=misc;misc_set=cloneset_30k","Get misc_feature from cloneset_30k"),
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
  
  my $gff_line = qq{6\tensembl\tgene\t1080164\t1105181\t.\t+\t.\tID=gene:ENSG00000176515;Name=AL033381.1;assembly_name=GRCh37;biotype=protein_coding;description=Uncharacterized protein%3B cDNA FLJ34594 fis%2C clone KIDNE2009109  [Source:UniProtKB/TrEMBL%3BAcc:Q8NAX6];gene_id=ENSG00000176515;logic_name=ensembl;version=1};
  eq_or_diff($lines[0], $gff_line, 'Expected output gene line from GFF');
}

{
  my $region = '6:1079386-1079387';
  my $gff = gff_GET("$base/$region?feature=repeat", 'Getting a single repeat');
  my @lines = filter_gff($gff);
  is(scalar(@lines), 1, '1 GFF line with 1 repeat in this region');
  
  my $gff_line = qq{6\twibble\trepeat_region\t1079386\t1079680\t.\t+\t.\tassembly_name=GRCh37;description=AluSq};
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
  my $expected_bed = qq{chr6\t1080163\t1105181\tENSG00000176515\t1000\t+\n};
  eq_or_diff($bed, $expected_bed, 'Expected output gene line from BED');
}

{
  my $region = '6:1078245-1108340';
  my $bed = bed_GET("$base/$region?feature=transcript", 'Getting a set of transcripts from both strands');
  my $expected_bed = qq{chr6\t1080163\t1105181\tENST00000314040\t1000\t+\t1101507\t1102415\t0,0,0\t3\t66,228,3141,\t0,21140,21877,\tAL033381.1-201\tcmpl\tcmpl\t-1,-1,0,\tprotein_coding\tENSG00000176515\tAL033381.1\tprotein_coding\n};
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
    19, "19 variation feature for $id");
  
  is(
    @{json_GET("$base/$id?feature=transcript_variation;feature=protein_feature", 'Ensembl biotype transcripts')}, 
    23, "23 features for protein $id");

  is(
    @{json_GET("$base/$id?feature=transcript_variation;so_term=missense_variant", 'Ensembl variation with so term')},
    10, "10 missense variants for $id");
  is(
    @{json_GET("$base/$id?feature=somatic_transcript_variation", 'Ensembl variation with somatic data')},
    16, "16 somatic variations overlapping $id");
}

#Check that the protein start and end coordinates of a "long" variant (i.e. overlap more than 1 AA) are different
{
  my $id = 'ENSP00000370194';
  my $json = json_GET("$base/$id?feature=transcript_variation;so_term=inframe_deletion", 'Ensembl deletion variant with so term');
  my $expected_tv_start = 277;
  eq_or_diff($json->[0]->{start}, $expected_tv_start, "Checking the protein start coordinates of the variant");
  my $expected_tv_end = 283;
  eq_or_diff($json->[0]->{end}, $expected_tv_end, "Checking the protein end coordinates of the variant");
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

# Check that the correct description is returned
{
  my $id = 'ENSP00000371073';
  cmp_deeply(json_GET("$base/$id?type=smart", 'Ensembl Smart domains'), [{
    cigar_string => '',
    type => 'Smart',
    translation_id => 725227,
    start => 33,
    description => 'plcx_3',
    interpro => '',
    end => 202,
    align_type => undef,
    Parent => 'ENST00000381657',
    feature_type => 'protein_feature',
    hit_start => 1,
    hseqname => 'SM00148',
    seq_region_name => 'ENSP00000371073',
    id => 'SM00148',
    hit_end => 182
  }], 'Protein feature description displayed for \'Smart\' type');

  cmp_deeply(json_GET("$base/$id?type=pfam", 'Ensembl Pfam domains'), [{
    feature_type => 'protein_feature',
    hit_start => 24,
    align_type => undef,
    translation_id => 725227,
    cigar_string => '',
    start => 84,
    seq_region_name => 'ENSP00000371073',
    Parent => 'ENST00000381657',
    hit_end => 120,
    interpro => 'IPR000001',
    hseqname => 'PF00388',
    id => 'PF00388',
    type => 'Pfam',
    description => 'Kringle',
    end => 183
  }], 'Interpro description displayed for \'Pfam\' type');
}

# Test retrieving variation features where no variation db exists
{
  my $base = '/overlap/region/meleagris_gallopavo';
  my $region = '3:1000000..2000000';
  my $json = json_GET("$base/$region?feature=variation", "Retrieving variation where none exist");
  cmp_ok(scalar(@{$json}), "==", 0, "Empty list returned");
  $json = json_GET("$base/$region?feature=structural_variation", "Retrieving structural_variation where none exist");
  cmp_ok(scalar(@{$json}), "==", 0, "Empty list returned");
  $json = json_GET("$base/$region?feature=somatic_variation", "Retrieving somatic_variation where none exist");
  cmp_ok(scalar(@{$json}), "==", 0, "Empty list returned");
  $json = json_GET("$base/$region?feature=somatic_structural_variation", "Retrieving somatic_structural_variation where none exist");
  cmp_ok(scalar(@{$json}), "==", 0, "Empty list returned");
}

# Test structural_variation overlap endpoint
{
  my $base = '/overlap/region/homo_sapiens';
  my $region = '16:4000000..5000000';
  my $json = json_GET("$base/$region?feature=structural_variation", "Retrieving structural_variation");
  is(scalar(@{$json}), 1, '1 structural variation feature overlaps input region');
  $json = json_GET("$base/$region?feature=somatic_structural_variation", "Retrieving somatic_structural_variation");
  is(scalar(@{$json}), 1, '1 somatic structural variation feature overlaps input region');
}

done_testing();
