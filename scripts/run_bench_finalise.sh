#!/bin/bash

# ------------------------------------------------------------------------------
#
# run_bench_finalise.sh: Oracle Benchmark Run Finalise.
#
# ------------------------------------------------------------------------------

if [ -z "$ORA_BENCH_JAVA_CLASSPATH" ]; then
    export ORA_BENCH_JAVA_CLASSPATH=".;priv/java_jar/*"
fi

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - finalise benchmark run."
echo "--------------------------------------------------------------------------------"
echo "JAVA_CLASSPATH          : $ORA_BENCH_JAVA_CLASSPATH"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

EXITCODE="0"

make -f java_src/Makefile clean
make -f java_src/Makefile

java -cp "priv/java_jar/*" ch.konnexions.orabench.OraBench finalise

EXITCODE=$?

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"

exit $EXITCODE
