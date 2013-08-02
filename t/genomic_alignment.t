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

#get databases
my $zebrafinch = Bio::EnsEMBL::Test::MultiTestDB->new("taeniopygia_guttata");
my $chicken = Bio::EnsEMBL::Test::MultiTestDB->new("gallus_gallus");
my $turkey = Bio::EnsEMBL::Test::MultiTestDB->new("meleagris_gallopavo");
my $ancestral = Bio::EnsEMBL::Test::MultiTestDB->new("ancestral_sequences");
my $multi = Bio::EnsEMBL::Test::MultiTestDB->new( "multi" );

Catalyst::Test->import('EnsEMBL::REST');
require EnsEMBL::REST;

#get test data
my $data = get_data();

#default species and region
 my $species = "taeniopygia_guttata";
 my $region = '2:106040000-106041500';

#Wrong method
{
  action_bad_regex("/alignment/block/region/$species/$region?method=wibble", qr/The method 'wibble' is not understood by this service/, "Using unsupported method causes an exception");
}

#Wrong masking
{
  action_bad_regex("/alignment/block/region/$species/$region?mask=wibble", qr/wibble/, "Using unsupported masking type causes an exception");
}

#Wrong overlap
{
  action_bad_regex("/alignment/slice/region/$species/$region?overlaps=wibble", qr/wibble/, "Using unsupported overlap type causes an exception");
}

#Too large a region
{
  my $region = '2:1000000..2000000';
  action_bad_regex("/alignment/block/region/$species/$region?", qr/maximum allowed length/, 'Using a too long a slice causes an exception');
}

#Invalid species_set_group
#curl 'http://127.0.0.1:3000/alignment/block/region/taeniopygia_guttata/2:106040000-106041500?method=EPO;species_set_group=wibble' -H 'Content-type:application/json'
{
 action_bad_regex("/alignment/slice/region/$species/$region?method=EPO;species_set_group=wibble", qr/wibble/, "Using unsupported species_set_group causes an exception");
}

#Invalid species_set
#curl 'http://127.0.0.1:3000/alignment/block/region/taeniopygia_guttata/2:106040000-106041500?method=LASTZ_NET;species_set=gallus_gallus;species_set=wibble' -H 'Content-type:application/json'
{
  action_bad_regex("/alignment/slice/region/$species/$region?method=EPO;species_set=gallus_gallus;species_set=wibble", qr/wibble/, "Using unsupported species_set causes an exception");
}

#Small region EPO, block
#curl 'http://127.0.0.1:3000/alignment/block/region/taeniopygia_guttata/2:106040000-106040050:1?method=EPO;species_set_group=birds' -H 'Content-type:application/json'
{
  my $region = '2:106040050-106040100';

  my $json = json_GET("/alignment/block/region/$species/$region?species_set_group=birds;method=EPO", "EPO alignment, block");
  is (scalar(@{$json}), 1, "number of alignment blocks");
  my $num_alignments = 5;

  is(scalar(@{$json->[0]}), $num_alignments, "number of EPO alignments, block");
  eq_or_diff_data($json->[0][0], $data->{short_EPO}, "First EPO alignment, block");
}

#Small region EPO align_slice, expanded
#curl 'http://127.0.0.1:3000/alignment/slice/region/taeniopygia_guttata/2:106040050-106040100:1?method=EPO;species_set_group=birds;expanded=1' -H 'Content-type:application/json'
{
  my $region = '2:106040050-106040100';

  my $json = json_GET("/alignment/slice/region/$species/$region?method=EPO;species_set_group=birds;expanded=1", "EPO alignment, align_slice, expanded");
  is (scalar(@{$json}), 1, "number of alignment blocks");
  my $num_alignments = 5;

  is($num_alignments, scalar(@{$json->[0]}), "number of EPO alignments, align_slice, expanded");
  eq_or_diff_data($json->[0][0], $data->{short_EPO}, "First EPO alignment, align_slice, expanded");

}

#Small region EPO align_slice, not expanded
#curl 'http://127.0.0.1:3000/alignment/slice/region/taeniopygia_guttata/2:106040050-106040100:1?method=EPO;species_set_group=birds;expanded=0' -H 'Content-type:application/json'
{
  my $region = '2:106040050-106040100';

  my $json = json_GET("/alignment/slice/region/$species/$region?method=EPO;species_set_group=birds;expanded=0", "EPO alignment, align_slice, expanded");
  is (scalar(@{$json}), 1, "number of alignment blocks");
  my $num_alignments = 5;

  is($num_alignments, scalar(@{$json->[0]}), "number of EPO alignments, align_slice, expanded");
  eq_or_diff_data($json->[0][0], $data->{short_EPO_no_gaps}, "First EPO alignment, align_slice, expanded");

}

