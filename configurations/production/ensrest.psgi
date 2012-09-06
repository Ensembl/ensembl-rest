use strict;
use warnings;
use Plack::Builder;
use EnsEMBL::REST;
use Config;
use Plack::Util;
use File::Basename;
use File::Spec;
my $app = EnsEMBL::REST->psgi_app;

builder {
  
  my $dirname = dirname(__FILE__);
  my $rootdir = File::Spec->rel2abs(File::Spec->catdir($dirname, File::Spec->updir(), File::Spec->updir()));
  my $staticdir = File::Spec->catdir($rootdir, 'root');

# Throttle to 14,400 requests per hr;
# We can configure white_list, black_list, key_prefix (when using more global hashes) and backend which could be a remote memcached server
# enable 'Throttle::Hourly' => (
# 	max     => (3*60*60), #3 requests per second
# 	# backend => Plack::Middleware::Throttle::Backend::Hash->new(),
# 	message => 'Gone over your current limit',
# 	path    => qr{^/}
# );

    #-------- RECOMMENDED PLUGINS -------- #

    #------ Reset processes if they get too big
    #if mac and SizeLimit is on then need to require this:
    Plack::Util::load_class('BSD::Resource') if $Config{osname} eq 'darwin';
    enable 'SizeLimit' => (
        max_unshared_size_in_kb => (300 * 1024),    # 100MB per process (memory assigned just to the process)
         # max_process_size_in_kb => (4096*25),  # seems to be the option which looks at overall size
        check_every_n_requests => 10,
    );

    #------ Make uri_for do the right thing
    enable "Plack::Middleware::ReverseProxy";

    #------ Adds a better stack trace
    enable 'StackTrace';

    #------ Adds a runtime header
    enable 'Runtime';

    #----- Plack to serve static content
    enable "Static",
      path => qr{\.(?:js|css|jpe?g|gif|ico|png|html?|swf|txt)$},
      root => $staticdir;

    #----- Javascript & CSS minimisation and expire dates set
    # CSS assets are first
    enable "Assets", files => [<$staticdir/static/css/*.css>];

    #Javascript assets are second
    enable "Assets",
      files  => [<$staticdir/static/js/*.js>],
      type   => 'js',
      minify => 1;

    #------ Plack to set ContentLength header
    enable "ContentLength";

    #------ END OF PLUGINS -------#

    $app;
}
