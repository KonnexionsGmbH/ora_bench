#!/bin/bash

# ------------------------------------------------------------------------------
#
# run_bench_setup.sh: Oracle Benchmark Run Setup.
#
# ------------------------------------------------------------------------------

if [ -z "$ORA_BENCH_FILE_CONFIGURATION_NAME" ]; then
    export ORA_BENCH_FILE_CONFIGURATION_NAME=priv/properties/ora_bench.properties
fi
if [ -z "$ORA_BENCH_JAVA_CLASSPATH" ]; then
    export ORA_BENCH_JAVA_CLASSPATH=".;priv/java_jar/*"
fi

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - setup benchmark run."
echo "--------------------------------------------------------------------------------"
echo "FILE_CONFIGURATION_NAME : $ORA_BENCH_FILE_CONFIGURATION_NAME"
echo "JAVA_CLASSPATH          : $ORA_BENCH_JAVA_CLASSPATH"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

EXITCODE="0"

PATH=$PATH:/u01/app/oracle/product/12.2/db_1/jdbc/lib

make -f src_java/Makefile clean
make -f src_java/Makefile

java -cp "priv/java_jar/*" ch.konnexions.orabench.OraBench setup

EXITCODE=$?

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"

exit $EXITCODE
