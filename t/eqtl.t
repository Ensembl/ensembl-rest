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

use Test::More;
use Catalyst::Test ();
use Bio::EnsEMBL::ApiVersion qw/software_version/;
use Test::Differences;
use Data::Dumper;
use Bio::EnsEMBL::HDF5::EQTLAdaptor;
use Bio::EnsEMBL::Test::MultiTestDB;

use feature qw(say);

Catalyst::Test->import('EnsEMBL::REST');
my $multi = Bio::EnsEMBL::Test::MultiTestDB->new();
my $var_dba = $multi->get_DBAdaptor('variation');
my $core_dba = $multi->get_DBAdaptor('core');
require EnsEMBL::REST;
my $sqlite  = $Bin . '/test-genome-DBs/homo_sapiens/eqtl/homo_sapiens.hdf5.sqlite3';
my $hdf5 = $Bin . '/test-genome-DBs/homo_sapiens/eqtl/homo_sapiens.hdf5';
my $sql = $hdf5;

if(!-e $sql){warn "Missing SQL file $sql"}
if(!-e $hdf5){warn "Missing HDF5 file $hdf5"}

 say "SQL  file used: $sql";
 say "HDF5 file used: $hdf5";
my $eqtl_a = Bio::EnsEMBL::HDF5::EQTLAdaptor->new(  -FILENAME => $hdf5, -CORE_DB_ADAPTOR => $core_dba, VAR_DB_ADAPTOR => $var_dba, -DB_FILE => $sqlite);
$multi->add_DBAdaptor('eqtl', $eqtl_a);


my $response = json_GET("/eqtl/id/homo_sapiens/ENSG00000223972?content-type=application/json;statistic=p-value;tissue=Whole_Blood;variant_name=rs4951859", "Return p-value for known gene and variant");

# Floats rounded to prevent precision variations between architectures and compilation options
cmp_ok(sprintf("%.6f",$response->[0]->{minus_log10_p_value}) , '==', sprintf("%.6f",0.00618329914558938) ,'p-value accurate to 6 d.p.');
cmp_ok(sprintf("%.6f",$response->[0]->{value}) , '==', sprintf("%.6f",0.985863302490807) ,'value accurate to 6 d.p.');

done_testing();