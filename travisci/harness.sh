#!/bin/bash

export PERL5LIB=$PWD/bioperl-live:$PWD/ensembl-test/modules:$PWD/ensembl/modules:$PWD/ensembl-compara/modules:$PWD/ensembl-variation/modules:$PWD/ensembl-funcgen/modules:$PWD/ensembl-io/modules:$PWD/lib:$PWD/Bio-HTS/lib:$PWD/Bio-HTS/blib/arch/auto/Bio/DB/HTS/Faidx:$PWD/Bio-HTS/blib/arch/auto/Bio/DB/HTS

export PATH=$PATH:$PWD/tabix:$PWD/ensembl-variation/C_code
export SKIP_TESTS=""

echo "Running test suite"
if [ "$COVERALLS" = 'true' ]; then
  PERL5OPT='-MDevel::Cover=+ignore,bioperl,+ignore,ensembl-test' perl $PWD/ensembl-test/scripts/runtests.pl -verbose t $SKIP_TESTS
else
  perl $PWD/ensembl-test/scripts/runtests.pl t $SKIP_TESTS
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
