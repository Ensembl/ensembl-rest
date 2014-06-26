# INSTALL

This guide is split into a number of sections pertaining to the steps required to get the REST service running using the Catalyst built-in scripts. Examples of PSGI setup is available from the root directory and under the configurations directory.

All commands assume a bash environment.

## The Quick Way (VM)

We provide a Vagrant (easy VirtualBox VM setups) machine spec currently available from https://github.com/andrewyatz/vagrant_machines/tree/master/ensembl/rest. To use this machine you should

- Download and install VirtualBox from https://www.virtualbox.org/
- Download and install Vagrant from http://www.vagrantup.com/
- Clone the vagrant machines repo using the command
  - `git clone https://github.com/andrewyatz/vagrant_machines.git`
- cd vagrant_machines/ensembl/rest
- start the VM and log into it
  - `vagrant up`
  - `vagrant ssh`
- you can change the version of REST installed by exporting ENSEMBL_VERSION before running vagrant up e.g. `ENSEMBL_VERSION=75 vagrant up`
- Follow the remaining part of this guide from Running the Server


## Installing on a Machine

### Required Binaries

Ensure you have the following binaries available:

- Perl v5.14 upwards
- cvs
- bash
- wget/curl


### Expected Directory Structure


Your directory structure should look like this after installation:
```
.
 \------- bioperl-1.2.3
 \------- ensembl
 \------- ensembl-compara
 \------- ensembl-external
 \------- ensembl-funcgen
 \------- ensembl-rest
 \------- ensembl-tools
 \------- ensembl-variation
```

### Installing Catalyst


Information on installing Catalyst can be found at:

- http://wiki.catalystframework.org/wiki/installation (basic)
- http://wiki.catalystframework.org/wiki/installingcatalyst (advanced)
  

If you are on Debian/Ubuntu you can find all required packages using (remembering you will probably need a C compiler):

```
apt-get install build-essential
apt-cache search catalyst
```

If you are on Fedora/RedHat then the following should suffice:

```
yum groupinstall "Development Tools"

yum install perl-Catalyst-Runtime perl-Catalyst-Devel /usr/bin/catalyst.pl
```

If you are using CPAN or CPANMINUS with local::lib then you can use:

```
cpanm Catalyst::Runtime Catalyst::Devel
```

Please remember that the REST API has more dependencies than the ones mentioned here. Please follow the guide carefully to ensure a good installation.


### Installing the Ensembl API


A number of guides to installing the Ensembl API are available from:

- http://www.ensembl.org/info/docs/api/api_installation.html
- http://www.ensembl.org/info/docs/api/api_git.html
- http://www.ensembl.org/info/docs/webcode/install/ensembl-code.html

Should you already have an Ensembl API for the required release then skip to "Installing the REST API".

We will partially work through the second document to install the API.

#### Installing BioPerl 1.2.3

Use one of the following commands to get BioPerl

`wget http://bioperl.org/DIST/old_releases/bioperl-1.2.3.tar.gz`

`curl -o bioperl-1.2.3.tar.gz http://bioperl.org/DIST/old_releases/bioperl-1.2.3.tar.gz`

Now untar

`tar zxvf bioperl-1.2.3.tar.gz`

####  Installing Ensembl API from Tarball

We will download the Ensembl API from our stable branch tarball and unpack.

```
wget ftp://ftp.ensembl.org/pub/ensembl-api.tar.gz
tar zxvf ensembl-api.tar.gz
```

### Installing the REST API

#### Installing from Git

This guide will checkout the stable current release (at the time of writing this is release/75 but this is updated every release)

```
git clone https://github.com/Ensembl/ensembl-rest.git
```

#### Bringing Ensembl onto your PERL5LIB

Using bash we bring each modules directory onto the library path:

```
  PERL5LIB=${PWD}/bioperl-1.2.3:${PERL5LIB}
  PERL5LIB=${PWD}/ensembl/modules:${PERL5LIB}
  PERL5LIB=${PWD}/ensembl-compara/modules:${PERL5LIB}
  PERL5LIB=${PWD}/ensembl-variation/modules:${PERL5LIB}
  PERL5LIB=${PWD}/ensembl-funcgen/modules:${PERL5LIB}
  export PERL5LIB
```

#### Setting up Catalyst and Ensembl REST using cpanm

First cd into the directory:

`cd ensembl-rest`

Then run cpanm asking it to install local dependencies

`cpanm --installdeps .`

This will run for quite some time but will install all recommended & essential libraries. After which run Makefile.PL to confirm the setup:

