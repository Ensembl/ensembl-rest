# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
# Copyright [2016-2025] EMBL-European Bioinformatics Institute
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


my $post_data2  = '{ "pageSize": 2,  "datasetId":"e06d8b736a50aaf1460f7640dce12012","pageToken":"" }';                                            

my $expected_data2 = { 
  variantSets => [                                
    {                                             
      datasetId => 'e06d8b736a50aaf1460f7640dce12012',                
      id => '1',                                 
      name => '1000 Genomes phase1:GRCh37',
      metadata => [                               
       { info => {},
         description => 'MLE Allele Frequency Accounting for LD',                        
         id => 'LDAF',                                                                   
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       { info => {},                                                                                
         description => 'Average posterior probability from MaCH/Thunder',               
         id => 'AVGPOST',                                                                
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       { info => {},                                                                                
         description => 'Genotype imputation quality from MaCH/Thunder',                 
         id => 'RSQ',                                                                    
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       { info => {},                                                                     
         description => 'Per-marker Mutation rate from MaCH/Thunder',                    
         id => 'ERATE',                                                                  
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       { info => {},                                                                     
         description => 'Per-marker Transition rate from MaCH/Thunder',                  
         id => 'THETA',                                                                  
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       { info => {},                                                                     
         description => 'Confidence interval around END for imprecise variants',         
         id => 'CIEND',                                                                  
         key => 'INFO',                                                                  
         number => '2',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       { info => {},                                                                     
         description => 'Confidence interval around POS for imprecise variants',         
         id => 'CIPOS',                                                                  
         key => 'INFO',                                                                  
         number => '2',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       { info => {},                                                                     
         description => 'End position of the variant described in this record',          
         id => 'END',                                                                    
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       { info => {},                                                                     
         description => 'Length of base pair identical micro-homology at event breakpoints',
         id => 'HOMLEN',                                                                 
         key => 'INFO',                                                                  
         number => '.',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       { info => {},                                                                     
         description => 'Sequence of base pair identical micro-homology at event breakpoints',
         id => 'HOMSEQ',                                                                 
         key => 'INFO',                                                                  
         number => '.',                                                                  
         type => 'String'                                                                
       },                                                                                
       { info => {},                                                                     
         description => 'Difference in length between REF and ALT alleles',              
         id => 'SVLEN',                                                                  
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       { info => {},                                                                     
         description => 'Type of structural variant',                                    
         id => 'SVTYPE',                                                                 
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'String'                                                                
       },                                                                                
       { info => {},                                                                     
         description => 'Alternate Allele Count',                                        
         id => 'AC',                                                                     
         key => 'INFO',                                                                  
         number => '.',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       { info => {},                                                                     
         description => 'Total Allele Count',                                            
         id => 'AN',                                                                     
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       { info => {},                                                                     
         description => 'Ancestral Allele, ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/pilot_data/technical/reference/ancestral_alignments/README',
         id => 'AA',                                                                     
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'String'                                                                
       },                                                                                
       { info => {},                                                                     
         description => 'Global Allele Frequency based on AC/AN',                        
         id => 'AF',                                                                     
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       { info => {},                                                                     
         description => 'Allele Frequency for samples from AMR based on AC/AN',          
         id => 'AMR_AF',                                                                 
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       { info => {},                                                                     
         description => 'Allele Frequency for samples from ASN based on AC/AN',          
         id => 'ASN_AF',                                                                 
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       { info => {},                                                                     
         description => 'Allele Frequency for samples from AFR based on AC/AN',          
         id => 'AFR_AF',                                                                 
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       { info => {},                                                                     
         description => 'Allele Frequency for samples from EUR based on AC/AN',          
         id => 'EUR_AF',                                                                 
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       { info => {},                                                                     
         description => 'indicates what type of variant the line represents',            
         id => 'VT',                                                                     
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'String'                                                                
       },                                                                                
       { info => {},                                                                     
         description => 'indicates if a snp was called when analysing the low coverage or exome alignment data',
         id => 'SNPSOURCE',                                                              
         key => 'INFO',                                                                  
         number => '.',                                                                  
         type => 'String'                                                                
       },                                                                                
       { info => {},                                                                     
         description => 'Genotype',                                                      
         id => 'GT',                                                                     
         key => 'FORMAT',                                                                
         number => '1',                                                                  
         type => 'String'                                                                
       },                                                                                
       { info => {},                                                                     
         description => 'Genotype dosage from MaCH/Thunder',                             
         id => 'DS',                                                                     
         key => 'FORMAT',                                                                
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       { info => {},                                                                     
         description => 'Genotype Likelihoods',                                          
         id => 'GL',                                                                     
         key => 'FORMAT',                                                                
         number => '.',                                                                  
         type => 'Float'                                                                 
       },
      ],
      referenceSetId => 'GRCh37'                                           
    },
  ],
  nextPageToken => undef
};                

my $json2 = json_POST($base, $post_data2, 'variantset by datasetid');
eq_or_diff($json2, $expected_data2, "Checking the result from the GA4GH variantset endpoint by dataset");
  

## GET
 
$base =~ s/\/search//;
my $id = 1;
my $json_get = json_GET("$base/$id", 'get variantset');

my $expected_get_data =  {                                             
      datasetId => 'e06d8b736a50aaf1460f7640dce12012',                           
      id => '1',                                 
      name => '1000 Genomes phase1:GRCh37',
      metadata => [                               
       { info => {},
         description => 'MLE Allele Frequency Accounting for LD',                        
         id => 'LDAF',                                                                   
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       { info => {},                                                                                
         description => 'Average posterior probability from MaCH/Thunder',               
         id => 'AVGPOST',                                                                
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       { info => {},                                                                     
         description => 'Genotype imputation quality from MaCH/Thunder',                 
         id => 'RSQ',                                                                    
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       { info => {},                                                                     
         description => 'Per-marker Mutation rate from MaCH/Thunder',                    
         id => 'ERATE',                                                                  
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       { info => {},                                                                     
         description => 'Per-marker Transition rate from MaCH/Thunder',                  
         id => 'THETA',                                                                  
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       { info => {},                                                                     
         description => 'Confidence interval around END for imprecise variants',         
         id => 'CIEND',                                                                  
         key => 'INFO',                                                                  
         number => '2',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       { info => {},                                                                     
         description => 'Confidence interval around POS for imprecise variants',         
         id => 'CIPOS',                                                                  
         key => 'INFO',                                                                  
         number => '2',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       { info => {},                                                                     
         description => 'End position of the variant described in this record',          
         id => 'END',                                                                    
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       { info => {},                                                                     
         description => 'Length of base pair identical micro-homology at event breakpoints',
         id => 'HOMLEN',                                                                 
         key => 'INFO',                                                                  
         number => '.',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       { info => {},                                                                     
         description => 'Sequence of base pair identical micro-homology at event breakpoints',
         id => 'HOMSEQ',                                                                 
         key => 'INFO',                                                                  
         number => '.',                                                                  
         type => 'String'                                                                
       },                                                                                
       { info => {},                                                                     
         description => 'Difference in length between REF and ALT alleles',              
         id => 'SVLEN',                                                                  
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       { info => {},                                                                     
         description => 'Type of structural variant',                                    
         id => 'SVTYPE',                                                                 
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'String'                                                                
       },                                                                                
       { info => {},                                                                     
         description => 'Alternate Allele Count',                                        
         id => 'AC',                                                                     
         key => 'INFO',                                                                  
         number => '.',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       { info => {},                                                                     
         description => 'Total Allele Count',                                            
         id => 'AN',                                                                     
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Integer'                                                               
       },                                                                                
       { info => {},                                                                     
         description => 'Ancestral Allele, ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/pilot_data/technical/reference/ancestral_alignments/README',
         id => 'AA',                                                                     
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'String'                                                                
       },                                                                                
       { info => {},                                                                     
         description => 'Global Allele Frequency based on AC/AN',                        
         id => 'AF',                                                                     
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       { info => {},                                                                     
         description => 'Allele Frequency for samples from AMR based on AC/AN',          
         id => 'AMR_AF',                                                                 
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       { info => {},                                                                     
         description => 'Allele Frequency for samples from ASN based on AC/AN',          
         id => 'ASN_AF',                                                                 
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       { info => {},                                                                     
         description => 'Allele Frequency for samples from AFR based on AC/AN',          
         id => 'AFR_AF',                                                                 
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       { info => {},                                                                     
         description => 'Allele Frequency for samples from EUR based on AC/AN',          
         id => 'EUR_AF',                                                                 
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       { info => {},                                                                     
         description => 'indicates what type of variant the line represents',            
         id => 'VT',                                                                     
         key => 'INFO',                                                                  
         number => '1',                                                                  
         type => 'String'                                                                
       },                                                                                
       { info => {},                                                                     
         description => 'indicates if a snp was called when analysing the low coverage or exome alignment data',
         id => 'SNPSOURCE',                                                              
         key => 'INFO',                                                                  
         number => '.',                                                                  
         type => 'String'                                                                
       },                                                                                
       { info => {},                                                                     
         description => 'Genotype',                                                      
         id => 'GT',                                                                     
         key => 'FORMAT',                                                                
         number => '1',                                                                  
         type => 'String'                                                                
       },                                                                                
       { info => {},                                                                     
         description => 'Genotype dosage from MaCH/Thunder',                             
         id => 'DS',                                                                     
         key => 'FORMAT',                                                                
         number => '1',                                                                  
         type => 'Float'                                                                 
       },                                                                                
       { info => {},                                                                     
         description => 'Genotype Likelihoods',                                          
         id => 'GL',                                                                     
         key => 'FORMAT',                                                                
         number => '.',                                                                  
         type => 'Float'                                                                 
       },
  ],
   referenceSetId => 'GRCh37'       
};

eq_or_diff($json_get, $expected_get_data, "Checking the get result from the variantset endpoint");


done_testing();
