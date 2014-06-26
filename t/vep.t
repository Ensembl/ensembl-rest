# Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http=>//www.apache.org/licenses/LICENSE-2.0
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

my $vep_get = '/vep/homo_sapiens/region/7:86442404-86442404:1/G?content-type=application/json';

# Test vep/region
my $json = json_GET($vep_get,'GET a VEP region');
eq_or_diff($json, 
  { data => [
    {"Consequence" => "intron_variant",
     "GMAF" => "C:0.0399",
     "STRAND" => 1,
     "SYMBOL" => "GRM3",
     "SYMBOL_SOURCE" => "HGNC",
     "Feature_type" => "Transcript",
     "Uploaded_variation" => "temp",
     "Existing_variation" => "rs2299222",
     "Allele" => "G",
     "Gene" => "ENSG00000198822",
     "CDS_position" => "-",
     "cDNA_position" => "-",
     "Protein_position" => "-",
     "Amino_acids" => undef,
     "Feature" => "ENST00000536043",
     "Codons" => undef,
     "Location" => "7:86442404"
    },
    {"Consequence" => "intron_variant",
     "GMAF" => "C:0.0399",
     "STRAND" => 1,
     "SYMBOL" => "GRM3",
     "SYMBOL_SOURCE" => "HGNC",
     "Uploaded_variation" => "temp",
     "Existing_variation" => "rs2299222",
     "Allele" => "G",
     "Gene" => "ENSG00000198822",
     "CDS_position" => "-",
     "cDNA_position" => "-",
     "Protein_position" => "-",
     "Amino_acids" => undef,
     "Feature" => "ENST00000439827",
     "Feature_type" => "Transcript",
     "Codons" => undef,
     "Location" => "7:86442404"
     },
     {"Consequence" => "intron_variant",
      "GMAF" => "C:0.0399",
      "STRAND" => 1,
      "SYMBOL" => "GRM3",
      "SYMBOL_SOURCE" => "HGNC",
      "Feature_type" => "Transcript",
      "Uploaded_variation" => "temp",
      "Existing_variation" => "rs2299222",
      "Allele" => "G",
      "Gene" => "ENSG00000198822",
      "CDS_position" => "-",
      "cDNA_position" => "-",
      "Protein_position" => "-",
      "Amino_acids" => undef,
      "Feature" => "ENST00000361669",
      "Codons" => undef,
      "Location" => "7:86442404"
      },
      {"Consequence" => "intron_variant",
       "GMAF" => "C:0.0399",
       "STRAND" => 1,
       "SYMBOL" => "GRM3",
       "SYMBOL_SOURCE" => "HGNC",
       "Feature_type" => "Transcript",
       "Uploaded_variation" => "temp",
       "Existing_variation" => "rs2299222",
       "Allele" => "G",
       "Gene" => "ENSG00000198822",
       "CDS_position" => "-",
       "cDNA_position" => "-",
       "Protein_position" => "-",
       "Amino_acids" => undef,
       "Feature" => "ENST00000546348",
       "Codons" => undef,
       "Location" => "7:86442404"
       },
       {"Consequence" => "intron_variant",
        "GMAF" => "C:0.0399",
        "STRAND" => 1,
        "SYMBOL" => "GRM3",
        "SYMBOL_SOURCE" => "HGNC",
        "Feature_type" => "Transcript",
        "Uploaded_variation" => "temp",
        "Existing_variation" => "rs2299222",
        "Allele" => "G",
        "Gene" => "ENSG00000198822",
        "CDS_position" => "-",
        "cDNA_position" => "-",
        "Protein_position" => "-",
        "Amino_acids" => undef,
        "Feature" => "ENST00000394720",
        "Codons" => undef,
        "Location" => "7:86442404"}
      ]},'Example vep region get message');

my $vep_post = '/vep/homo_sapiens/region';
my $vep_post_body = '{ "variants" : ["7  34381884  var1  C  T  . . .",
                                     "7  86442404  var2  T  C  . . ."]}';

