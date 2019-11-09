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

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - Java."
echo "--------------------------------------------------------------------------------"
echo "BENCHMARK_COMMENT  : $ORA_BENCH_BENCHMARK_COMMENT"
echo "BENCHMARK_DATABASE : $ORA_BENCH_BENCHMARK_DATABASE"
echo "CONNECTION_HOST    : $ORA_BENCH_CONNECTION_HOST"
echo "CONNECTION_PORT    : $ORA_BENCH_CONNECTION_PORT"
echo "CONNECTION_SERVICE : $ORA_BENCH_CONNECTION_SERVICE"
echo "JAVA_CLASSPATH     : $ORA_BENCH_JAVA_CLASSPATH"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

EXITCODE="0"

PATH=$PATH:/u01/app/oracle/product/12.2/db_1/jdbc/lib

java -cp "priv/java_jar/*" ch.konnexions.orabench.OraBench runBenchmark

EXITCODE=$?

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"

exit $EXITCODE
