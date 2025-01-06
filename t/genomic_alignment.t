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
use Bio::EnsEMBL::Test::TestUtils;
use Test::XML::Simple;
use Test::XPath;

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

#Wrong method
{
  action_bad_regex("/alignment/block/region/$species/$region?method=SYNTENY", qr/The method 'SYNTENY' is not used for genome alignments/, "Using non-alignment method causes an exception");
}

#Wrong masking
{
  action_bad_regex("/alignment/block/region/$species/$region?mask=wibble", qr/wibble/, "Using unsupported masking type causes an exception");
}

#Too large a region
{
  my $region = '2:1000000..2000000';
  action_bad_regex("/alignment/block/region/$species/$region?", qr/maximum allowed length/, 'Using a too long a slice causes an exception');
}

#Invalid species_set_group
#curl 'http://127.0.0.1:3000/alignment/region/taeniopygia_guttata/2:106040000-106041500?method=EPO;species_set_group=wibble' -H 'Content-type:application/json'
{
 action_bad_regex("/alignment/region/$species/$region?method=EPO;species_set_group=wibble", qr/wibble/, "Using unsupported species_set_group causes an exception");
}

#Invalid species_set
#curl 'http://127.0.0.1:3000/alignment/region/taeniopygia_guttata/2:106040000-106041500?method=LASTZ_NET;species_set=gallus_gallus;species_set=wibble' -H 'Content-type:application/json'
{
  action_bad_regex("/alignment/region/$species/$region?method=EPO;species_set=gallus_gallus;species_set=wibble", qr/wibble/, "Using unsupported species_set causes an exception");
}

# No alignment on this region
{
  my $region = '2:40000-41500';
  action_bad("/alignment/$species/$region?method=EPO;species_set_group=birds", "no alignment available for this region");
}

#Small region EPO slice, tree, deprecated, json
#curl 'http://127.0.0.1:3000/alignment/slice/region/taeniopygia_guttata/2:106040050-106040100:1?method=EPO;species_set_group=birds' -H 'Content-type:application/json'
{
  my $region = '2:106040050-106040100';

  action_bad("/alignment/slice/region/$species/$region?method=EPO;species_set_group=birds", "Deprecated method: EPO alignment, slice");

  #is (scalar(@{$json}), 1, "number of alignment blocks");
 # my $num_alignments = 5;

  #is($num_alignments, scalar(@{$json->[0]{alignments}}), "number of EPO alignments, align_slice, expanded");
  #eq_or_diff_data($json->[0]{alignments}[0], $data->{short_EPO}, "First EPO alignment, align_slice, expanded");

}

#Small region EPO, block, tree, json
#curl 'http://127.0.0.1:3000/alignment/block/region/taeniopygia_guttata/2:106040050-106040100:1?method=EPO;species_set_group=birds' -H 'Content-type:application/json'
{
  my $region = '2:106040050-106040100';

  my $json = json_GET("/alignment/block/region/$species/$region?species_set_group=birds;method=EPO", "EPO alignment, block");
  is (scalar(@{$json}), 1, "number of alignment blocks");
  my $num_alignments = 5;

  is(scalar(@{$json->[0]{alignments}}), $num_alignments, "number of EPO alignments, block");
  eq_or_diff_data($json->[0]{alignments}[0], $data->{short_EPO}, "First EPO alignment, block");
  eq_or_diff_data($json->[0]{tree}, $data->{short_EPO_tree}, 'Single EPO tree');
}