`perl Makefile.PL`

#### Installing with CPAN

Run the makefile:

`perl Makefile.PL`

This program will prompt to install CPAN dependencies required for the REST API. If you are on your machine as root and wish to do this into a central machine location then say Y to any prompt.

#### Installing using another dependency manager

Should you want to use another manager (such as apt or yum) you should use Makefile.PL's output as a way of checking for dependencies. Should anything report as being missing then quit the program (Ctrl+c), install the missing dependency and retry.

#### Confirming the setup

First run Makefile.PL

`perl Makefile.PL`

This will emit output looking like:

```
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

      include /Users/ayates/tmp/ensembl-rest/inc/Module/Install.pm
      include inc/Module/Install/Metadata.pm
      include inc/Module/Install/Base.pm
      include inc/Module/Install/Makefile.pm
      include inc/Module/Install/Catalyst.pm
      include inc/Module/Install/Include.pm
      include inc/File/Copy/Recursive.pm
      *** Module::Install::Catalyst
      Please run "make catalyst_par" to create the PAR package!
      *** Module::Install::Catalyst finished.
      include inc/Module/Install/Scripts.pm
      include inc/Module/Install/AutoInstall.pm
      include inc/Module/AutoInstall.pm
      *** Module::AutoInstall version 1.06
      *** Checking for Perl dependencies...
      [Core Features]
      - Test::More                       ...loaded. (0.98 >= 0.88)
      - Catalyst::Runtime                ...loaded. (5.90015 >= 5.90015)
      - Catalyst::Plugin::ConfigLoader   ...loaded. (0.30)
      - Catalyst::Plugin::Static::Simple ...loaded. (0.30)
      - Catalyst::Action::RenderView     ...loaded. (0.16)
      - Moose                            ...loaded. (2.0401)
      - namespace::autoclean             ...loaded. (0.13)
      - Config::General                  ...loaded. (2.50)
      - Catalyst::Controller::REST       ...loaded. (1.04)
      - Catalyst::Plugin::SubRequest     ...loaded. (0.20)
      - Catalyst::View::TT               ...loaded. (0.39)
      - JSON::XS                         ...loaded. (2.32)
      - Log::Log4perl::Catalyst          ...loaded. (undef)
      - Parse::RecDescent                ...loaded. (1.965001)
      - XML::Writer                      ...loaded. (0.615)
      - Plack::Middleware::Assets        ...loaded. (0.0.2)
      - Plack::Middleware::SizeLimit     ...loaded. (0.04)
      *** Module::AutoInstall configuration finished.
      include inc/Module/Install/WriteAll.pm
      include inc/Module/Install/Win32.pm
      include inc/Module/Install/Can.pm
      include inc/Module/Install/Fetch.pm
      Writing Makefile for EnsEMBL::REST
      Writing MYMETA.yml and MYMETA.json
      Writing META.yml

++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
```

Assuming your output shown no errors your installation is good.

Secondly you should run `ping_ensembl.pl`

`perl ensembl/misc-scripts/ping_ensembl.pl`

This script checks that all Ensembl dependencies are installed and we can contact the public Ensembl MySQL instances. If `ping_ensembl.pl` returns a successful message then your installation is ready to go.

## Configuration of the REST API


### Selecting the databases to use

The API offers two methods of configuring databases; using connections specified in the `ensembl_rest.conf` file or an Ensembl Registry file. We will use the former technique as it reduces the number of configuration files required.

Open ensembl_rest.conf in a text editor & edit the `<Registry>` section as so:

```
  host = useastdb.ensembl.org
  port = 5306
  user = anonymous
```

This will tell the API to use the public databases held on our USEast server. You could have used ensembldb.ensembl.org instead which would point to our European based database servers.

### Application Debugging

Since this is your first time with the REST API you will want to configure debug messages to appear to screen as this will aid in problem solving if they occur.

Firstly open `log4perl.conf` in a text editor & edit the first line accordingly (this should, most likely, already set):

```
  log4perl.category = DEBUG, Screen
```

Secondly open lib/EnsEMBL/REST.pm and edit the module to look like the following (search for use Catalyst to find the section we need to edit):

```
  use Catalyst qw/
    -Debug
    ConfigLoader
    Static::Simple
    SubRequest
  /;
```

This will cause Catalyst to emit a lot of information about endpoints and the routing the application is performing. We recommend using the API with this mode on for your first steps.

**REMEMBER TO REMOVE THE -Debug FLAG WHEN GOING INTO PRODUCTION MODE**

