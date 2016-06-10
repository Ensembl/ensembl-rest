# Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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
use feature qw(say);


Catalyst::Test->import('EnsEMBL::REST');
require EnsEMBL::REST;
my $sql  = $Bin . '/test-eqtl-DBs/eqtl.hdf5.sqlite3';

my $hdf5 = $Bin . '/test-eqtl-DBs/eqtl.hdf5';
my $eqtl_a = Bio::EnsEMBL::HDF5::EQTLAdaptor->new(  -FILENAME => $hdf5);
warn Dumper($eqtl_a->fetch_all_tissues());


# warn ref($eqtl_a);
my $expected = {value => '0.985863302490807'};
json_GET(
  'eqtl/variant_name/homo_sapiens/rs4951859?content-type=application/json;statistic=p-value;stable_id=ENSG00000227232;tissue=Whole_Blood',  "Returned"
);
#

done_testing();