#Small region EPO, tree, phyloxml
#curl 'http://127.0.0.1:3000/alignment/region/taeniopygia_guttata/2:106040050-106040100:1?method=EPO;species_set_group=birds' -H 'Content-type:text/x-phyloxml+xml'
{
  my $region = '2:106040050-106040100';

  my $phyloxml = phyloxml_GET("/alignment/region/$species/$region?species_set_group=birds;method=EPO", "EPO alignment, block HERE");

  #not sure if this is the best way of doing this but I couldn't figure out how to get all the nodes associated with a particular Scientific node
   my $location = $data->{short_EPO}{seq_region} .":" . $data->{short_EPO}{start} . "-" . $data->{short_EPO}{end};
   my $tx = Test::XPath->new(xml => $phyloxml, xmlns => { x => "http://www.w3.org/2001/XMLSchema-instance", p => "http://www.phyloxml.org"});

   $tx->is('count(//p:clade)', 5,"number of clades");
   $tx->ok('//p:scientific_name="Taeniopygia guttata"', "Scientific name");
   $tx->ok('//p:location="'.$location.'"', "location");
   $tx->ok( '//p:mol_seq="' . $data->{short_EPO}{seq}  .'"', "sequence");  
}

#Small region EPO, tree, aligned, json
#curl 'http://127.0.0.1:3000/alignment/region/taeniopygia_guttata/2:106040050-106040100:1?method=EPO;species_set_group=birds;aligned=1' -H 'Content-type:application/json'
{
  my $region = '2:106040050-106040100';

  my $json = json_GET("/alignment/region/$species/$region?species_set_group=birds;method=EPO;aligned=1", "EPO alignment, block");
  is (scalar(@{$json}), 1, "number of alignment blocks");
  my $num_alignments = 5;

  is(scalar(@{$json->[0]{alignments}}), $num_alignments, "number of EPO alignments, block");
  eq_or_diff_data($json->[0]{alignments}[0], $data->{short_EPO}, "First EPO alignment, block");
  eq_or_diff_data($json->[0]{tree}, $data->{short_EPO_tree}, 'Single EPO tree');
}

#Small region EPO, block, tree, aligned, phyloxml
#curl 'http://127.0.0.1:3000/alignment/region/taeniopygia_guttata/2:106040050-106040100:1?method=EPO;species_set_group=birds;aligned=1' -H 'Content-type:text/x-phyloxml+xml'
{
  my $region = '2:106040050-106040100';

  my $phyloxml = phyloxml_GET("/alignment/region/$species/$region?species_set_group=birds;method=EPO;aligned=1", "EPO alignment HERE");

  #not sure if this is the best way of doing this but I couldn't figure out how to get all the nodes associated with a particular Scientific node
   my $location = $data->{short_EPO}{seq_region} .":" . $data->{short_EPO}{start} . "-" . $data->{short_EPO}{end};
   my $tx = Test::XPath->new(xml => $phyloxml, xmlns => { x => "http://www.w3.org/2001/XMLSchema-instance", p => "http://www.phyloxml.org"});

   $tx->is('count(//p:clade)', 5,"number of clades");
   $tx->ok('//p:scientific_name="Taeniopygia guttata"', "Scientific name");
   $tx->ok('//p:location="'.$location.'"', "location");
   $tx->ok( '//p:mol_seq="' . $data->{short_EPO}{seq}  .'"', "sequence");  

}

#Small region EPO, tree, not aligned, json
#curl 'http://127.0.0.1:3000/alignment/region/taeniopygia_guttata/2:106040050-106040100:1?method=EPO;species_set_group=birds;aligned=0' -H 'Content-type:application/json'
{
  my $region = '2:106040050-106040100';

  my $json = json_GET("/alignment/region/$species/$region?species_set_group=birds;method=EPO;aligned=0", "EPO alignment");
  is (scalar(@{$json}), 1, "number of alignment blocks");
  my $num_alignments = 5;

  is(scalar(@{$json->[0]{alignments}}), $num_alignments, "number of EPO alignments, block");
  eq_or_diff_data($json->[0]{alignments}[0], $data->{short_EPO_no_gaps}, "First EPO alignment, block");
  eq_or_diff_data($json->[0]{tree}, $data->{short_EPO_tree}, 'Single EPO tree');
}

