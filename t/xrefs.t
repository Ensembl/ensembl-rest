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
use Test::Deep;
use Catalyst::Test ();
use Bio::EnsEMBL::Test::MultiTestDB;
use Test::Differences;

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

# Check ontology xrefs
{
  my $go_id = 'GO:0043565';
  my $url = '/xrefs/id/ENSP00000296839?external_db=GO';
  my $json = json_GET($url, 'Retriving GO xrefs');
  my $expected = { 
    db_display_name => 'GO', dbname => 'GO', description => 'sequence-specific DNA binding',
    info_text => 'Generated via main', info_type => 'DEPENDENT',
    linkage_types => [qw/IEA/],
    primary_id => $go_id,
    display_id => $go_id,
    synonyms => [],
    version => '0',
  };
  my ($actual) = grep { $_->{primary_id} eq $go_id } @{$json};
  cmp_deeply($actual, $expected, 'Checking GO Xrefs bring along their linkage types');
}

# Check identity xrefs
{
  my $translation_id = 'ENSP00000320396';
  my $external_id = 'Q8NAX6';
  my $url = '/xrefs/id/'.$translation_id.'?external_db=Uniprot%';
  my $json = json_GET($url, 'Retriving identity xrefs for '.$translation_id);
  my $expected = { 
    db_display_name => 'UniProtKB/TrEMBL', dbname => 'Uniprot/SPTREMBL', description => 'Uncharacterized protein; cDNA FLJ34594 fis, clone KIDNE2009109 ',
    info_text => '', info_type => 'SEQUENCE_MATCH',
    primary_id => $external_id,
    display_id => $external_id.'_HUMAN',
    synonyms => [],
    version => '0',
    evalue => undef, score => 705, cigar_line => '132M',
    ensembl_start => 1, ensembl_end => 132, ensembl_identity => 100,
    xref_start => 1, xref_end => 132, xref_identity => 100,
  };
  my ($actual) = grep { $_->{primary_id} eq $external_id } @{$json};
  cmp_deeply($actual, $expected, 'Checking identity Xrefs bring along their alignment data. Using '.$external_id); 
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
