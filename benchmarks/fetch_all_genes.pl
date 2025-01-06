#!/usr/bin/env perl
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