$json = json_POST($vep_post,$vep_post_body,'POST a selection of regions to the VEP');
eq_or_diff($json,{                                                     
  data => [                                           
    {                                                 
      Allele => 'T',                                  
      Amino_acids => undef,                           
      CDS_position => '-',                            
      Codons => undef,                                
      Consequence => 'downstream_gene_variant',       
      Existing_variation => '-',
      "DISTANCE" => 4240,
      "STRAND" => -1,
      "SYMBOL" => "NPSR1-AS1",
      "SYMBOL_SOURCE" => "HGNC",
      Feature => 'ENST00000419766',                   
      Feature_type => 'Transcript',                   
      Gene => 'ENSG00000197085',                      
      Location => '7:34381884',                       
      Protein_position => '-',                        
      Uploaded_variation => 'var1',                   
      cDNA_position => '-'                            
    },                                                
    {                                                 
      Allele => 'C',                                  
      Amino_acids => undef,                           
      CDS_position => '-',                            
      Codons => undef,                                
      Consequence => 'intron_variant',                
      Existing_variation => 'rs2299222',
      GMAF => 'C:0.0399',                    
      STRAND => 1,  
      SYMBOL => 'GRM3',                              
      SYMBOL_SOURCE => 'HGNC',
      Feature => 'ENST00000536043',                   
      Feature_type => 'Transcript',                   
      Gene => 'ENSG00000198822',                      
      Location => '7:86442404',                       
      Protein_position => '-',                        
      Uploaded_variation => 'var2',                   
      cDNA_position => '-'                            
    },                                                
    {                                                 
      Allele => 'C',                                  
      Amino_acids => undef,                           
      CDS_position => '-',                            
      Codons => undef,                                
      Consequence => 'intron_variant',                
      Existing_variation => 'rs2299222',
      GMAF => 'C:0.0399',
      STRAND => 1,
      SYMBOL => 'GRM3',
      SYMBOL_SOURCE => 'HGNC',
      Feature => 'ENST00000439827',                   
      Feature_type => 'Transcript',                   
      Gene => 'ENSG00000198822',                      
      Location => '7:86442404',                       
      Protein_position => '-',                        
      Uploaded_variation => 'var2',                   
      cDNA_position => '-'                            
    },                                                
    {                                                 
      Allele => 'C',                                  
      Amino_acids => undef,                           
      CDS_position => '-',                            
      Codons => undef,                                
      Consequence => 'intron_variant',                
      Existing_variation => 'rs2299222',                      
      GMAF => 'C:0.0399',
      STRAND => 1,
      SYMBOL => 'GRM3',
      SYMBOL_SOURCE => 'HGNC',
      Feature => 'ENST00000361669',                   
      Feature_type => 'Transcript',                   
      Gene => 'ENSG00000198822',                      
      Location => '7:86442404',                       
      Protein_position => '-',                        
      Uploaded_variation => 'var2',                   
      cDNA_position => '-'                            
    },                                                
    {                                                 
      Allele => 'C',                                  
      Amino_acids => undef,                           
      CDS_position => '-',                            
      Codons => undef,                                
      Consequence => 'intron_variant',                
      Existing_variation => 'rs2299222',                      
      GMAF => 'C:0.0399',
      STRAND => 1,
      SYMBOL => 'GRM3',
      SYMBOL_SOURCE => 'HGNC',
      Feature => 'ENST00000546348',                   
      Feature_type => 'Transcript',                   
      Gene => 'ENSG00000198822',                      
      Location => '7:86442404',                       
      Protein_position => '-',                        
      Uploaded_variation => 'var2',                   
      cDNA_position => '-'                            
    },                                                
    {                                                 
      Allele => 'C',                                  
      Amino_acids => undef,                           
      CDS_position => '-',                            
      Codons => undef,                                
      Consequence => 'intron_variant',                
      Existing_variation => 'rs2299222',                      
      GMAF => 'C:0.0399',
      STRAND => 1,
      SYMBOL => 'GRM3',
      SYMBOL_SOURCE => 'HGNC',
      Feature => 'ENST00000394720',                   
      Feature_type => 'Transcript',                   
      Gene => 'ENSG00000198822',                      
      Location => '7:86442404',                       
      Protein_position => '-',                        
      Uploaded_variation => 'var2',                   
      cDNA_position => '-'                            
    }                                                 
  ]                                                   
},'VEP region POST');

# test vep/id
my $vep_id_get = '/vep/homo_sapiens/id/rs186950277?content-type=application/json';
$json = json_GET($vep_id_get,'GET consequences for Variation ID');
eq_or_diff($json, {                                          
  data => [                                
    {                                      
      Allele => 'A',                       
      Consequence => 'intergenic_variant', 
      Existing_variation => 'rs186950277',           
      GMAF => 'A:0.0014',
      Location => '8:60403074',            
      Uploaded_variation => 'rs186950277'  
    },                                     
    {                                      
      Allele => 'T',                       
      Consequence => 'intergenic_variant', 
      Existing_variation => 'rs186950277',           
      GMAF => 'A:0.0014',
      Location => '8:60403074',            
      Uploaded_variation => 'rs186950277'  
    }                                      
  ]                                        
},'VEP id GET');

my $vep_id_post = '/vep/homo_sapiens/id';
my $vep_id_body = '{ "ids" : ["rs186950277", "rs17081232" ]}';
$json = json_POST($vep_id_post,$vep_id_body,'VEP ID list POST');
eq_or_diff($json,{                                         
  data => [                               
    {                                     
      Allele => 'A',                      
      Consequence => 'intergenic_variant',
      Existing_variation => 'rs17081232',          
      GMAF => 'A:0.2443',
      Location => '4:32305409',           
      Uploaded_variation => 'rs17081232'  
    },                                    
    {                                     
      Allele => 'A',                      
      Consequence => 'intergenic_variant',
      Existing_variation => 'rs186950277',          
      GMAF => 'A:0.0014',
      Location => '8:60403074',           
      Uploaded_variation => 'rs186950277' 
    },                                    
    {                                     
      Allele => 'T',                      
      Consequence => 'intergenic_variant',
      Existing_variation => 'rs186950277',
      GMAF => 'A:0.0014',
      Location => '8:60403074',           
      Uploaded_variation => 'rs186950277' 
    }                                     
  ]                                       
},'VEP id POST');


done_testing();
