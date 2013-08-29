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

#get databases
my $multi = Bio::EnsEMBL::Test::MultiTestDB->new( "multi");

Catalyst::Test->import('EnsEMBL::REST');
require EnsEMBL::REST;

#Get methods
#curl 'http://127.0.0.1:3000/compara/info/methods?compara=multi' -H 'Content-type:application/json'
{
	my $json = json_GET("/compara/info/methods?compara=multi", "Get available methods");
	eq_or_diff_data($json, ['BLASTZ_NET', 'TRANSLATED_BLAT_NET','PECAN','EPO','EPO_LOW_COVERAGE','LASTZ_NET','LASTZ_PATCH'], "Get available methods");
}

#Get species_set_groups
#curl 'http://127.0.0.1:3000/compara/info/species_set_groups/EPO?compara=multi' -H 'Content-type:application/json'
{
	my $json = json_GET("/compara/info/species_set_groups/EPO?compara=multi", "Get available species_set_groups for EPO");
	eq_or_diff_data($json, ["birds","fish","mammals","primates"], "Get available species_set_groups for EPO");
}

#No species_set_groups available for BLASTZ_NET in database multi
{
	 action_bad_regex("/compara/info/species_set_groups/BLASTZ_NET?compara=multi", qr/BLASTZ_NET/, "No species_set_groups available for BLASTZ_NET causes an exception");
}

#Get species_set_groups
#curl 'http://127.0.0.1:3000/compara/info/species_set_groups/LASTZ_NET?compara=multi' -H 'Content-type:application/json'
{
	my $json = json_GET("/compara/info/species_set_groups/LASTZ_NET?compara=multi", "Get available species_set_groups for EPO");
	eq_or_diff_data($json, ["cionas"], "Get available species_set_groups for EPO");
}

#Get species_sets
#curl 'http://127.0.0.1:3000/compara/info/species_sets/LASTZ_NET?compara=multi' -H 'Content-type:application/json'
{
	my $json = json_GET("/compara/info/species_sets/LASTZ_NET?compara=multi", "Get available species_sets for LASTZ_NET");
	is (scalar(@{$json}), 43, "number of species_sets");
}

#Get species_sets, default compara
#curl 'http://127.0.0.1:3000/compara/info/species_sets/LASTZ_NET' -H 'Content-type:application/json'
{
	my $json = json_GET("/compara/info/species_sets/LASTZ_NET", "Get available species_sets for LASTZ_NET, default compara");
	is (scalar(@{$json}), 43, "number of species_sets");
}

#Get method_link_species_sets, default compara
#curl 'http://127.0.0.1:3000/compara/info/method_and_species_sets/EPO' -H 'Content-type:application/json'
{
	my $json = json_GET("/compara/info/method_and_species_sets/EPO", "Get available methods and species_sets for EPO, default compara");
	is (scalar(@{$json}), 4, "number of method_link_species_sets");
}
