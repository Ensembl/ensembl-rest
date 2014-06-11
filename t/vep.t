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


my $vep_get = '/vep/human/region/7:86442404-86442404:1/G?content-type=application/json';

# Test vep/region
my $json = json_GET($vep_get,'GET a VEP region');
eq_or_diff($json, 
  { data => [
    {"Consequence" => "intron_variant",
     "Extra" => {"ENSP" => "ENSP00000441407",
                 "STRAND" => 1,
                 "HGVSc" => "ENST00000536043.1:c.941-25751N>G",
                 "INTRON" => "2/4"},
     "Feature_type" => "Transcript",
     "Uploaded_variation" => "temp",
     "Existing_variation" => "-",
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
     "Extra" => {"ENSP" => "ENSP00000398767",
                 "STRAND" => 1,
                 "HGVSc" => "ENST00000439827.1:c.1324+25972N>G",
                 "INTRON" => "3/4"},
     "Feature_type" => "Transcript",
     "Uploaded_variation" => "temp",
     "Existing_variation" => "-",
     "Allele" => "G",
     "Gene" => "ENSG00000198822",
     "CDS_position" => "-",
     "cDNA_position" => "-",
     "Protein_position" => "-",
     "Amino_acids" => undef,
     "Feature" => "ENST00000439827",
     "Codons" => undef,
     "Location" => "7:86442404"
     },
     {"Consequence" => "intron_variant",
      "Extra" => {"ENSP" => "ENSP00000355316",
                  "STRAND" => 1,
                  "HGVSc" => "ENST00000361669.2:c.1325-25751N>G",
                  "INTRON" => "3/5",
                  "CANONICAL" => "YES",
                  "CCDS" => "CCDS5600.1"},
      "Feature_type" => "Transcript",
      "Uploaded_variation" => "temp",
      "Existing_variation" => "-",
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
       "Extra" => {"ENSP" => "ENSP00000444064",
                   "STRAND" => 1,
                   "HGVSc" => "ENST00000546348.1:c.101-25751N>G",
                   "INTRON" => "1/3"},
       "Feature_type" => "Transcript",
       "Uploaded_variation" => "temp",
       "Existing_variation" => "-",
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
        "Extra" => {"ENSP" => "ENSP00000378209",
                    "STRAND" => 1,
                    "HGVSc" => "ENST00000394720.2:c.1318+25972N>G",
                    "INTRON" => "3/4"},
        "Feature_type" => "Transcript",
        "Uploaded_variation" => "temp",
        "Existing_variation" => "-",
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

my $vep_post = '/vep/human/region';
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
      Extra => {                                      
        CANONICAL => 'YES',                           
        DISTANCE => 4240,                             
        STRAND => -1                                  
      },                                              
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
      Existing_variation => '-',                      
      Extra => {                                      
        ENSP => 'ENSP00000441407',                    
        HGVSc => 'ENST00000536043.1:c.941-25751T>C',  
        INTRON => '2/4',                              
        STRAND => 1                                   
      },                                              
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
      Existing_variation => '-',                      
      Extra => {                                      
        ENSP => 'ENSP00000398767',                    
        HGVSc => 'ENST00000439827.1:c.1324+25972T>C', 
        INTRON => '3/4',                              
        STRAND => 1                                   
      },                                              
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
      Existing_variation => '-',                      
      Extra => {                                      
        CANONICAL => 'YES',                           
        CCDS => 'CCDS5600.1',                         
        ENSP => 'ENSP00000355316',                    
        HGVSc => 'ENST00000361669.2:c.1325-25751T>C', 
        INTRON => '3/5',                              
        STRAND => 1                                   
      },                                              
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
      Existing_variation => '-',                      
      Extra => {                                      
        ENSP => 'ENSP00000444064',                    
        HGVSc => 'ENST00000546348.1:c.101-25751T>C',  
        INTRON => '1/3',                              
        STRAND => 1                                   
      },                                              
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
      Existing_variation => '-',                      
      Extra => {                                      
        ENSP => 'ENSP00000378209',                    
        HGVSc => 'ENST00000394720.2:c.1318+25972T>C', 
        INTRON => '3/4',                              
        STRAND => 1                                   
      },                                              
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
my $vep_id_get = '/vep/human/id/rs186950277?content-type=application/json';
$json = json_GET($vep_id_get,'GET consequences for Variation ID');
eq_or_diff($json, {                                          
  data => [                                
    {                                      
      Allele => 'A',                       
      Consequence => 'intergenic_variant', 
      Existing_variation => '-',           
      Extra => {},                         
      Location => '8:60403074',            
      Uploaded_variation => 'rs186950277'  
    },                                     
    {                                      
      Allele => 'T',                       
      Consequence => 'intergenic_variant', 
      Existing_variation => '-',           
      Extra => {},                         
      Location => '8:60403074',            
      Uploaded_variation => 'rs186950277'  
    }                                      
  ]                                        
},'VEP id GET');

my $vep_id_post = '/vep/human/id';
my $vep_id_body = '{ "ids" : ["rs186950277", "rs17081232" ]}';
$json = json_POST($vep_id_post,$vep_id_body,'VEP ID list POST');
eq_or_diff($json,{                                         
  data => [                               
    {                                     
      Allele => 'A',                      
      Consequence => 'intergenic_variant',
      Existing_variation => '-',          
      Extra => {},                        
      Location => '4:32305409',           
      Uploaded_variation => 'rs17081232'  
    },                                    
    {                                     
      Allele => 'A',                      
      Consequence => 'intergenic_variant',
      Existing_variation => '-',          
      Extra => {},                        
      Location => '8:60403074',           
      Uploaded_variation => 'rs186950277' 
    },                                    
    {                                     
      Allele => 'T',                      
      Consequence => 'intergenic_variant',
      Existing_variation => '-',          
      Extra => {},                        
      Location => '8:60403074',           
      Uploaded_variation => 'rs186950277' 
    }                                     
  ]                                       
},'VEP id POST');


done_testing();