#Small region, EPO soft masking
#curl 'http://127.0.0.1:3000/alignment/block/region/taeniopygia_guttata/2:106040500-106040550:1?method=EPO;species_set_group=birds;mask=soft' -H 'Content-type:application/json'
{
  my $region = '2:106040500-106040550';

  my $json = json_GET("/alignment/block/region/$species/$region?method=EPO;species_set_group=birds;mask=soft", "EPO alignment, block, soft masking");
  is (scalar(@{$json}), 1, "number of short EPO alignment blocks, soft masking");
  my $num_alignments = 3;

  is($num_alignments, scalar(@{$json->[0]}), "number of EPO alignments, block, soft masking");
  eq_or_diff_data($json->[0][0], $data->{short_EPO_soft}, "First EPO alignment, block, soft masking");

}

#Small region, EPO, slice, hard masking
#curl 'http://127.0.0.1:3000/alignment/block/region/taeniopygia_guttata/2:106040500-106040550:1?method=EPO;species_set_group=birds;mask=hard' -H 'Content-type:application/json'
{
  my $region = '2:106040500-106040550';

  my $json = json_GET("/alignment/block/region/$species/$region?method=EPO;species_set_group=birds;mask=hard", "EPO alignment, block, hard masking");
  is (scalar(@{$json}), 1, "number of EPO alignmens, block, hard masking");
  my $num_alignments = 3;

  is($num_alignments, scalar(@{$json->[0]}), "number of EPO alignments, block, hard masking");
  eq_or_diff_data($json->[0][0], $data->{short_EPO_hard}, "First EPO alignment, block, hard masking");

}

#Small region, EPO, slice,  soft masking
#curl 'http://127.0.0.1:3000/alignment/slice/region/taeniopygia_guttata/2:106040500-106040550:1?method=EPO;species_set_group=birds;mask=soft;expanded=1' -H 'Content-type:application/json'
{
  my $region = '2:106040500-106040550';

  my $json = json_GET("/alignment/slice/region/$species/$region?method=EPO;species_set_group=birds;mask=soft;expanded=1", "EPO alignment, slice, soft masking");
  is (scalar(@{$json}), 1, "number of EPO alignments, slice, soft masking");
  my $num_alignments = 3;

  is($num_alignments, scalar(@{$json->[0]}), "number of EPO alignments, slice, soft masking");
  eq_or_diff_data($json->[0][0], $data->{short_EPO_soft}, "First EPO alignment, slice, soft masking");

}

#Small region, EPO, slice, hard masking
#curl 'http://127.0.0.1:3000/alignment/slice/region/taeniopygia_guttata/2:106040500-106040550:1?method=EPO;species_set_group=birds;mask=hard;expaned=1' -H 'Content-type:application/json'
{
  my $region = '2:106040500-106040550';

  my $json = json_GET("/alignment/slice/region/$species/$region?method=EPO;species_set_group=birds;mask=hard;expanded=1", "EPO alignment, slice, hard masking");
  is (scalar(@{$json}), 1, "number of EPO alignments, slice, hard masking");
  my $num_alignments = 3;

  is($num_alignments, scalar(@{$json->[0]}), "number of EPO alignments, slice, hard masking");
  eq_or_diff_data($json->[0][0], $data->{short_EPO_hard}, "First EPO alignment, slice, hard masking");

}

#EPO, block, restricted species
#curl 'http://127.0.0.1:3000/alignment/block/region/taeniopygia_guttata/2:106040050-106040100:1?method=EPO;species_set_group=birds;display_species_set=gallus_gallus;display_species_set=taeniopygia_guttata' -H 'Content-type:application/json'
{
  my $region = '2:106040050-106040100';

  my $json = json_GET("/alignment/block/region/$species/$region?method=EPO;species_set_group=birds;display_species_set=gallus_gallus;display_species_set=taeniopygia_guttata", "short EPO alignment, block, restricted set");
  is (scalar(@{$json}), 1, "number of alignment blocks, block, restricted set");
  my $num_alignments = 2;

  is(scalar(@{$json->[0]}), $num_alignments, "number of EPO alignments, block, restricted set");
  eq_or_diff_data($json->[0][0], $data->{short_EPO}, "First EPO alignment, block, restricted set");
}

#EPO, slice, restricted species
#curl 'http://127.0.0.1:3000/alignment/slice/region/taeniopygia_guttata/2:106040050-106040100:1?method=EPO;expanded=1;species_set_group=birds;display_species_set=gallus_gallus;display_species_set=taeniopygia_guttata' -H 'Content-type:application/json'
{
  my $region = '2:106040050-106040100';

  my $json = json_GET("/alignment/block/region/$species/$region?method=EPO;species_set_group=birds;expanded=1;display_species_set=gallus_gallus;display_species_set=taeniopygia_guttata", "short EPO alignment, slice, restricted set");
  is (scalar(@{$json}), 1, "number of alignment blocks, slice, restricted set ");
  my $num_alignments = 2;

  is(scalar(@{$json->[0]}), $num_alignments, "number of EPO alignments, slice, restricted set");
  eq_or_diff_data($json->[0][0], $data->{short_EPO}, "First EPO alignment, slice, restricted set");
}


