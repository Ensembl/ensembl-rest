 use strict;
 use warnings;
  use Test::More qw/no_plan/;
# use Test::More tests => 13;


 BEGIN { use_ok 'Catalyst::Test', 'EnsEMBL::REST' }
 use HTTP::Headers;
 use HTTP::Request::Common;

 # GET request

 my $request = GET('http://localhost');
 my $response = request($request);
 ok( $response = request($request), 'Request');
 ok( $response->is_success, 'Response Successful 2xx' );
 is( $response->content_type, 'text/html', 'Response Content-Type' );


 $request = GET(
         'http://localhost:3000/gene_adaptor/fetch_by_stable_id/ENSG00000101321',
         'Content-Type' => 'application/json',
         );

ok( $response = request($request), 'Request');
diag $response->content;

 ok( $response->is_success, 'Response Successful 2xx' );
 is( $response->content_type, 'application/json', 'Response Content-Type' );

 $request = GET(
         'http://localhost:3000/gene/fetch_by_stable_id/ENSG00000101321/description',
         'Content-Type' => 'text/xml',
         );
ok( $response = request($request), 'Request');
diag $response->content;

 ok( $response->is_success, 'Response Successful 2xx' );
 is( $response->content_type, 'text/xml', 'Response Content-Type' );


 $request = GET(
         'http://localhost:3000/gene/fetch_by_stable_id/ENSG00000101321/descriptio',
         'Content-Type' => 'application/json',
         );

ok( $response = request($request), 'Request');
diag $response->content;

#  ok( $response->is_success, 'Response Successful 2xx' );
#  is( $response->content_type, 'application/json', 'Response Content-Type' );
diag $response->is_success;

#  $request = GET(
#          'http://localhost:3000/gene/fetch_by_stable_id/ENSG00000101321/seq',
#          'Content-Type' => 'application/json',
#          );
# 
#  ok( $response = request($request), 'Request');
# diag $response->content;
# 
#  ok( $response->is_success, 'Response Successful 2xx' );
#  is( $response->content_type, 'application/json', 'Response Content-Type' );
