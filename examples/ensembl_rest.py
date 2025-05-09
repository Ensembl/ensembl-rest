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

# required module imports
import httplib2, urllib, json, sys, StringIO
from Bio import SeqIO

# setup http object
http = httplib2.Http(".cache")

iterations=1
if len(sys.argv) == 2 :
  iterations = int(sys.argv[1])

for x in range(0,iterations) :
  print str(x)
  #Get gene genomic seq
  resp, content = http.request("http://127.0.0.1:3000/sequence/id/ENSG00000139618.fasta", method="GET", headers={"Content-Type":"text/plain"})

  # check response ok
  if not resp.status == 200:
	  print "Invalid response: ", resp.status
	  sys.exit()

  io = StringIO.StringIO(content)
  for record in SeqIO.parse(io, "fasta") :
    print "definition :" + record.id
    print "nalen      :" + str(len(record.seq))
