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


use Cwd;
use File::Spec;
use File::Basename qw/dirname/;
use Test::More;
use Test::Warnings;
use Bio::EnsEMBL::Test::TestUtils;

if ( not $ENV{TEST_AUTHOR} ) {
  my $msg = 'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.';
  plan( skip_all => $msg );
}


#chdir into the file's target & request cwd() which should be fully resolved now.
#then go back
my $file_dir = dirname(__FILE__);
my $original_dir = cwd();
chdir($file_dir);
my $cur_dir = cwd();
chdir($original_dir);
my $root = File::Spec->catdir($cur_dir, File::Spec->updir());
print "Looking at $file_dir, $original_dir, $cur_dir and $root\n";

my @source_files = map {all_source_code(File::Spec->catfile($root, $_))} qw(benchmarks bin configurations docs examples lib root script selenium t);
#Find all files & run
foreach my $f (@source_files) {
    next if $f =~ /t\/test-genome-DBs\//;
    next if $f =~ /\/blib\//;
    next if $f =~ /\.conf\b/;
    next if $f =~ /banner\b/;
    next if $f =~ /CLEAN/;
    next if $f =~ /\.(tmpl|hash|nw|ctl|txt|html|textile|css)$/;
    has_apache2_licence($f);
}

done_testing();