### Using an alternative ensembl_rest.conf

Catalyst allows you to specify a different configuration file to the default ensembl_rest.conf file held in the root of the Rest API. This is a useful feature when in production environments. Export the location of the config file as so:

`export ENSEMBL_REST_CONFIG=$APP_HOME/path/to/other/ensembl_rest.conf`

See the following links for more information:

- https://metacpan.org/module/Catalyst::Plugin::ConfigLoader
- https://metacpan.org/module/Catalyst::Plugin::ConfigLoader::Manual

## Running The Server

### Using Catalyst's inbuilt server

```
cd ensembl-rest
./script/ensembl_rest_server.pl
```

This will start up a server with the output looking like:

```
  2012/09/05 11:01:54 (0) Catalyst.pm 1184> EnsEMBL::REST powered by Catalyst 5.90015 
  HTTP::Server::PSGI: Accepting connections at http://0:3000/
```

See "Errors & Tips", specifically lib errors, if you have any issues when starting up the server.

Navigate to the specified address and if everything has worked you should see the main REST page appearing.

### Using a PSGI/Plack server

PSGI, http://plackperl.org/, is a framework independent way of programming HTTP based frameworks. We will run the REST server using starman, https://metacpan.org/module/Starman, and a PSGI file with 5 worker threads and running on port 3000 (same as the default Catalyst port).

Starman can be installed using your system's default package management software or via cpan. Once installed you can invoke the server using the following:

```
cd ensembl-rest
PERL5LIB=$PWD/lib:$PERL5LIB starman --listen :3000 --workers 5 ensembl_rest.psgi
```

Navigate to either (depending on your machine):

- http://localhost:3000/
- http://127.0.0.1:3000/
- http://0.0.0.0:3000/

Starman also has options for production environments including hot-deploy & daemonisation of the starman process. Please see its docs for more information.

### Production

We have provided a number of example production scripts and configurations under 

- bin/production
- configurations/production

These are intended as a guide about how to run this server in a production mode and heavily use Server::Starter, https://metacpan.org/module/Server::Starter, and the Linux command start-stop-daemon.

### Running the Test Server

Ensembl REST ships with a number of test databases. It is possible to run a local server which communicates only with these databases. Firstly you must setup the test case configuration like so

```
cd ensembl-rest
cp t/MultiTestDB.conf.example t/MultiTestDB.conf
$EDITOR t/MultiTestDB.conf
# In the editor replace connection settings with more appropriate ones
# and save
```

To run execute the following

```
cd ensembl-rest
./scripts/ensembl_rest_test_server.pl
```

The script supports the same debug, restart and file watching capacities as the ensembl_rest_server.pl script. Automatic cleanup of databases will occur.


## Errors & Tips


### Speeding up ID Lookup

A precomputed MySQL schema is available on USEast called ensembl_stable_ids_?? where ?? is the Ensembl release. This database is only available on USEast. Should you want a copy locally then please take a mysqldump of the schema or run the ensembl core script:

`ensembl/misc-scripts/stable_id_lookup/populate_stable_id_lookup.pl`

Documentation on the code is available from ensembl/misc-scripts/stable_id_lookup/README.

The database supports the following IDs:

- Genes, Transcripts, Translations & Exons
- Operons & Operon Transcripts
- Gene Trees & Families (comparative genomics)

### Lib cannot be found

If you have this issue then please make sure you have run the Makefile.PL file and installed all additional libraries using your package manager of choice.

### Couldn't instantiate component "EnsEMBL::REST::Model::Registry"

This normally points to an error in your database setup. You should see a second message in the stack trace:

`"Cannot instantiate a registry. Please consult your configuration file and try again"`

Make sure your Host, Port and User attributes are set in your .conf file. If you are using a Registry file then ensure this is correctly configured and in the place it should be. If you want to use a relative path e.g. my/dir/reg.pm consider using the built-in Catalyst substitution macros. 

`reg = my/dir/reg.pm`

Becomes:

`reg = _path_to(my/dir/reg.pm)__`

More information is available from https://metacpan.org/module/Catalyst::Plugin::ConfigLoader

### More information on Catalyst

You can see these websites for more Catalyst information:

- http://www.catalystframework.org/
- https://metacpan.org/module/Catalyst
- https://metacpan.org/module/Catalyst::Manual::Intro

### Caching vs. No Caching

We normally turn caching off in our production environments as caching normally bloats processes too much and the randomness of incoming requests makes hitting subsequent caches hard. Your milage may vary so please try it both on & off.