#Small region EPO, tree, not aligned, phyloxml
#curl 'http://127.0.0.1:3000/alignment/region/taeniopygia_guttata/2:106040050-106040100:1?method=EPO;species_set_group=birds;aligned=0' -H 'Content-type:text/x-phyloxml+xml'
{
  my $region = '2:106040050-106040100';

  my $phyloxml = phyloxml_GET("/alignment/region/$species/$region?species_set_group=birds;method=EPO;aligned=0", "EPO alignment, AGAIN");

   my $location = $data->{short_EPO}{seq_region} .":" . $data->{short_EPO}{start} . "-" . $data->{short_EPO}{end};
   my $tx = Test::XPath->new(xml => $phyloxml, xmlns => { x => "http://www.w3.org/2001/XMLSchema-instance", p => "http://www.phyloxml.org"});

   $tx->is('count(//p:clade)', 5,"number of clades");
   $tx->ok('//p:scientific_name="Taeniopygia guttata"', "Scientific name");
   $tx->ok('//p:location="'.$location.'"', "location");
   $tx->ok( '//p:mol_seq="' . $data->{short_EPO_no_gaps}{seq}  .'"', "sequence");  

}

#Small region, EPO soft masking json
#curl 'http://127.0.0.1:3000/alignment/region/taeniopygia_guttata/2:106040500-106040550:1?method=EPO;species_set_group=birds;mask=soft' -H 'Content-type:application/json'
{
  my $region = '2:106040500-106040550';

  my $json = json_GET("/alignment/region/$species/$region?method=EPO;species_set_group=birds;mask=soft", "EPO alignment, soft masking");
  is (scalar(@{$json}), 1, "number of short EPO alignment blocks, soft masking");
  my $num_alignments = 3;

  is($num_alignments, scalar(@{$json->[0]{alignments}}), "number of EPO alignments, soft masking");
  eq_or_diff_data($json->[0]{alignments}[0], $data->{short_EPO_soft}, "First EPO alignment, soft masking");

}

#Small region, EPO soft masking phyloxml
#curl 'http://127.0.0.1:3000/alignment/region/taeniopygia_guttata/2:106040500-106040550:1?method=EPO;species_set_group=birds;mask=soft' -H 'Content-type:text/x-phyloxml+xml'
{
  my $region = '2:106040500-106040550';
  my $num_alignments = 3;
  
  my $phyloxml = phyloxml_GET("/alignment/region/$species/$region?species_set_group=birds;method=EPO;mask=soft", "EPO alignment BROKEN");

   my $location = $data->{short_EPO_soft}{seq_region} .":" . $data->{short_EPO_soft}{start} . "-" . $data->{short_EPO_soft}{end};
   my $tx = Test::XPath->new(xml => $phyloxml, xmlns => { x => "http://www.w3.org/2001/XMLSchema-instance", p => "http://www.phyloxml.org"});
   
   #$phyloxml =~ s/xmlns="http:\/\/www.phyloxml.org"//d;
   # my $tx = Test::XPath->new(xml => $phyloxml);

   $tx->is('count(//p:clade)', $num_alignments,"number of short EPO alignment blocks, soft masking, phyloxml");
   $tx->ok('//p:scientific_name="Taeniopygia guttata"', "First EPO alignment, soft masking, Scientific name");
   $tx->ok('//p:location="'.$location.'"', "First EPO alignment, soft masking, location");
   $tx->ok( '//p:mol_seq="' . $data->{short_EPO_soft}{seq}  .'"', "First EPO alignment, soft masking, sequence");   
}


#Small region, EPO, hard masking
#curl 'http://127.0.0.1:3000/alignment/region/taeniopygia_guttata/2:106040500-106040550:1?method=EPO;species_set_group=birds;mask=hard' -H 'Content-type:application/json'
{
  my $region = '2:106040500-106040550';

  my $json = json_GET("/alignment/region/$species/$region?method=EPO;species_set_group=birds;mask=hard", "EPO alignment,hard masking");
  is (scalar(@{$json}), 1, "number of EPO alignmens, hard masking");
  my $num_alignments = 3;

  is($num_alignments, scalar(@{$json->[0]{alignments}}), "number of EPO alignments, hard masking");
  eq_or_diff_data($json->[0]{alignments}[0], $data->{short_EPO_hard}, "First EPO alignment, hard masking");

}

