#!/usr/bin/env perl

use strict;
use warnings;
use Bio::EnsEMBL::Registry;
use JSON -convert_blessed_universally;
use Benchmark qw/timethese/;
Bio::EnsEMBL::Registry->load_registry_from_db(
	-host => 'ensembldb.ensembl.org',
	-user => 'anonymous',
	-port => 5306,
	-verbose => 0,
	-no_cache => 1
);

my $ga = Bio::EnsEMBL::Registry->get_DBAdaptor('human', 'core')->get_GeneAdaptor();
my $genes = $ga->fetch_all();

timethese(1, {
  normal => sub {
    my $ga = Bio::EnsEMBL::Registry->get_DBAdaptor('human', 'core')->get_GeneAdaptor();
    my $genes = $ga->fetch_all();
  },
  json => sub { 
    my @genes = map { 
      delete $_->{adaptor}; 
      delete $_->slice()->{adaptor}; 
      delete $_->slice()->coord_system()->{adaptor}; 
      delete $_->display_xref()->{adaptor}; 
      delete $_->analysis()->{adaptor};
      $_ } @{$ga->fetch_all()};

    open my $fh, '>', 'allgenes.json' or die "Cannot open file: $!";
    my $scalar = JSON->new->allow_blessed(1)->convert_blessed(1)->encode(\@genes);
    print $fh $scalar;
    close $fh;
  }
});

__END__
my @genes = map { 
  delete $_->{adaptor}; 
  delete $_->slice()->{adaptor}; 
  delete $_->slice()->coord_system()->{adaptor}; 
  delete $_->display_xref()->{adaptor}; 
  delete $_->analysis()->{adaptor};
  $_ } @{$ga->fetch_all()};

open my $fh, '>', 'allgenes.json' or die "Cannot open file: $!";
my $scalar = JSON->new->allow_blessed(1)->convert_blessed(1)->encode(\@genes);
print $fh $scalar;
close $fh;