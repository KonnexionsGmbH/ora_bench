#!/bin/bash

# ------------------------------------------------------------------------------
#
# run_bench_java.sh: Oracle Benchmark based on Java.
#
# ------------------------------------------------------------------------------

if [ -z "$ORA_BENCH_JAVA_CLASSPATH" ]; then
    export ORA_BENCH_JAVA_CLASSPATH=".;priv/java_jar/*"
fi
if [ -z "$ORA_BENCH_FILE_CONFIGURATION_NAME" ]; then
    export ORA_BENCH_FILE_CONFIGURATION_NAME=priv/ora_bench.properties
    make -f java_src/Makefile clean
    make -f java_src/Makefile
fi

EXITCODE="0"

PATH=$PATH:/u01/app/oracle/product/12.2/db_1/jdbc/lib

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Java."
echo "--------------------------------------------------------------------------------"
date +"DATE TIME          : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

java -cp "priv/java_jar/*" ch.konnexions.orabench.OraBench runBenchmark

EXITCODE=$?

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME          : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"

exit $EXITCODE
