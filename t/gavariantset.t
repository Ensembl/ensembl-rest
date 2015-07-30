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
use Bio::EnsEMBL::Test::TestUtils;


Catalyst::Test->import('EnsEMBL::REST');

my $base = '/ga4gh/variantsets/search';

my $post_data1 = '{ "pageSize": 2,  "datasetIds":[],"pageToken":"" }';
my $post_data2 = '{ "pageSize": 2,  "datasetIds":[1],"pageToken":"" }';

my $expected_data1 = {                                                
  variantSets => [                                
    {                                             
      datasetId => '1',                           
      id => '20',                                 
      metadata => [                               
     { 
         description => 'MLE Allele Frequency Accounting for LD',                        
         id => 'LDAF',                                                                   
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Average posterior probability from MaCH/Thunder',               
         id => 'AVGPOST',                                                                
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Genotype imputation quality from MaCH/Thunder',                 
         id => 'RSQ',                                                                    
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Per-marker Mutation rate from MaCH/Thunder',                    
         id => 'ERATE',                                                                  
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Per-marker Transition rate from MaCH/Thunder',                  
         id => 'THETA',                                                                  
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Confidence interval around END for imprecise variants',         
         id => 'CIEND',                                                                  
         key => 'INFO',                                                                  
         number => '2',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       {                                                                                 
         description => 'Confidence interval around POS for imprecise variants',         
         id => 'CIPOS',                                                                  
         key => 'INFO',                                                                  
         number => '2',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       {                                                                                 
         description => 'End position of the variant described in this record',          
         id => 'END',                                                                    
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       {                                                                                 
         description => 'Length of base pair identical micro-homology at event breakpoints',
         id => 'HOMLEN',                                                                 
         key => 'INFO',                                                                  
         number => '.',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       {                                                                                 
         description => 'Sequence of base pair identical micro-homology at event breakpoints',
         id => 'HOMSEQ',                                                                 
         key => 'INFO',                                                                  
         number => '.',                                                                  
         type => 'String'                                                                
       },                                                                                
       {                                                                                 
         description => 'Difference in length between REF and ALT alleles',              
         id => 'SVLEN',                                                                  
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       {                                                                                 
         description => 'Type of structural variant',                                    
         id => 'SVTYPE',                                                                 
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'String'                                                                
       },                                                                                
       {                                                                                 
         description => 'Alternate Allele Count',                                        
         id => 'AC',                                                                     
         key => 'INFO',                                                                  
         number => '.',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       {                                                                                 
         description => 'Total Allele Count',                                            
         id => 'AN',                                                                     
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       {                                                                                 
         description => 'Ancestral Allele, ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/pilot_data/technical/reference/ancestral_alignments/README',
         id => 'AA',                                                                     
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'String'                                                                
       },                                                                                
       {                                                                                 
         description => 'Global Allele Frequency based on AC/AN',                        
         id => 'AF',                                                                     
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Allele Frequency for samples from AMR based on AC/AN',          
         id => 'AMR_AF',                                                                 
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Allele Frequency for samples from ASN based on AC/AN',          
         id => 'ASN_AF',                                                                 
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Allele Frequency for samples from AFR based on AC/AN',          
         id => 'AFR_AF',                                                                 
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Allele Frequency for samples from EUR based on AC/AN',          
         id => 'EUR_AF',                                                                 
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'indicates what type of variant the line represents',            
         id => 'VT',                                                                     
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'String'                                                                
       },                                                                                
       {                                                                                 
         description => 'indicates if a snp was called when analysing the low coverage or exome alignment data',
         id => 'SNPSOURCE',                                                              
         key => 'INFO',                                                                  
         number => '.',                                                                  
         type => 'String'                                                                
       },                                                                                
       {                                                                                 
         description => 'Genotype',                                                      
         id => 'GT',                                                                     
         key => 'FORMAT',                                                                
         number => '1',                                                                  
         type => 'String'                                                                
       },                                                                                
       {                                                                                 
         description => 'Genotype dosage from MaCH/Thunder',                             
         id => 'DS',                                                                     
         key => 'FORMAT',                                                                
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Genotype Likelihoods',                                          
         id => 'GL',                                                                     
         key => 'FORMAT',                                                                
         number => '.',                                                                  
         type => 'Float'                                                                 
       },
       {                                         
          key => 'assembly',                      
          value => 'GRCh37'                       
        },                                        
        {                                         
          key => 'source_name',                   
          value => '1000 Genomes phase1'          
        },                                        
        {                                         
          key => 'source_url',                    
          value => 'http://www.1000genomes.org/'  
        },                                         
        { 
          key => 'set_name',      
          value => '1000GENOMES:phase_1:AFR'
        } 
       ]
    },                                            
    {                                             
      datasetId => '1',                           
      id => '21',                                 
      metadata => [                               
{ 
         description => 'MLE Allele Frequency Accounting for LD',                        
         id => 'LDAF',                                                                   
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Average posterior probability from MaCH/Thunder',               
         id => 'AVGPOST',                                                                
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Genotype imputation quality from MaCH/Thunder',                 
         id => 'RSQ',                                                                    
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Per-marker Mutation rate from MaCH/Thunder',                    
         id => 'ERATE',                                                                  
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Per-marker Transition rate from MaCH/Thunder',                  
         id => 'THETA',                                                                  
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Confidence interval around END for imprecise variants',         
         id => 'CIEND',                                                                  
         key => 'INFO',                                                                  
         number => '2',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       {                                                                                 
         description => 'Confidence interval around POS for imprecise variants',         
         id => 'CIPOS',                                                                  
         key => 'INFO',                                                                  
         number => '2',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       {                                                                                 
         description => 'End position of the variant described in this record',          
         id => 'END',                                                                    
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       {                                                                                 
         description => 'Length of base pair identical micro-homology at event breakpoints',
         id => 'HOMLEN',                                                                 
         key => 'INFO',                                                                  
         number => '.',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       {                                                                                 
         description => 'Sequence of base pair identical micro-homology at event breakpoints',
         id => 'HOMSEQ',                                                                 
         key => 'INFO',                                                                  
         number => '.',                                                                  
         type => 'String'                                                                
       },                                                                                
       {                                                                                 
         description => 'Difference in length between REF and ALT alleles',              
         id => 'SVLEN',                                                                  
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       {                                                                                 
         description => 'Type of structural variant',                                    
         id => 'SVTYPE',                                                                 
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'String'                                                                
       },                                                                                
       {                                                                                 
         description => 'Alternate Allele Count',                                        
         id => 'AC',                                                                     
         key => 'INFO',                                                                  
         number => '.',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       {                                                                                 
         description => 'Total Allele Count',                                            
         id => 'AN',                                                                     
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       {                                                                                 
         description => 'Ancestral Allele, ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/pilot_data/technical/reference/ancestral_alignments/README',
         id => 'AA',                                                                     
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'String'                                                                
       },                                                                                
       {                                                                                 
         description => 'Global Allele Frequency based on AC/AN',                        
         id => 'AF',                                                                     
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Allele Frequency for samples from AMR based on AC/AN',          
         id => 'AMR_AF',                                                                 
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Allele Frequency for samples from ASN based on AC/AN',          
         id => 'ASN_AF',                                                                 
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Allele Frequency for samples from AFR based on AC/AN',          
         id => 'AFR_AF',                                                                 
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Allele Frequency for samples from EUR based on AC/AN',          
         id => 'EUR_AF',                                                                 
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'indicates what type of variant the line represents',            
         id => 'VT',                                                                     
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'String'                                                                
       },                                                                                
       {                                                                                 
         description => 'indicates if a snp was called when analysing the low coverage or exome alignment data',
         id => 'SNPSOURCE',                                                              
         key => 'INFO',                                                                  
         number => '.',                                                                  
         type => 'String'                                                                
       },                                                                                
       {                                                                                 
         description => 'Genotype',                                                      
         id => 'GT',                                                                     
         key => 'FORMAT',                                                                
         number => '1',                                                                  
         type => 'String'                                                                
       },                                                                                
       {                                                                                 
         description => 'Genotype dosage from MaCH/Thunder',                             
         id => 'DS',                                                                     
         key => 'FORMAT',                                                                
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Genotype Likelihoods',                                          
         id => 'GL',                                                                     
         key => 'FORMAT',                                                                
         number => '.',                                                                  
         type => 'Float'                                                                 
       },
        {                                         
          key => 'assembly',                      
          value => 'GRCh37'                       
        },                                        
        {                                         
          key => 'source_name',                   
          value => '1000 Genomes phase1'          
        },                                        
        {                                         
          key => 'source_url',                    
          value => 'http://www.1000genomes.org/'  
        },
        {
          key => 'set_name',
          value => '1000GENOMES:phase_1:AMR'
        } 
      ]                                           
    },                                            
    {                                             
      pageToken => '22'                           
    }                                             
  ]                                               
};      
my $expected_data2 = { 
  variantSets => [                                
    {                                             
      datasetId => '1',                           
      id => '20',                                 
      metadata => [                               
{ 
         description => 'MLE Allele Frequency Accounting for LD',                        
         id => 'LDAF',                                                                   
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Average posterior probability from MaCH/Thunder',               
         id => 'AVGPOST',                                                                
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Genotype imputation quality from MaCH/Thunder',                 
         id => 'RSQ',                                                                    
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Per-marker Mutation rate from MaCH/Thunder',                    
         id => 'ERATE',                                                                  
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Per-marker Transition rate from MaCH/Thunder',                  
         id => 'THETA',                                                                  
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Confidence interval around END for imprecise variants',         
         id => 'CIEND',                                                                  
         key => 'INFO',                                                                  
         number => '2',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       {                                                                                 
         description => 'Confidence interval around POS for imprecise variants',         
         id => 'CIPOS',                                                                  
         key => 'INFO',                                                                  
         number => '2',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       {                                                                                 
         description => 'End position of the variant described in this record',          
         id => 'END',                                                                    
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       {                                                                                 
         description => 'Length of base pair identical micro-homology at event breakpoints',
         id => 'HOMLEN',                                                                 
         key => 'INFO',                                                                  
         number => '.',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       {                                                                                 
         description => 'Sequence of base pair identical micro-homology at event breakpoints',
         id => 'HOMSEQ',                                                                 
         key => 'INFO',                                                                  
         number => '.',                                                                  
         type => 'String'                                                                
       },                                                                                
       {                                                                                 
         description => 'Difference in length between REF and ALT alleles',              
         id => 'SVLEN',                                                                  
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       {                                                                                 
         description => 'Type of structural variant',                                    
         id => 'SVTYPE',                                                                 
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'String'                                                                
       },                                                                                
       {                                                                                 
         description => 'Alternate Allele Count',                                        
         id => 'AC',                                                                     
         key => 'INFO',                                                                  
         number => '.',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       {                                                                                 
         description => 'Total Allele Count',                                            
         id => 'AN',                                                                     
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       {                                                                                 
         description => 'Ancestral Allele, ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/pilot_data/technical/reference/ancestral_alignments/README',
         id => 'AA',                                                                     
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'String'                                                                
       },                                                                                
       {                                                                                 
         description => 'Global Allele Frequency based on AC/AN',                        
         id => 'AF',                                                                     
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Allele Frequency for samples from AMR based on AC/AN',          
         id => 'AMR_AF',                                                                 
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Allele Frequency for samples from ASN based on AC/AN',          
         id => 'ASN_AF',                                                                 
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Allele Frequency for samples from AFR based on AC/AN',          
         id => 'AFR_AF',                                                                 
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Allele Frequency for samples from EUR based on AC/AN',          
         id => 'EUR_AF',                                                                 
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'indicates what type of variant the line represents',            
         id => 'VT',                                                                     
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'String'                                                                
       },                                                                                
       {                                                                                 
         description => 'indicates if a snp was called when analysing the low coverage or exome alignment data',
         id => 'SNPSOURCE',                                                              
         key => 'INFO',                                                                  
         number => '.',                                                                  
         type => 'String'                                                                
       },                                                                                
       {                                                                                 
         description => 'Genotype',                                                      
         id => 'GT',                                                                     
         key => 'FORMAT',                                                                
         number => '1',                                                                  
         type => 'String'                                                                
       },                                                                                
       {                                                                                 
         description => 'Genotype dosage from MaCH/Thunder',                             
         id => 'DS',                                                                     
         key => 'FORMAT',                                                                
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Genotype Likelihoods',                                          
         id => 'GL',                                                                     
         key => 'FORMAT',                                                                
         number => '.',                                                                  
         type => 'Float'                                                                 
       },
        {                                         
          key => 'assembly',                      
          value => 'GRCh37'                       
        },                                        
        {                                         
          key => 'source_name',                   
          value => '1000 Genomes phase1'          
        },                                        
        {                                         
          key => 'source_url',                    
          value => 'http://www.1000genomes.org/'  
        },
        {
          key => 'set_name',  
          value => '1000GENOMES:phase_1:AFR'
        }                                         
      ]                                           
    },                                            
    {                                             
      datasetId => '1',                           
      id => '21',                                 
      metadata => [                               
{ 
         description => 'MLE Allele Frequency Accounting for LD',                        
         id => 'LDAF',                                                                   
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Average posterior probability from MaCH/Thunder',               
         id => 'AVGPOST',                                                                
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Genotype imputation quality from MaCH/Thunder',                 
         id => 'RSQ',                                                                    
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Per-marker Mutation rate from MaCH/Thunder',                    
         id => 'ERATE',                                                                  
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Per-marker Transition rate from MaCH/Thunder',                  
         id => 'THETA',                                                                  
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Confidence interval around END for imprecise variants',         
         id => 'CIEND',                                                                  
         key => 'INFO',                                                                  
         number => '2',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       {                                                                                 
         description => 'Confidence interval around POS for imprecise variants',         
         id => 'CIPOS',                                                                  
         key => 'INFO',                                                                  
         number => '2',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       {                                                                                 
         description => 'End position of the variant described in this record',          
         id => 'END',                                                                    
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       {                                                                                 
         description => 'Length of base pair identical micro-homology at event breakpoints',
         id => 'HOMLEN',                                                                 
         key => 'INFO',                                                                  
         number => '.',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       {                                                                                 
         description => 'Sequence of base pair identical micro-homology at event breakpoints',
         id => 'HOMSEQ',                                                                 
         key => 'INFO',                                                                  
         number => '.',                                                                  
         type => 'String'                                                                
       },                                                                                
       {                                                                                 
         description => 'Difference in length between REF and ALT alleles',              
         id => 'SVLEN',                                                                  
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       {                                                                                 
         description => 'Type of structural variant',                                    
         id => 'SVTYPE',                                                                 
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'String'                                                                
       },                                                                                
       {                                                                                 
         description => 'Alternate Allele Count',                                        
         id => 'AC',                                                                     
         key => 'INFO',                                                                  
         number => '.',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       {                                                                                 
         description => 'Total Allele Count',                                            
         id => 'AN',                                                                     
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       {                                                                                 
         description => 'Ancestral Allele, ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/pilot_data/technical/reference/ancestral_alignments/README',
         id => 'AA',                                                                     
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'String'                                                                
       },                                                                                
       {                                                                                 
         description => 'Global Allele Frequency based on AC/AN',                        
         id => 'AF',                                                                     
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Allele Frequency for samples from AMR based on AC/AN',          
         id => 'AMR_AF',                                                                 
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Allele Frequency for samples from ASN based on AC/AN',          
         id => 'ASN_AF',                                                                 
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Allele Frequency for samples from AFR based on AC/AN',          
         id => 'AFR_AF',                                                                 
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Allele Frequency for samples from EUR based on AC/AN',          
         id => 'EUR_AF',                                                                 
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'indicates what type of variant the line represents',            
         id => 'VT',                                                                     
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'String'                                                                
       },                                                                                
       {                                                                                 
         description => 'indicates if a snp was called when analysing the low coverage or exome alignment data',
         id => 'SNPSOURCE',                                                              
         key => 'INFO',                                                                  
         number => '.',                                                                  
         type => 'String'                                                                
       },                                                                                
       {                                                                                 
         description => 'Genotype',                                                      
         id => 'GT',                                                                     
         key => 'FORMAT',                                                                
         number => '1',                                                                  
         type => 'String'                                                                
       },                                                                                
       {                                                                                 
         description => 'Genotype dosage from MaCH/Thunder',                             
         id => 'DS',                                                                     
         key => 'FORMAT',                                                                
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       {                                                                                 
         description => 'Genotype Likelihoods',                                          
         id => 'GL',                                                                     
         key => 'FORMAT',                                                                
         number => '.',                                                                  
         type => 'Float'                                                                 
       },
        {                                         
          key => 'assembly',                      
          value => 'GRCh37'                       
        },                                        
        {                                         
          key => 'source_name',                   
          value => '1000 Genomes phase1'          
        },                                        
        {                                         
          key => 'source_url',                    
          value => 'http://www.1000genomes.org/'  
        },
        {  
          key => 'set_name',   
          value => '1000GENOMES:phase_1:AMR' 
        }                                         
      ]                                           
    },                                            
    {                                             
      pageToken => '22'                           
    }                                             
  ]                                               
};                

my $json1 = json_POST( $base, $post_data1, 'variantset - 2 entries' );
eq_or_diff($json1, $expected_data1, "Checking the result from the gavariantset endpoint");

my $json2 = json_POST($base, $post_data2, 'variantset by datasetid');
eq_or_diff($json2, $expected_data2, "Checking the result from the gavariantset endpoint by dataset");
  

done_testing();