#Small region, EPO hard masking phyloxml
#curl 'http://127.0.0.1:3000/alignment/region/taeniopygia_guttata/2:106040500-106040550:1?method=EPO;species_set_group=birds;mask=hard' -H 'Content-type:text/x-phyloxml+xml'
{
  my $region = '2:106040500-106040550';
  my $num_alignments = 3;
  
  my $phyloxml = phyloxml_GET("/alignment/region/$species/$region?species_set_group=birds;method=EPO;mask=hard", "EPO alignment, hard masking");

   my $location = $data->{short_EPO_hard}{seq_region} .":" . $data->{short_EPO_hard}{start} . "-" . $data->{short_EPO_hard}{end};

  $phyloxml =~ s/xmlns="http:\/\/www.phyloxml.org"//d;
  my $tx = Test::XPath->new(xml => $phyloxml);
   #my $tx = Test::XPath->new(xml => $phyloxml, xmlns => { x => "http://www.w3.org/2001/XMLSchema-instance", p => "http://www.phyloxml.org"});

   $tx->is('count(//clade)', $num_alignments,"number of short EPO alignment blocks, hard masking, phyloxml");
   $tx->ok('//scientific_name="Taeniopygia guttata"', "First EPO alignment, hard masking, Scientific name");
   $tx->ok('//location="'.$location.'"', "First EPO alignment, hard masking, location");
   $tx->ok( '//mol_seq="' . $data->{short_EPO_hard}{seq}  .'"', "First EPO alignment, hard masking, sequence");   
}

#EPO, restricted species, json
#curl 'http://127.0.0.1:3000/alignment/region/taeniopygia_guttata/2:106040050-106040100:1?method=EPO;species_set_group=birds;display_species_set=gallus_gallus;display_species_set=taeniopygia_guttata' -H 'Content-type:application/json'
{
   use Bio::EnsEMBL::Registry;
   Bio::EnsEMBL::Registry->add_alias("gallus_gallus", "chicken");
   Bio::EnsEMBL::Registry->add_alias("taeniopygia_guttata", "zebrafinch");
   my $region = '2:106040050-106040100';

  my $json = json_GET("/alignment/region/$species/$region?method=EPO;species_set_group=birds;display_species_set=chicken;display_species_set=zebrafinch", "short EPO alignment, restricted set");

  is (scalar(@{$json}), 1, "number of alignment blocks, restricted set");
  my $num_alignments = 3;

  is(scalar(@{$json->[0]{alignments}}), $num_alignments, "number of EPO alignments, restricted set");
  eq_or_diff_data($json->[0]{alignments}[0], $data->{short_EPO}, "First EPO alignment, restricted set");

  action_bad("/alignment/$species/$region?method=EPO;species_set_group=birds;display_species_set=human", "no alignment available for this region");
}

#EPO, restricted species, phyloxml
#curl 'http://127.0.0.1:3000/alignment/region/taeniopygia_guttata/2:106040050-106040100:1?method=EPO;species_set_group=birds;display_species_set=chicken;display_species_set=zebrafinch' -H 'Content-type:text/x-phyloxml+xml'
{
   use Bio::EnsEMBL::Registry;
   Bio::EnsEMBL::Registry->add_alias("gallus_gallus", "chicken");
   Bio::EnsEMBL::Registry->add_alias("taeniopygia_guttata", "zebrafinch");
   my $region = '2:106040050-106040100';
   my $num_alignments = 3;

   my $phyloxml = phyloxml_GET("/alignment/region/$species/$region?species_set_group=birds;method=EPO;display_species_set=chicken;display_species_set=zebrafinch", "EPO alignment, restricted set");

   my $location = $data->{short_EPO}{seq_region} .":" . $data->{short_EPO}{start} . "-" . $data->{short_EPO}{end};
   #$phyloxml =~ s/xmlns="http:\/\/www.phyloxml.org"//d;
   #my $tx = Test::XPath->new(xml => $phyloxml);
   my $tx = Test::XPath->new(xml => $phyloxml, xmlns => { x => "http://www.w3.org/2001/XMLSchema-instance", p => "http://www.phyloxml.org"});

   $tx->is('count(//p:clade)', $num_alignments,"number of short EPO alignment blocks, restricted set, phyloxml");
   $tx->ok('//p:scientific_name="Taeniopygia guttata"', "First EPO alignment, restricted set, Scientific name");
   $tx->ok('//p:location="'.$location.'"', "First EPO alignment, restricted set, location");
   $tx->ok( '//p:mol_seq="' . $data->{short_EPO}{seq}  .'"', "First EPO alignment, restricted set, sequence");   

}

