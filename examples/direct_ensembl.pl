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