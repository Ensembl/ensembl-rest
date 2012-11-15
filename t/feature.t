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

my $base = '/feature/region/homo_sapiens';

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
  }, qr/wibble genes not available/, 'Checking for internal warnings when bad DB type given');
}

#Inspect the first feature
{
  my $region = '6:1078245-1108340';
  my $json = json_GET("$base/$region?feature=gene;feature=transcript;feature=cds;feature=exon", 'Gene models');
  is(scalar(@{$json}), 7, '7 features representing gene models');
  
  my ($gene) = grep { $_->{feature_type} eq 'gene' } @{$json};
  eq_or_diff_data($gene, {
    ID => 'ENSG00000176515',
    biotype => 'protein_coding',
    description => 'Uncharacterized protein; cDNA FLJ34594 fis, clone KIDNE2009109  [Source:UniProtKB/TrEMBL;Acc:Q8NAX6]',
    end => 1105181,
    external_name => 'AL033381.1',
    feature_type => 'gene',
    logic_name => 'ensembl',
    seq_region_name => '6',
    start => 1080164,
    strand => 1
  }, 'Checking structure of gene model as expected');
  
  my ($transcript) = grep { $_->{feature_type} eq 'transcript' } @{$json};
  is($transcript->{Parent}, $gene->{ID}, 'Transcript parent is previous gene');
  
  my ($cds) = sort { $a->{start} <=> $b->{start} } grep { $_->{feature_type} eq 'cds'} @{$json};
  is($cds->{ID}, 'ENSP00000320396', 'CDS ID is the protein identifier');
  is($cds->{Parent}, $transcript->{ID}, 'CDS parent is the previous transcript');
  is($cds->{start}, 1101508, 'First CDS starts at first coding point in the second exon');
  is($cds->{end}, 1101531, 'First CDS ends at the second exon');
}

#Query variation DB
{
  my $region = '6:1000000-1003000';
  my $expected_count = 2;
  my $json = json_GET("$base/$region?feature=variation", 'Fetching variations at '.$region);
  is(scalar(@{$json}), $expected_count, 'Expected variations at '.$region);
  eq_or_diff_data($json->[0],{
    start => 1001893,
    end => 1001893,
    strand => 1,
    ID => 'tmp__',
    consequence_type => 'intergenic_variant',
    feature_type => 'variation',
    seq_region_name => '6',
    alt_alleles => [ qw/T -/]
  }, 'Checking one variation format');
  
  my $somatic_json = json_GET("$base/$region?feature=somatic_variation", 'Fetching somatic variations at '.$region);
  is(scalar(@{$somatic_json}), 1, 'Expected somatic variations at '.$region);
  
  #SO:0001650 inframe_variant (but the original term does not work)
  is_json_GET("$base/$region?feature=variation;so_term=inframe_variant", [], 'SO term querying');
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
    end => 1000776,
    strand => 0, # YES DON'T CHANGE THIS; THEY DO NOT HAVE A STRAND
    ID => 'dust',
    seq_region_name => '6',
    feature_type => 'repeat',
  }, 'Checking one repeat');
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
  
  my $gff_line = q{6	EnsEMBL	protein_coding_gene	1080164	1105181	.	+	.	ID=ENSG00000176515;logic_name=ensembl;external_name=AL033381.1;description=Uncharacterized protein%3B cDNA FLJ34594 fis%2C clone KIDNE2009109  [Source:UniProtKB/TrEMBL%3BAcc:Q8NAX6];biotype=protein_coding;};
  is($lines[0], $gff_line, 'Expected output line from GFF');
}

sub filter_gff {
  my ($gff) = @_;
  return unless $gff;
  return grep { $_ !~ /^#/ && $_ ne q{} } split(/\n/, $gff);
}

done_testing();
