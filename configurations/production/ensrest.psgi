use strict;
use warnings;

use Config;
use EnsEMBL::REST;
use File::Basename;
use File::Spec;
use Plack::Builder;
use Plack::Util;
use Plack::Middleware::Throttle::Backend::Memcached;

my $app = EnsEMBL::REST->apply_default_middlewares(EnsEMBL::REST->psgi_app);

builder {
  
  my $dirname = dirname(__FILE__);
  my $rootdir = File::Spec->rel2abs(File::Spec->catdir($dirname, File::Spec->updir(), File::Spec->updir()));
  my $staticdir = File::Spec->catdir($rootdir, 'root');

  enable 'Throttle::Hour' => (
    max     => 11100, #11100 requests per hr (~3 per second)
    backend =>  Plack::Middleware::Throttle::Backend::Memcached->new(
      driver => 'Cache::Memcached',
      expire => 3601, #Expire set to 1hr and 1 second
      args => {
        servers => ['127.0.0.1:11211'], 
        no_rehash => 1, 
        namespace => 'ensrest:throttle_3pr_hr:',
        debug => 0,
      }
    ),
    message => 'You have exceeded your limit which is 11,100 requests per hour (~3 per second)',
    path    => sub {
      my ($path) = @_;
      return 1 if $path eq '/';
      return 1 if $path !~ /\/(?:documentation|static)/;
      return 0;
    }
  );
  
  enable 'Throttle::Second' => (
    max     => 6, #6 requests per second
    backend =>  Plack::Middleware::Throttle::Backend::Memcached->new(
      driver => 'Cache::Memcached',
      expire => 2,
      args => {
        servers => ['127.0.0.1:11211'], 
        no_rehash => 1, 
        namespace => 'ensrest:throttle_6pr_second:',
        debug => 0,
      }
    ),
    message => 'You have exceeded the limit of 6 requests per second; please reduce your concurrent connections',
    path    => sub {
      my ($path) = @_;
      return 1 if $path eq '/';
      return 1 if $path !~ /\/(?:documentation|static)/;
      return 0;
    }
  );

    #-------- RECOMMENDED PLUGINS -------- #

    #------ Reset processes if they get too big
    #if mac and SizeLimit is on then need to require this:
    Plack::Util::load_class('BSD::Resource') if $Config{osname} eq 'darwin';
    enable 'SizeLimit' => (
        max_unshared_size_in_kb => (300 * 1024),    # 300MB per process (memory assigned just to the process)
         # max_process_size_in_kb => (4096*25),  # seems to be the option which looks at overall size
        check_every_n_requests => 10,
    );

    #------ Make uri_for do the right thing -- COMMENTED OUT SINCE apply_default_middlewares() BRINGS IT IN
    #enable "Plack::Middleware::ReverseProxy";

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