#Small region EPO, tree, no branch lengths json
#curl 'http://127.0.0.1:3000/alignment/region/taeniopygia_guttata/2:106040050-106040100:1?method=EPO;species_set_group=birds;no_branch_lengths=1' -H 'Content-type:application/json'
{
  my $region = '2:106040050-106040100';

  my $json = json_GET("/alignment/region/$species/$region?species_set_group=birds;method=EPO;no_branch_lengths=1", "EPO alignment, block");
  is (scalar(@{$json}), 1, "number of alignment blocks");
  my $num_alignments = 5;

  is(scalar(@{$json->[0]{alignments}}), $num_alignments, "number of EPO alignments, block");
  eq_or_diff_data($json->[0]{alignments}[0], $data->{short_EPO}, "First EPO alignment, block");
  eq_or_diff_data($json->[0]{tree}, $data->{short_EPO_tree_no_branch_lengths}, 'Single EPO tree');
}


#Small region EPO, tree, no branch lengths phyloxml
#curl 'http://127.0.0.1:3000/alignment/region/taeniopygia_guttata/2:106040050-106040100:1?method=EPO;species_set_group=birds;no_branch_lengths=1' -H 'Content-type:text/x-phyloxml+xml'
{
  my $region = '2:106040050-106040100';
  my $num_alignments = 5;

  my $phyloxml = phyloxml_GET("/alignment/region/$species/$region?species_set_group=birds;method=EPO;no_branch_lengths=1", "EPO alignment, block HERE");

  #not sure if this is the best way of doing this but I couldn't figure out how to get all the nodes associated with a particular Scientific node
   my $location = $data->{short_EPO}{seq_region} .":" . $data->{short_EPO}{start} . "-" . $data->{short_EPO}{end};
   my $tx = Test::XPath->new(xml => $phyloxml, xmlns => { x => "http://www.w3.org/2001/XMLSchema-instance", p => "http://www.phyloxml.org"});

   $tx->is('count(//p:clade)', $num_alignments,"number of clades");
   $tx->is('count(//p:clade[@branch_length])', 0, "No branch length set");
   $tx->ok('//p:scientific_name="Taeniopygia guttata"', "First EPO alignment, no branch length, Scientific name");
   $tx->ok('//p:location="'.$location.'"', "First EPO alignment, no branch length, location");
   $tx->ok( '//p:mol_seq="' . $data->{short_EPO}{seq}  .'"', "First EPO alignment, no branch length, sequence");  
}

#Small region EPO, tree, branch lengths json
#curl 'http://127.0.0.1:3000/alignment/region/taeniopygia_guttata/2:106040050-106040100:1?method=EPO;species_set_group=birds;no_branch_lengths=0' -H 'Content-type:application/json'
{
  my $region = '2:106040050-106040100';

  my $json = json_GET("/alignment/region/$species/$region?species_set_group=birds;method=EPO;no_branch_lengths=0", "EPO alignment, block");
  is (scalar(@{$json}), 1, "number of alignment blocks");
  my $num_alignments = 5;

  is(scalar(@{$json->[0]{alignments}}), $num_alignments, "number of EPO alignments, block");
  eq_or_diff_data($json->[0]{alignments}[0], $data->{short_EPO}, "First EPO alignment, block");
  eq_or_diff_data($json->[0]{tree}, $data->{short_EPO_tree}, 'Single EPO tree');
}

