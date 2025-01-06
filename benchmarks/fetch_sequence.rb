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

require 'rubygems'
require 'ensembl'
require 'net/http'
require 'uri'
require 'json'

include Ensembl::Core

ids=[]
file='./random_ids.local.fixed.txt'
# file=ARGV[0]
File.open( file ).each do |line|
  if line =~ /^http:\/\/rest.ensembl.org\/sequence\/id\/(.+)\?/
    id_array = [$1]
    if line =~ /type=([a-z]+)$/ 
      id_array.push($1)
    end
  end
  ids.push(id_array)
end

iters=10
if ARGV[1]
  iters = ARGV[1].to_int
end

url = URI.parse('http://rest.ensembl.org')
http = Net::HTTP.new(url.path, url.port)
puts iters
(1..iters).each do |iter|
  choice = ids.choice
  id = choice[0]
  type = choice[1]
  
  request = Net::HTTP::Get.new('/lookup/'+id, {'Content-Type' => 'application/json'})
  response = http.request(request)
  
  location = JSON.parse(response.body)
  object_type = location['object_type']
  Ensembl::Core::DBConnection.connect(location['species'],68)

  if object_type == 'Gene'
    s = Gene.find_by_stable_id(id).slice.seq
  elsif object_type == 'Translation'
    redo
  elsif object_type == 'Transcript'
    s = transcript = Transcript.find_by_stable_id(id)
    if type && type == 'cds'
      s = transcript.cds_seq
    elsif type && type == 'cdna'
      s = transcript.seq
    else
      s = transcript.slice.seq
    end
  end

end


