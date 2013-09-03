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
use Catalyst::Test ();
use Bio::EnsEMBL::Test::MultiTestDB;

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new();
Catalyst::Test->import('EnsEMBL::REST');

my $UPI = 'UPI0000073BC4';

# Ensembl ID based lookup
{
  my $json = json_GET('/xrefs/id/ENSG00000176515', 'Retriving Gene xrefs'); 
  is(scalar(@{$json}), 2, 'Have two xrefs');
  
  is_deeply(
    [sort map { $_->{dbname} } @{$json}], 
    [qw/ArrayExpress Clone_based_ensembl_gene/], 
    'Expecting 2 different database names') or diag explain $json;
  
  is_json_GET('/xrefs/id/ENSG00000176515?external_db=wibble', [], 'Bad dbname means no xrefs');
  
  my $deep_json = json_GET('/xrefs/id/ENSG00000176515?all_levels=1;external_db=Uniparc', 'Retriving UniParc xref from a gene');
  is(scalar(@{$deep_json}), 1, 'Got 1 UniParc reference going for all levels of Xrefs from a gene');
  is($deep_json->[0]->{primary_id}, $UPI, 'Checking UniParc ID');
  
  my $identity_json = json_GET('/xrefs/id/ENSG00000176515?all_levels=1;external_db=UniProt%', 'Retriving UniParc xref from a gene');
  is(scalar(@{$identity_json}), 1, 'Got 1 UniProt reference back');
  is($identity_json->[0]->{cigar_line}, '132M', 'Checking UniProt cigar line');
  
}

#Name based xref lookup
{
  my $json = json_GET("/xrefs/name/homo_sapiens/$UPI", 'Getting UniParc Xref directly with no associations');
  is($json->[0]->{primary_id}, $UPI, 'Checking UniParc ID as retrieved');  
}

#Symbol based lookup of entites
{
  is_json_GET(
    '/xrefs/symbol/homo_sapiens/ENSG00000176515?external_db=ArrayExpress', 
    [{ id => 'ENSG00000176515', type => 'gene' }],
    'ArrayExpress by ensembl Gene ID is only on 1 Gene'
  );
}

#Replicating the Ensembl Genomes way of holding names. UniProt gene names
#are only held via display xref id
{
  $dba->save('core', 'object_xref');
  my $symbol = 'AL033381.1';
  my $sql = 'delete object_xref from object_xref join xref using (xref_id) where xref.dbprimary_acc =?';
  $dba->get_DBAdaptor('core')->dbc()->sql_helper->execute_update(
    -SQL => $sql, -PARAMS => [$symbol]
  );
  is_json_GET(
    '/xrefs/symbol/homo_sapiens/'.$symbol,
    [{"type" => "gene", "id" => "ENSG00000176515"}],
    'Checking we can still find display names if they are not linked to the object as an xref'
  );
  is_json_GET(
    '/xrefs/symbol/homo_sapiens/'.$symbol.'?object_type=transcript',
    [],
    'Asking for a symbol without an object_xref and incorrect object type returns an array'
  );
  $dba->restore('core', 'object_xref');
}

done_testing();