#Small region EPO, tree, branch lengths phyloxml
#curl 'http://127.0.0.1:3000/alignment/region/taeniopygia_guttata/2:106040050-106040100:1?method=EPO;species_set_group=birds;no_branch_lengths=0' -H 'Content-type:text/x-phyloxml+xml'
{
  my $region = '2:106040050-106040100';
  my $num_alignments = 5;

  my $phyloxml = phyloxml_GET("/alignment/region/$species/$region?species_set_group=birds;method=EPO;no_branch_lengths=0", "EPO alignment, block HERE");

  #not sure if this is the best way of doing this but I couldn't figure out how to get all the nodes associated with a particular Scientific node
   my $location = $data->{short_EPO}{seq_region} .":" . $data->{short_EPO}{start} . "-" . $data->{short_EPO}{end};
   my $tx = Test::XPath->new(xml => $phyloxml, xmlns => { x => "http://www.w3.org/2001/XMLSchema-instance", p => "http://www.phyloxml.org"});

   $tx->is('count(//p:clade)', $num_alignments,"number of clades");
   $tx->is('count(//p:clade[@branch_length])', $num_alignments, "Branch length set");
   $tx->ok('//p:scientific_name="Taeniopygia guttata"', "First EPO alignment, branch length, Scientific name");
   $tx->ok('//p:location="'.$location.'"', "First EPO alignment, branch length, location");
   $tx->ok( '//p:mol_seq="' . $data->{short_EPO}{seq}  .'"', "First EPO alignment, branch length, sequence");  
}

#Small region EPO, tree, no compact json (no afffect for EPO)
#curl 'http://127.0.0.1:3000/alignment/region/taeniopygia_guttata/2:106040050-106040100:1?method=EPO;species_set_group=birds;compact=0' -H 'Content-type:application/json'
{
  my $region = '2:106040050-106040100';

  my $json = json_GET("/alignment/region/$species/$region?species_set_group=birds;method=EPO;compact=0", "EPO alignment, block");
  is (scalar(@{$json}), 1, "number of alignment blocks");
  my $num_alignments = 5;

  is(scalar(@{$json->[0]{alignments}}), $num_alignments, "number of EPO alignments, block");
  eq_or_diff_data($json->[0]{alignments}[0], $data->{short_EPO}, "First EPO alignment, block");
  eq_or_diff_data($json->[0]{tree}, $data->{short_EPO_tree}, 'Single EPO tree');
}

#Small region EPO, tree, branch lengths phyloxml
#curl 'http://127.0.0.1:3000/alignment/region/taeniopygia_guttata/2:106040050-106040100:1?method=EPO;species_set_group=birds;compact=0' -H 'Content-type:text/x-phyloxml+xml'
{
  my $region = '2:106040050-106040100';
  my $num_alignments = 5;

  my $phyloxml = phyloxml_GET("/alignment/region/$species/$region?species_set_group=birds;method=EPO;compact=0", "EPO alignment, block HERE");

  #not sure if this is the best way of doing this but I couldn't figure out how to get all the nodes associated with a particular Scientific node
   my $location = $data->{short_EPO}{seq_region} .":" . $data->{short_EPO}{start} . "-" . $data->{short_EPO}{end};
   my $tx = Test::XPath->new(xml => $phyloxml, xmlns => { x => "http://www.w3.org/2001/XMLSchema-instance", p => "http://www.phyloxml.org"});

   $tx->is('count(//p:clade)', $num_alignments,"number of clades");
   $tx->is('count(//p:clade[@branch_length])', $num_alignments, "Branch length set");
   $tx->ok('//p:scientific_name="Taeniopygia guttata"', "First EPO alignment, branch length, Scientific name");
   $tx->ok('//p:location="'.$location.'"', "First EPO alignment, branch length, location");
   $tx->ok( '//p:mol_seq="' . $data->{short_EPO}{seq}  .'"', "First EPO alignment, branch length, sequence");  
}