#Pairwise, overlaps=none
#curl 'http://127.0.0.1:3000/alignment/slice/region/taeniopygia_guttata/2:106041430-106041480:1?method=LASTZ_NET;species_set=taeniopygia_guttata;species_set=gallus_gallus;overlaps=none' -H 'Content-type:application/json'
{
	my $region = '2:106041430-106041480';

	my $json = json_GET("/alignment/slice/region/$species/$region?method=LASTZ_NET;species_set=taeniopygia_guttata;species_set=gallus_gallus;overlaps=none", "Pairwise, slice, no overlaps");
	is (scalar(@{$json}), 1, "number of LASTZ_NET alignments, slice, no overlaps");
  	my $num_seqs = 2;

   	is(scalar(@{$json->[0]}), $num_seqs, "number of LASTZ_NET sequences, slice, no overlaps");
        for (my $i = 0; $i < $num_seqs; $i++) {   
	   eq_or_diff_data($json->[0][$i], $data->{LASTZ_NET_no_overlaps}[$i], "Pairwise, slice, no overlaps");
        }
}

#Pairwise, overlaps=all
#curl 'http://127.0.0.1:3000/alignment/slice/region/taeniopygia_guttata/2:106041430-106041480:1?method=LASTZ_NET;species_set=taeniopygia_guttata;species_set=gallus_gallus;overlaps=all' -H 'Content-type:application/json'
{
	my $region = '2:106041430-106041480';

	my $json = json_GET("/alignment/slice/region/$species/$region?method=LASTZ_NET;species_set=taeniopygia_guttata;species_set=gallus_gallus;overlaps=all", "Pairwise, slice, all overlaps");
	is (scalar(@{$json}), 1, "number of LASTZ_NET alignments, slice, all overlaps");
  	my $num_seqs = 3;

   	is(scalar(@{$json->[0]}), $num_seqs, "number of LASTZ_NET sequences, slice, all overlaps");
        for (my $i = 0; $i < $num_seqs; $i++) {   
	   eq_or_diff_data($json->[0][$i], $data->{LASTZ_NET_all_overlaps}[$i], "Pairwise, slice, all overlaps");
        }
}

#Pairwise, overlaps=restrict
#curl 'http://127.0.0.1:3000/alignment/slice/region/taeniopygia_guttata/2:106041430-106041480:1?method=LASTZ_NET;species_set=taeniopygia_guttata;species_set=gallus_gallus;overlaps=restrict' -H 'Content-type:application/json'
{
	my $region = '2:106041430-106041480';

	my $json = json_GET("/alignment/slice/region/$species/$region?method=LASTZ_NET;species_set=taeniopygia_guttata;species_set=gallus_gallus;overlaps=restrict", "Pairwise, slice, all overlaps");
	is (scalar(@{$json}), 1, "number of LASTZ_NET alignments, slice, restrict overlaps");
  	my $num_seqs = 2;

   	is(scalar(@{$json->[0]}), $num_seqs, "number of LASTZ_NET sequences, slice, restrict overlaps");
        for (my $i = 0; $i < $num_seqs; $i++) {   
	   eq_or_diff_data($json->[0][$i], $data->{LASTZ_NET_restrict_overlaps}[$i], "Pairwise, slice, restrict overlaps");
        }
}

#Pairwise, block
#curl 'http://127.0.0.1:3000/alignment/block/region/taeniopygia_guttata/2:106041430-106041480:1?method=LASTZ_NET;species_set=taeniopygia_guttata;species_set=gallus_gallus' -H 'Content-type:application/json'
{
	my $region = '2:106041430-106041480';

	my $json = json_GET("/alignment/block/region/$species/$region?method=LASTZ_NET;species_set=taeniopygia_guttata;species_set=gallus_gallus;overlaps=restrict", "Pairwise, block");

	my $num_blocks = 2;
	is (scalar(@{$json}), $num_blocks, "number of LASTZ_NET alignments, block");
  	my $num_seqs = 2;

   	is(scalar(@{$json->[0]}), $num_seqs, "number of LASTZ_NET sequences, block");
        for (my $i = 0; $i < $num_blocks; $i++) {   
           for (my $j = 0; $j < $num_seqs; $j++) {   
	      eq_or_diff_data($json->[$i][$j], $data->{LASTZ_NET_blocks}[$i][$j], "Pairwise, block");
           }
        }
}

