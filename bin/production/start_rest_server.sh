#!/bin/bash -ex
# Copyright [1999-2013] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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

exec > >(tee /var/log/rest-server-start.log|logger -t rest-server-start -s 2>/dev/console) 2>&1


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PORT=5000
# This should be the directory name/app name
APP="perl5/ensembl-rest"
PIDFILE="$HOME/$APP.pid"
STATUS="$HOME/$APP.status"

export HOME=/home/ubuntu
export ENS_CVS_ROOT_DIR=$HOME/perl5/ensembl-api
if [ -z "$ENS_CVS_ROOT_DIR" ]; then
  export ENS_CVS_ROOT_DIR=$(cd $SCRIPT_DIR/../../../ && pwd)
fi

# The actual path on disk to the application.
APP_HOME=$(cd $SCRIPT_DIR/../../ && pwd)

# Library path work
for ensdir in ensembl-variation ensembl-functgenomics ensembl-compara ensembl; do
  PERL5LIB=$ENS_CVS_ROOT_DIR/$ensdir/modules:$PERL5LIB
done
PERL5LIB=$APP_HOME/../bioperl-live:$PERL5LIB
PERL5LIB=$APP_HOME/lib:$PERL5LIB
export PERL5LIB

. $HOME/perl5/perlbrew/etc/bashrc

export ENS_REST_LOG4PERL=$APP_HOME'/configurations/production/log4perl.conf'

# Server settings for starman
WORKERS=15
BACKLOG=1024
MAXREQUESTS=10000
RESTART_INTERVAL=1

# This is only relevant if using Catalyst
TDP_HOME="$HOME/$APP"
export TDP_HOME

ERROR_LOG="$HOME/logs/$APP.error.log"
ACCESS_LOG="$HOME/logs/$APP.access.log"

export ENSEMBL_REST_CONFIG=$APP_HOME/configurations/production/ensembl_rest.conf
STARMAN="starman --backlog $BACKLOG --max-requests $MAXREQUESTS --workers $WORKERS --access-log $ACCESS_LOG --error-log $ERROR_LOG $APP_HOME/configurations/production/ensrest.psgi"
DAEMON="$HOME/perl5/perlbrew/perls/perl-5.14.2/bin/start_server"
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
