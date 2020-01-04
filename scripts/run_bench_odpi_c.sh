#!/bin/bash

# ------------------------------------------------------------------------------
#
# run_bench_odpi_c.sh: Oracle Benchmark based on ODPI-C.
#
# ------------------------------------------------------------------------------

if [ -z "$ORA_BENCH_BENCHMARK_DATABASE" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_19_3_ee
fi
if [ -z "$ORA_BENCH_CONNECTION_HOST" ]; then
    export ORA_BENCH_CONNECTION_HOST=0.0.0.0
fi
if [ -z "$ORA_BENCH_CONNECTION_PORT" ]; then
    export ORA_BENCH_CONNECTION_PORT=1521
fi
if [ -z "$ORA_BENCH_CONNECTION_SERVICE" ]; then
    export ORA_BENCH_CONNECTION_SERVICE=orclpdb1
fi
if [ -z "$ORA_BENCH_JAVA_CLASSPATH" ]; then
    export ORA_BENCH_JAVA_CLASSPATH=".;priv/java_jar/*"
fi

if [ -z "$ORA_BENCH_FILE_CONFIGURATION_NAME" ]; then
    export ORA_BENCH_FILE_CONFIGURATION_NAME=priv/properties/ora_bench.properties
fi

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - ODPI-C."
echo "--------------------------------------------------------------------------------"
echo "BENCHMARK_DATABASE      : $ORA_BENCH_BENCHMARK_DATABASE"
echo "CONNECTION_HOST         : $ORA_BENCH_CONNECTION_HOST"
echo "CONNECTION_PORT         : $ORA_BENCH_CONNECTION_PORT"
echo "CONNECTION_SERVICE      : $ORA_BENCH_CONNECTION_SERVICE"
echo "FILE_CONFIGURATION_NAME : $ORA_BENCH_FILE_CONFIGURATION_NAME"
echo "JAVA_CLASSPATH          : $ORA_BENCH_JAVA_CLASSPATH"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

EXITCODE="0"

java -cp "priv/java_jar/*" ch.konnexions.orabench.OraBench setup_odpic

if [ "$OSTYPE" = "msys" ]; then
    nmake -f src_c/Makefile.win32 clean
    nmake -f src_c/Makefile.win32
    ./OraBench.exe priv/properties/ora_bench_odpi_c.properties
else
    make -f src_c/Makefile clean
    make -f src_c/Makefile
   ./OraBench priv/properties/ora_bench_odpi_c.properties
fi

EXITCODE=$?

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"

exit $EXITCODE
