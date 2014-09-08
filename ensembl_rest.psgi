use strict;
use warnings;
use EnsEMBL::REST;
use Plack::Builder;
use Plack::Util;

my $app = EnsEMBL::REST->apply_default_middlewares(EnsEMBL::REST->psgi_app);

builder {
  enable 'DetectExtension';
  enable 'EnsemblRestHeaders';
  $app;
}