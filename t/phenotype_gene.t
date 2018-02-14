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

use JSON;
use Test::More;
use Test::Differences;
use Catalyst::Test();
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');
my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('multi');
Catalyst::Test->import('EnsEMBL::REST');


my $base = '/phenotype/gene/homo_sapiens';
my $gene_name='FOXF2'; 


#Null based queries
{
  my $bad_get = '/phenotype/gene';
  action_bad($bad_get, 'Species and gene are required for this endpoint.');

  $bad_get = '/phenotype/gene//';
  action_bad($bad_get, 'Species and gene are required for this endpoint.');
 }

#Bad parameters
{
  my $bad_get = '/phenotype/gene/speciesX/';
  action_bad($bad_get, 'Species speciesX not found.');

  $bad_get = '/phenotype/gene/speciesX/speciesX';
  action_bad($bad_get, 'Species speciesX not found.');


  $bad_get = '/phenotype/gene/speciesX/HNF1A';
  action_bad_regex($bad_get, qr/speciesX/, 'Can not find internal name for species speciesX.');

  my $gene_name = 'gene123H';
  my $msg = "Gene gene123H not found.";
  action_bad_regex("$base/$gene_name", qr/gene123H/, $msg);
}


#Get Gene phenotype features given gene Ensembl identifier
{
  my $gene = "ENSG00000137273";
  my $expected = 2;

  my $expected_data = [
          {
            Gene => "ENSG00000137273",
	    attributes => {
	      external_reference => 'PMID:8626802'  
	    },
	    description => 'positive regulation of transcription from RNA polymerase II promoter',
	    location => '6:1312675-1314992',
	    source => 'GOA'
            },
	  {
	    Gene => "ENSG00000137273",
	    attributes => {
	      external_reference => 'PMID:8626802'  
	    },
	    description => 'soft palate development',
	    location => '6:1312675-1314992',
	    source => 'GOA' 
          }
        ];
	
  my $json = json_GET("$base/$gene", 'Gene with 2 phenotype features associated from GOAs ');
  cmp_ok(scalar(@{$json}), "==", $expected, 'Gene with 2 phenotype associations found');
  eq_or_diff($json, $expected_data, "Checking the result content from the phenotype/gene REST call");
}

#Get Gene phenotype features given gene name
{
  my $expected = 2;

  my $expected_data = [
          {
            Gene => "ENSG00000137273",
	    attributes => {
	      external_reference => 'PMID:8626802'  
	    },
	    description => 'positive regulation of transcription from RNA polymerase II promoter',
	    location => '6:1312675-1314992',
	    source => 'GOA'
            },
	  {
	    Gene => "ENSG00000137273",
	    attributes => {
	      external_reference => 'PMID:8626802'  
	    },
	    description => 'soft palate development',
	    location => '6:1312675-1314992',
	    source => 'GOA' 
          }
        ];
	
  my $json = json_GET("$base/$gene_name", 'Gene with 2 phenotype features associated from GOAs ');
  cmp_ok(scalar(@{$json}),"==", $expected, 'Gene with 2 phenotype associations found');
  eq_or_diff($json, $expected_data, "Checking the result content from the phenotype/gene REST call");
}


#Get Variation phenotype features associated with gene
{
  my $expected = 3;

  my $expected_data = [
           {
	    Gene => 'ENSG00000137273',
            attributes => {                        
              external_reference => 'PMID:8626802'
            },                                                       
            description => 'positive regulation of transcription from RNA polymerase II promoter',
            location => '6:1312675-1314992',  
            source => 'GOA'                  
       	  },  
          {                                                                                
	    Gene => 'ENSG00000137273',
            attributes => {                        
              external_reference => 'PMID:8626802'
            },                                                                       
            description => 'soft palate development',                                       
            location => '6:1312675-1314992',                                                 
            source => 'GOA'                                                               
          },       
	  {
            Variation => 'rs2299222',
	    attributes => {
	      associated_gene => 'YES1,FOXF2',
	      external_reference => 'pubmed/17122850'
	    },
	    description => 'ACHONDROPLASIA',
	    location => '7:86442404-86442404',
	    source => 'dbSNP'
          }
        ];
	
  my $json = json_GET("$base/$gene_name?include_associated=1", 'Gene with 1 phenotype feature associated with a variant');
  cmp_ok(scalar(@{$json}),"==", $expected, 'Gene with 1 phenotype association with variant found');
  eq_or_diff($json, $expected_data, "Checking the result content from the phenotype/gene REST call");
}


#Get Gene phenotype features overlapping (eg. large structural variants)
{
  my $expected = 3;

  my $expected_data = [
          {
	    Gene => 'ENSG00000137273',
            attributes => {                        
              external_reference => 'PMID:8626802'
            },                                                       
            description => 'positive regulation of transcription from RNA polymerase II promoter',
            location => '6:1312675-1314992',  
            source => 'GOA'                  
       	  },  
          {                                                                                
	    Gene => 'ENSG00000137273',
            attributes => {                        
              external_reference => 'PMID:8626802'
            },                                                                       
            description => 'soft palate development',                                       
            location => '6:1312675-1314992',                                                 
            source => 'GOA'                                                               
          },
	  {
	    StructuralVariation => 'esv1234',
	    description => 'COSMIC:tumour_site:skin',
	    location => '6:1312670-1390070',
	    source => 'DGVa'
	  }
        ];
	
  my $json = json_GET("$base/$gene_name?include_overlap=1", 'Gene with 3 phenotype feature overlap');
  cmp_ok(scalar(@{$json}), "==", $expected, 'Gene with 3 phenotype feature overlaps');
  eq_or_diff($json, $expected_data, "Checking the result content from the phenotype/gene REST call");
}

done_testing();