#EPO, large block, multiple trees
#curl 'http://127.0.0.1:3000/alignment/region/taeniopygia_guttata/2:106040050-106041500:1?method=EPO;species_set_group=birds' -H 'Content-type:application/json'
{
  my $region = '2:106040050-106041500';
  my $number_of_alignment_blocks = 2;   

  my $json = json_GET("/alignment/region/$species/$region?method=EPO;species_set_group=birds", "large EPO alignment, multiple trees");
  is (scalar(@{$json}), $number_of_alignment_blocks, "number of alignment blocks, large block, multiple trees");

  my @trees = sort map {$_->{tree}} @$json;
  eq_or_diff_data(\@trees, $data->{large_EPO_tree}, "Large EPO tree");
}

#EPO, large block, multiple trees
#curl 'http://127.0.0.1:3000/alignment/region/taeniopygia_guttata/2:106040000-106041500:1?method=EPO;species_set_group=birds' -H 'Content-type:text/x-phyloxml'
{
  my $region = '2:106040050-106041500';
  my $number_of_alignment_blocks = 2;   
 
   my $phyloxml = phyloxml_GET("/alignment/region/$species/$region?species_set_group=birds;method=EPO;aligned=1", "large EPO alignment, multiple trees");
     $phyloxml =~ s/xmlns="http:\/\/www.phyloxml.org"//d;
     my $tx = Test::XPath->new(xml => $phyloxml);

     #my $tx = Test::XPath->new(xml => $phyloxml, xmlns => { x => "http://www.w3.org/2001/XMLSchema-instance", p => "http://www.phyloxml.org"});

    $tx->is('count(//phylogeny)', $number_of_alignment_blocks,"number of  LASTZ_NET blocks, phyloxml");

}


#Pairwise, block
#curl 'http://127.0.0.1:3000/alignment/region/taeniopygia_guttata/2:106041430-106041480:1?method=LASTZ_NET;species_set=taeniopygia_guttata;species_set=gallus_gallus' -H 'Content-type:application/json'
{
	my $region = '2:106041430-106041480';

	my $json = json_GET("/alignment/region/$species/$region?method=LASTZ_NET;species_set=taeniopygia_guttata;species_set=gallus_gallus", "Pairwise, multiple blocks");

	my $num_blocks = 2;
	is (scalar(@{$json}), $num_blocks, "number of LASTZ_NET alignments, block");
  	my $num_seqs = 2;

   	is(scalar(@{$json->[0]{alignments}}), $num_seqs, "number of LASTZ_NET sequences, block");
	my $found = 0;
	#Need to loop round each seq since they may be stored in a different order
        for (my $i = 0; $i < $num_blocks; $i++) {   
           for (my $j = 0; $j < $num_seqs; $j++) {   
	        for (my $k = 0; $k < $num_seqs; $k++) {   
	        #eq_or_diff_data($json->[$i]{alignments}[$j], $data->{LASTZ_NET_blocks}[$i][$j], "Pairwise, block");
	         if ($json->[$i]{alignments}[$k]->{end} eq $data->{LASTZ_NET_blocks}[$i][$j]->{end} &&
		     $json->[$i]{alignments}[$k]->{start} eq $data->{LASTZ_NET_blocks}[$i][$j]->{start} &&
		     $json->[$i]{alignments}[$k]->{seq} eq $data->{LASTZ_NET_blocks}[$i][$j]->{seq} &&
		     $json->[$i]{alignments}[$k]->{seq_region} eq $data->{LASTZ_NET_blocks}[$i][$j]->{seq_region}) {
	            $found++;
                 }
              }	      
           }
        }
	is($found, 4, "LASTZ_NET block");
}

