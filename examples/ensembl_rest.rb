# Copyright [2020-2025] EMBL-European Bioinformatics Institute
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


# required module imports
require 'net/http'
require 'uri'
require 'rubygems'
require 'json'
require 'bio'
require 'stringio'

iterations=0
if ARGV.length == 1
  iterations = ARGV[0].to_i - 1
end

# setup http object
url = URI.parse('http://127.0.0.1:3000')
http = Net::HTTP.new(url.path, url.port)

# call GET to retrieve BRCA2 gene
get_path = 'sequence/id/ENSG00000139618.fasta'

for i in 0..iterations
  request = Net::HTTP::Get.new(get_path, {'Content-Type' => 'text/plain'})
  response = http.request(request)

  # check response ok
  if response.code != "200":
  	puts "Invalid response: #{response.code}"
  	puts response.body
  	exit
  end

  io=StringIO.new(response.body)
  ff = Bio::FlatFile.new(Bio::FastaFormat, io)
  ff.each_entry do |f|
    puts "definition : " + f.definition
    puts "nalen      : " + f.nalen.to_s
  end
end