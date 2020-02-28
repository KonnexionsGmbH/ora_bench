#!/bin/bash

# ------------------------------------------------------------------------------
#
# run_bench_odpi.sh: Oracle Benchmark based on ODPI-C.
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
echo "MULTIPLE_RUN               : $ORA_BENCH_MULTIPLE_RUN"
echo "BENCHMARK_DATABASE         : $ORA_BENCH_BENCHMARK_DATABASE"
echo "CONNECTION_HOST            : $ORA_BENCH_CONNECTION_HOST"
echo "CONNECTION_PORT            : $ORA_BENCH_CONNECTION_PORT"
echo "CONNECTION_SERVICE         : $ORA_BENCH_CONNECTION_SERVICE"
echo "--------------------------------------------------------------------------------"
echo "BENCHMARK_BATCH_SIZE       : $ORA_BENCH_BENCHMARK_BATCH_SIZE"
echo "BENCHMARK_CORE_MULTIPLIER  : $ORA_BENCH_BENCHMARK_CORE_MULTIPLIER"
echo "BENCHMARK_TRANSACTION_SIZE : $ORA_BENCH_BENCHMARK_TRANSACTION_SIZE"
echo "--------------------------------------------------------------------------------"
echo "FILE_CONFIGURATION_NAME    : $ORA_BENCH_FILE_CONFIGURATION_NAME"
echo "JAVA_CLASSPATH             : $ORA_BENCH_JAVA_CLASSPATH"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

EXITCODE="0"

if [ "$ORA_BENCH_MULTIPLE_RUN" != "true" ]; then
    if [ "$OSTYPE" = "msys" ]; then
        nmake -f src_c/Makefile.win32 clean
        if [ $? -ne 0 ]; then
            echo "ERRORLEVEL : $?"
            exit $?
        fi
        nmake -f src_c/Makefile.win32
    else
        make -f src_c/Makefile clean
        if [ $? -ne 0 ]; then
            echo "ERRORLEVEL : $?"
            exit $?
        fi
        make -f src_c/Makefile
    fi
    if [ $? -ne 0 ]; then
        echo "ERRORLEVEL : $?"
        exit $?
    fi
fi

java -cp "priv/java_jar/*" ch.konnexions.orabench.OraBench setup_c
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi

if [ "$OSTYPE" = "msys" ]; then
    ./OraBench.exe priv/properties/ora_bench_c.properties
else
   ./OraBench priv/properties/ora_bench_c.properties
fi
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi

EXITCODE=$?

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"

exit $EXITCODE
