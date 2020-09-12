#!/bin/bash

# ------------------------------------------------------------------------------
#
# run_bench_cx_oracle.sh: Oracle Benchmark based on Python.
#
# ------------------------------------------------------------------------------

if [ -z "$ORA_BENCH_BENCHMARK_DATABASE" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_19_3_ee
fi
if [ -z "$ORA_BENCH_CONNECTION_HOST" ]; then
    export javaORA_BENCH_CONNECTION_HOST=localhost
fi
if [ -z "$ORA_BENCH_CONNECTION_PORT" ]; then
    export ORA_BENCH_CONNECTION_PORT=1521
fi
if [ -z "$ORA_BENCH_CONNECTION_SERVICE" ]; then
    export ORA_BENCH_CONNECTION_SERVICE=orclpdb1
fi

if [ -z "$ORA_BENCH_FILE_CONFIGURATION_NAME" ]; then
    export ORA_BENCH_FILE_CONFIGURATION_NAME=priv/properties/ora_bench.properties
fi

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - cx_Oracle and Python."
echo "--------------------------------------------------------------------------------"
echo "MULTIPLE_RUN               : $ORA_BENCH_MULTIPLE_RUN"
echo "--------------------------------------------------------------------------------"
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
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

if [ "$ORA_BENCH_MULTIPLE_RUN" != "true" ]; then
    if ! { /bin/bash src_java/scripts/run_gradle.sh; }; then
        exit 255
    fi

    if ! java -jar priv/libs/ora_bench_java.jar setup_python; then
        exit 255
    fi
fi

if [ "$OSTYPE" = "msys" ]; then
    if ! python src_python/OraBench.py; then
        exit 255
    fi
else
    if ! python3 src_python/OraBench.py; then
        exit 255
    fi
fi

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"
