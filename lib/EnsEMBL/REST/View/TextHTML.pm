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

package EnsEMBL::REST::View::TextHTML;
use Moose;
use namespace::autoclean;
use HTML::Entities;

extends 'Catalyst::View';
 
sub process {
  my ($self, $c, $stash_key) = @_;
  $stash_key ||= 'rest';
  
  my $title = $self->get_title($c, $stash_key);
  my $content = $self->get_content($c, $stash_key);
  $content = ${$content} if ref($content) eq 'SCALAR';
  my $text = HTML::Entities::encode($content);
  
  my $template = <<'TMPL';
  <!DOCTYPE html
  	PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
  	 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
  <html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US">
  <head>
  <title>%s</title>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
  </head>
  <body>
  <pre>%s</pre>

  </body>
  </html>
TMPL
  my $output = sprintf($template, $title, $text);
  $c->response->output( $output );
  $c->res->headers->header('Content-Type' => 'text/html');
  return 1;
}

sub get_content {
  my ($self, $c, $key) = @_;
  return $c->stash->{$key};
}

sub get_title {
  my ($self, $c, $key) = @_;
  my $rest = $c->stash()->{$key};
  return $rest->{title} if ref($rest) eq 'HASH' && $rest->{title};
  return $c->config->{'name'} || '';
}

__PACKAGE__->meta->make_immutable;

1;
