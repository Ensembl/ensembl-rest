# Copyright [1999-2013] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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
use LWP::Simple;

my $file = $ARGV[0];
my $iterations = $ARGV[1];

open my $fh, '<', $file or die "Cannot open $file: $!";
my @ids = map { chomp($_); $_ } <$fh>;
close $fh;

$iterations ||= 10;

foreach my $iter (1..$iterations) {
  my $url = $ids[rand($#ids)];
  my $content = get($url);
}
