package EnsEMBL::REST::Role::Content;

use Moose::Role;

sub is_content_type {
  my ($self, $c, $content_type) = @_;
  my $request_content_type = $c->request()->params->{'content-type'}; 
  my $headers_content_type =  $c->request()->headers()->content_type();
  if( (defined $request_content_type && $request_content_type eq $content_type) || 
      (defined $headers_content_type && $headers_content_type eq $content_type)) {
    return 1;
  }
  return 0;
}

sub set_content_dispsition {
  my ($self, $c, $name, $ext) = @_;
  die 'Not ext given' unless $ext;
  my $disposition = sprintf('attachment; filename=%s.%s', $name, $ext);
  $c->response->header('Content-Disposition' => $disposition);
  return;
}

1;