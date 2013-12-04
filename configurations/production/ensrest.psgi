use strict;
use warnings;

use Config;
use EnsEMBL::REST;
use File::Basename;
use File::Spec;
use Plack::Builder;
use Plack::Util;

use Plack::Middleware::EnsThrottle::MemcachedBackend;
use Cache::Memcached;

my $app = EnsEMBL::REST->psgi_app;

builder {

  #------ Set appropriate headers when we detect REST is being used as a ReverseProxy
  enable "Plack::Middleware::ReverseProxy";
  #------ Set Content-type headers when we detect a valid extension
  enable "DetectExtension";
  #------ Allow CrossOrigin requests from any host
  enable 'CrossOrigin', origins => '*';
  
  
  my $dirname = dirname(__FILE__);
  my $rootdir = File::Spec->rel2abs(File::Spec->catdir($dirname, File::Spec->updir(), File::Spec->updir()));
  my $staticdir = File::Spec->catdir($rootdir, 'root');

  enable 'EnsThrottle::Hour',
    backend => Plack::Middleware::EnsThrottle::MemcachedBackend->new({
      memcached => Cache::Memcached->new(servers => ['127.0.0.1:11211']), 
      expire => 2,
    }),
    max_requests => 11100, #1100 requests per hr (~3 per second)
    client_id_prefix => '3rps_hour',
    message => 'You have exceeded your limit which is 11,100 requests per hour (~3 per second)',
    path    => sub {
      my ($path) = @_;
      return 1 if $path ne '/';
      return 1 if $path !~ /\/(?:documentation|static|_asset)/;
      return 0;
    };

  enable 'EnsThrottle::Second',
    backend => Plack::Middleware::EnsThrottle::MemcachedBackend->new({
      memcached => Cache::Memcached->new(servers => ['127.0.0.1:11211']), 
      expire => 2,
    }),
    max_requests => 6,
    client_id_prefix => '6rps_second',
    retry_after_addition => 1,
    message => 'You have exceeded the limit of 6 requests per second; please reduce your concurrent connections',
    path  => sub {
      my ($path) = @_;
      return 1 if $path ne '/';
      return 1 if $path !~ /\/(?:documentation|static|_asset)/;
      return 0;
    };

    #-------- RECOMMENDED PLUGINS -------- #

    #------ Reset processes if they get too big
    #if mac and SizeLimit is on then need to require this:
    Plack::Util::load_class('BSD::Resource') if $Config{osname} eq 'darwin';
    enable 'SizeLimit' => (
        max_unshared_size_in_kb => (300 * 1024),    # 300MB per process (memory assigned just to the process)
         # max_process_size_in_kb => (4096*25),  # seems to be the option which looks at overall size
        check_every_n_requests => 10,
    );

    #------ Adds a better stack trace
    enable 'StackTrace';

    #------ Adds a runtime header
    enable 'Runtime';

    #----- Enable compression on output
    enable sub {
      my $app = shift;
      sub {
        my $env = shift;
        my $ua = $env->{HTTP_USER_AGENT} || '';

        # Netscape has some problem
        $env->{"psgix.compress-only-text/html"} = 1 if $ua =~ m!^Mozilla/4!;

        # Netscape 4.06-4.08 have some more problems
        $env->{"psgix.no-compress"} = 1 if $ua =~ m!^Mozilla/4\.0[678]!;

        # MSIE (7|8) masquerades as Netscape, but it is fine
        if ( $ua =~ m!\bMSIE (?:7|8)! ) {
          $env->{"psgix.no-compress"}             = 0;
          $env->{"psgix.compress-only-text/html"} = 0;
        }
        $app->($env);
      }
    };

    enable "Deflater",
      content_type =>
      [ 'text/css', 'text/html', 'text/javascript', 'application/javascript' ],
      vary_user_agent => 1;

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
