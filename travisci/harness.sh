#!/bin/bash

export PERL5LIB=$PERL5LIB:$ENSDIR/ensembl-test/modules:$ENSDIR/ensembl/modules:$ENSDIR/ensembl-compara/modules:$ENSDIR/ensembl-variation/modules:$ENSDIR/ensembl-vep/modules:$ENSDIR/ensembl-funcgen/modules:$ENSDIR/ensembl-io/modules:$TRAVIS_BUILD_DIR/lib

export TEST_AUTHOR=$USER

export PATH=$PATH:$ENSDIR/share/htslib/bin:$ENSDIR/ensembl-variation/C_code
export SKIP_TESTS=""

echo "Running test suite"
if [ "$COVERALLS" = 'true' ]; then
  PERL5OPT='-MDevel::Cover' perl $ENSDIR/ensembl-test/scripts/runtests.pl t $SKIP_TESTS
else
  perl $ENSDIR/ensembl-test/scripts/runtests.pl t $SKIP_TESTS
fi

rt=$?
if [ $rt -eq 0 ]; then
  if [ "$COVERALLS" = 'true' ]; then
    echo "Running Devel::Cover coveralls report"
    cover --nosummary -report coveralls
  fi
  exit $?
else
  exit $rt
fi
