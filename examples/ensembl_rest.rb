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