sub get_data {
    my $data;

    $data->{short_EPO} =  {description=>'','end'=>106040100,'seq'=>'TGAACAAA--------GAAATGTCTTATCCCACAGAGAGTACAGACATTATAGAGTTAT','seq_region'=>2,'species'=>'taeniopygia_guttata','start'=>106040050,'strand'=>1};
    $data->{short_EPO_no_gaps} =  {description=>'','end'=>106040100,'seq'=>'TGAACAAAGAAATGTCTTATCCCACAGAGAGTACAGACATTATAGAGTTAT','seq_region'=>2,'species'=>'taeniopygia_guttata','start'=>106040050,'strand'=>1};
    $data->{short_EPO_soft} =  {description=>'','end'=>106040550,'seq'=>'TAGTGG-TGAttttttggttttttGCCTGCTGGCCCTCCTTCTTTGTACTCA','seq_region'=>2,'species'=>'taeniopygia_guttata','start'=>106040500,'strand'=>1};
    $data->{short_EPO_hard} =  {description=>'','end'=>106040550,'seq'=>'TAGTGG-TGANNNNNNNNNNNNNNGCCTGCTGGCCCTCCTTCTTTGTACTCA','seq_region'=>2,'species'=>'taeniopygia_guttata','start'=>106040500,'strand'=>1};

    push @{$data->{LASTZ_NET_no_overlaps}}, {description=>'','end'=>106041480,'seq'=>'ACTCATTCGCATTTATCACAGTTTATAAAATTGCAGTTTACGCTGAATCAC','seq_region'=>2,'species'=>'taeniopygia_guttata','start'=>106041430,'strand'=>1};
    push @{$data->{LASTZ_NET_no_overlaps}}, {description=>'','end'=>100371632,'seq'=>'ACTCATCAGTATTTAACACAGCTTGTGACACTGC.................','seq_region'=>2,'species'=>'gallus_gallus','start'=>100371599,'strand'=>1};

   push @{$data->{LASTZ_NET_all_overlaps}}, {description=>'','end'=>106041480,'seq'=>'ACTCATTCGCATTTATCACAGTTTATAAAATTGCAGTTTACGCTGAATCAC','seq_region'=>2,'species'=>'taeniopygia_guttata','start'=>106041430,'strand'=>1};
    push @{$data->{LASTZ_NET_all_overlaps}}, {description=>'','end'=>100371632,'seq'=>'ACTCATCAGTATTTAACACAGCTTGTGACACTGC-----------------','seq_region'=>2,'species'=>'gallus_gallus','start'=>100371599,'strand'=>1};
   push @{$data->{LASTZ_NET_all_overlaps}}, {description=>'','end'=>809,'seq'=>'ACTCATCAGTATTTAACACAGCTTGTGACACTGCAGATTTTGAT-----AT','seq_region'=>'AADN03027098.1','species'=>'gallus_gallus','start'=>764,'strand'=>1};

   push @{$data->{LASTZ_NET_restrict_overlaps}}, {description=>'','end'=>106041480,'seq'=>'ACTCATTCGCATTTATCACAGTTTATAAAATTGCAGTTTACGCTGAATCAC','seq_region'=>2,'species'=>'taeniopygia_guttata','start'=>106041430,'strand'=>1};
    push @{$data->{LASTZ_NET_restrict_overlaps}}, {description=>'Composite is: chromosome:Galgal4:2:100371599:100371632:1 + scaffold:Galgal4:AADN03027098.1:798:809:1','end'=>51,'seq'=>'ACTCATCAGTATTTAACACAGCTTGTGACACTGCAGATTTTGAT-----AT','seq_region'=>'Composite','species'=>'gallus_gallus','start'=>1,'strand'=>1};

    my ($block1, $block2);
    push @{$block1}, {description=>'',end=>106041463,seq=>'ACTCATTCGCATTTATCACAGTTTATAAAATTGC',seq_region=>'2',species=>'taeniopygia_guttata',start=>106041430,strand=>1};
    push @{$block1}, {description=>'',end=>100371632,seq=>'ACTCATCAGTATTTAACACAGCTTGTGACACTGC',seq_region=>'2',species=>'gallus_gallus',start=>100371599,strand=>1};
    push @{$block2}, {description=>'',end=>106041480,seq=>'ACTCATTCGCATTTATCACAGTTTATAAAATTGCAGTTTACGCTGAATCAC',seq_region=>'2',species=>'taeniopygia_guttata',start=>106041430,strand=>1};
    push @{$block2}, {description=>'',end=>809,seq=>'ACTCATCAGTATTTAACACAGCTTGTGACACTGCAGATTTTGAT-----AT',seq_region=>'AADN03027098.1',species=>'gallus_gallus',start=>764,strand=>1};

   push @{$data->{LASTZ_NET_blocks}}, $block1;
   push @{$data->{LASTZ_NET_blocks}}, $block2;


    return $data;
}

done_testing();