#Pairwise, block
#curl 'http://127.0.0.1:3000/alignment/region/taeniopygia_guttata/2:106041430-106041480:1?method=LASTZ_NET;species_set=taeniopygia_guttata;species_set=gallus_gallus' -H 'Content-type:text/x-phyloxml+xml'
{
	my $region = '2:106041430-106041480';
	my $num_blocks = 2;
	my $num_seqs = 2;

	my $phyloxml = phyloxml_GET("/alignment/region/$species/$region?method=LASTZ_NET;aligned=1;species_set=taeniopygia_guttata;species_set=gallus_gallus", "Pairwise, multiple blocks");
        $phyloxml =~ s/xmlns="http:\/\/www.phyloxml.org"//d;

       my $tx = Test::XPath->new(xml => $phyloxml);

       $tx->is('count(//phylogeny)', $num_blocks,"number of  LASTZ_NET blocks, phyloxml");

	#Loop round the blocks and sequences
        for (my $i = 0; $i < $num_blocks; $i++) {   
           for (my $j = 0; $j < $num_seqs; $j++) {   
	        for (my $k = 0; $k < $num_seqs; $k++) {   
		   my $location = $data->{LASTZ_NET_blocks}[$i][$j]->{seq_region} .":" . $data->{LASTZ_NET_blocks}[$i][$j]->{start} . "-" . $data->{LASTZ_NET_blocks}[$i][$j]->{end};
		   my $species  = ucfirst($data->{LASTZ_NET_blocks}[$i][$j]->{species});
		   $species =~ s/_/ /g;

   		   $tx->ok('//location="'.$location.'"', "LASTZ_NET blocks, phyloxml location");
		   $tx->ok( '//mol_seq="' . $data->{LASTZ_NET_blocks}[$i][$j]->{seq}  .'"', "LASTZ_NET blocks, sequence");   
		   $tx->ok('//scientific_name="' . $species  .'"' , "LASTZ_NET blocks, Scientific name");
		}	      
           }
       }
}

sub get_data {
    my $data;

    $data->{short_EPO} =  {description=>'','end'=>106040100,'seq'=>'TGAACAAA--------GAAATGTCTTATCCCACAGAGAGTACAGACATTATAGAGTTAT','seq_region'=>2,'species'=>'taeniopygia_guttata','start'=>106040050,'strand'=>1};
    $data->{short_EPO_tree} = '(taeniopygia_guttata_2_106040050_106040100[+]:0.1715,(gallus_gallus_2_100370256_100370312[+]:0.0414,meleagris_gallopavo_3_49885207_49885257[+]:0.0414)Ggal-Mgal[2]:0.1242)Ggal-Mgal-Tgut[3];';

    $data->{short_EPO_tree_no_branch_lengths} = '(taeniopygia_guttata_2_106040050_106040100[+],(gallus_gallus_2_100370256_100370312[+],meleagris_gallopavo_3_49885207_49885257[+]));';

    push @{$data->{large_EPO_tree}}, '(taeniopygia_guttata_2_106040050_106040400[+]:0.1715,(gallus_gallus_2_100370256_100370612[+]:0.0414,meleagris_gallopavo_3_49885207_49885557[+]:0.0414)Ggal-Mgal[2]:0.1242)Ggal-Mgal-Tgut[3];';
    push @{$data->{large_EPO_tree}}, '(taeniopygia_guttata_2_106040401_106041500[+]:0.1715,meleagris_gallopavo_3_49885558_49886610[+]:0.1656)Mgal-Tgut[2];';

    $data->{short_EPO_no_gaps} =  {description=>'','end'=>106040100,'seq'=>'TGAACAAAGAAATGTCTTATCCCACAGAGAGTACAGACATTATAGAGTTAT','seq_region'=>2,'species'=>'taeniopygia_guttata','start'=>106040050,'strand'=>1};
    $data->{short_EPO_soft} =  {description=>'','end'=>106040550,'seq'=>'TAGTGG-TGAttttttggttttttGCCTGCTGGCCCTCCTTCTTTGTACTCA','seq_region'=>2,'species'=>'taeniopygia_guttata','start'=>106040500,'strand'=>1};
    $data->{short_EPO_hard} =  {description=>'','end'=>106040550,'seq'=>'TAGTGG-TGANNNNNNNNNNNNNNGCCTGCTGGCCCTCCTTCTTTGTACTCA','seq_region'=>2,'species'=>'taeniopygia_guttata','start'=>106040500,'strand'=>1};

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
