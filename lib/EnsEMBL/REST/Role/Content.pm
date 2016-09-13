=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
Copyright [2016] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::REST::Role::Content;

###############################################################
####### HUGE WARNING
####### I'm not sure the following code will work all the time.
####### However it's working most of the time. Be aware!
###############################################################

use Moose::Role;
use Bio::EnsEMBL::Utils::Scalar qw/check_ref/;

sub is_content_type {
  my ($self, $c, $content_type) = @_;
  my $request = $c->request();
  my $headers = $request->headers();

  my $param_content_type = $request->parameters()->{'content-type'};
  my $headers_accept = $headers->header('Accept');
  my $headers_content_type =  $headers->content_type();

  # If it's a GET then Accepts gets bumped down to the bottom otherwise things go wrong
  if($request->method() eq 'GET') {
    if(check_ref($content_type, 'Regexp')) {
      if( (defined $headers_content_type && $headers_content_type =~ $content_type) || 
          (defined $param_content_type && $param_content_type =~ $content_type) ||
          (defined $headers_accept && $headers_accept =~ $content_type) ) {
        return 1;
      }
    }
    else {
      if( (defined $headers_content_type && $headers_content_type eq $content_type) || 
          (defined $param_content_type && $param_content_type eq $content_type) ||
          (defined $headers_accept && $headers_accept =~ /$content_type/i) ) {
        return 1;
      }
    }
  }
  # Must be a POST so do the Accepts take precedence thang
  else {
     # If it is already a regexp then apply against the values
    if(check_ref($content_type, 'Regexp')) {
      if( (defined $headers_accept && $headers_accept =~ $content_type) ||
          (defined $headers_content_type && $headers_content_type =~ $content_type) || 
          (defined $param_content_type && $param_content_type =~ $content_type)) {
        return 1;
      }
    }
    # Otherwise do the old code using eq & regex
    else {
      # Accepts ALWAYS WINS
      if( (defined $headers_accept && $headers_accept =~ /$content_type/i) ||
          (defined $param_content_type && $param_content_type eq $content_type) || 
          (defined $headers_content_type && $headers_content_type eq $content_type)) {
        return 1;
      }
    }
  }

  return 0;
}

sub set_content_disposition {
  my ($self, $c, $name, $ext) = @_;
  die 'Not ext given' unless $ext;
  my $disposition = sprintf('attachment; filename=%s.%s', $name, $ext);
  $c->response->header('Content-Disposition' => $disposition);
  return;
}

1;
