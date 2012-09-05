use strict;
use warnings;
use EnsEMBL::REST;

my $app = EnsEMBL::REST->apply_default_middlewares(EnsEMBL::REST->psgi_app);
$app;

