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
  return 1;
}

sub get_content {
  my ($self, $c, $key) = @_;
  return $c->stash->{$key};
}

sub get_title {
  my ($self, $c, $key) = @_;
  my $rest = $c->stash()->{$key};
  return $rest->{title} if $rest->{title};
  return $c->config->{'name'} || '';
}

__PACKAGE__->meta->make_immutable;

1;
