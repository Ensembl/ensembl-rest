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
use feature 'say';
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Registry;

my $iterations = 1;
if(@ARGV) {
  $iterations = $ARGV[0];
}

# Bio::EnsEMBL::DBSQL::DBAdaptor->new(-HOST => '127.0.0.1', -PORT => 33067, -DBNAME => 'ensembl_stable_ids_67', -SPECIES => 'multi', -GROUP => 'stable_ids', -USER => 'ensro');
my $dba = Bio::EnsEMBL::DBSQL::DBAdaptor->new(
  # -HOST => 'ensembldb.ensembl.org',
  # -HOST => 'useastdb.ensembl.org',
  # -PORT => 5306,
  # -USER => 'anonymous',
  
  -HOST => '127.0.0.1', -PORT => 33069, -USER => 'ensro',
  
  -SPECIES => 'homo_sapiens',
  -DBNAME => 'homo_sapiens_core_67_37',
  -NO_CACHE => 1,
  -DISCONNECT_WHEN_INACTIVE => 1,
);

my $stable_id = 'ENSG00000139618';

foreach my $iter (0..$iterations) {
  my ( $species, $object_type, $db_type ) = Bio::EnsEMBL::Registry->get_species_and_object_type($stable_id);
  my $db_adaptor = Bio::EnsEMBL::Registry->get_DBAdaptor($species, $db_type);
  $db_adaptor->dbc()->prevent_disconnect(sub {
    my $adaptor = Bio::EnsEMBL::Registry->get_adaptor($species, $db_type, $object_type);
    my $gene = $adaptor->fetch_by_stable_id($stable_id);
    my $seq = $gene->feature_Slice()->seq();
    say "definition: ".$gene->feature_Slice()->name();
    say "nalen:      ".length($seq);
  });
}
