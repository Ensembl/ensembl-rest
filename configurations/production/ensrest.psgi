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
      expire => 7200,
    }),
    max_requests => 55000, #55000 requests per hr (~15 per second)
    client_id_prefix => '15rps_hour',
    message => 'You have exceeded your limit which is 55,000 requests per hour (~15 per second)',
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
    max_requests => 16,
    client_id_prefix => '16rps_second',
    retry_after_addition => 1,
    message => 'You have exceeded the limit of 15 requests per second; please reduce your concurrent connections',
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
    
    #------ Plack to set ContentLength header
    enable "ContentLength";

    enable "Deflater",
      content_type =>
      [ 'text/css', 'text/html', 'text/javascript', 'application/javascript' ],
      vary_user_agent => 1;

    #----- Javascript & CSS minimisation and expire dates set
    # CSS assets are first
    enable "Assets", files => [<$staticdir/static/css/*.css>, "$staticdir/static/js/highlight/styles/default.css"];

    #Javascript assets are second
    enable "Assets",
      files  => [<$staticdir/static/js/*.js>],
      type   => 'js',
      minify => 1;
   
    #----- Plack to serve static content - THIS MUST COME AFTER ASSETS GENERATION AS THEY HAVE FILE EXTENSIONS
    enable "Static",
      path => qr{\.(?:js|css|jpe?g|gif|ico|png|html?|swf|txt)$},
      root => $staticdir;

    #------ END OF PLUGINS -------#

    $app;
}
