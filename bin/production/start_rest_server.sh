#!/bin/bash -ex
# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
# Copyright [2016-2025] EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# {mark} Ansible Perl Paths

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PORT=5000
if ["$REST_PORT"]; then
  PORT=$REST_PORT
fi
# This should be the directory name/app name
APP="perl5/ensembl-rest"
PIDFILE="$HOME/$APP.pid"
STATUS="$HOME/$APP.status"

export ENS_GIT_ROOT_DIR=$HOME/src
if [ -z "$ENS_GIT_ROOT_DIR" ]; then
  export ENS_GIT_ROOT_DIR=$(cd $SCRIPT_DIR/../../../ && pwd)
fi

# The actual path on disk to the application.
APP_HOME=$(cd $SCRIPT_DIR/../../ && pwd)

# Library path work
for ensdir in ensembl-variation ensembl-funcgen ensembl-compara ensembl ensembl-io; do
  PERL5LIB=$ENS_GIT_ROOT_DIR/$ensdir/modules:$PERL5LIB
  if [ ! -d "$ensdir" ];
  then
    echo "One of your paths does not exist: "
    echo "ERROR: $ensdir "
  fi
done
PERL5LIB=$APP_HOME/../bioperl-live:$PERL5LIB
PERL5LIB=$APP_HOME/../Bio-HTS/blib/arch:$APP_HOME/../Bio-HTS/blib/lib:$PERL5LIB
PERL5LIB=$APP_HOME/lib:$PERL5LIB
export PERL5LIB

. $HOME/perl5/perlbrew/etc/bashrc

export ENS_REST_LOG4PERL=$APP_HOME'/configurations/production/log4perl.conf'
#export PROGRESSIVE_CACTUS_DIR=${HOME}/src/progressiveCactus/
#export COMPARA_HAL_DIR=/mnt/shared/88/
#export PERL5LIB=$PERL5LIB:/home/ubuntu/src/ensembl-compara/modules/Bio/EnsEMBL/Compara/HAL/HALXS/blib/arch/auto

# Server settings for starman
WORKERS=10
BACKLOG=1024
MAXREQUESTS=10000
RESTART_INTERVAL=1

# This is only relevant if using Catalyst
TDP_HOME="$HOME/$APP"
export TDP_HOME
#export PROGRESSIVE_CACTUS_DIR="$HOME/src/progressiveCactus/"

export ENSEMBL_REST_CONFIG=$APP_HOME/configurations/production/ensembl_rest.conf
STARMAN="starman --backlog $BACKLOG --max-requests $MAXREQUESTS --workers $WORKERS $APP_HOME/configurations/production/ensrest.psgi"
DAEMON="$HOME/perl5/perlbrew/perls/perl-5.14.2/bin/start_server"
# Maintain existing Embassy configuration for now, only
# go for the system start_server if we can't find the one we
# know and love. Flip this around as we get closer to deploying
# on EBI hardware
if [ ! -f "$DAEMON" ]
then
    DAEMON=$(which start_server)
fi
DAEMON_OPTS="--pid-file=$PIDFILE --interval=$RESTART_INTERVAL --status-file=$STATUS --port 0.0.0.0:$PORT -- $STARMAN"

cd $APP_HOME
echo "Current working directory is " $(pwd)

# Here you could even do something like this to ensure deps are there:
# cpanm --installdeps .

res=1
if [ -f $PIDFILE ]; then
        echo "Found the file $PIDFILE; attempting a restart"
        echo "$DAEMON --restart $DAEMON_OPTS"
        $DAEMON --restart $DAEMON_OPTS
        res=$?
fi

# If the restart failed (2 or 3) then try again. We could put in a kill.
if [ $res -gt 0 ]; then
    echo "Application likely not running. Starting..."
    # Rely on start-stop-daemon to run start_server in the background
    # The PID will be written by start_server
    /sbin/start-stop-daemon --start --background  \
                -d $APP_HOME --exec "$DAEMON" -- $DAEMON_OPTS
fi
