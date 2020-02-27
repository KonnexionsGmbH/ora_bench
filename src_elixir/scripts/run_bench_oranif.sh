#!/bin/bash

# ------------------------------------------------------------------------------
#
# run_bench_oranif.sh: Oracle Benchmark based on Elixir.
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
if [ -z "$ORA_BENCH_FILE_CONFIGURATION_NAME" ]; then
    export ORA_BENCH_FILE_CONFIGURATION_NAME=priv/properties/ora_bench.properties
fi
if [ -z "$ORA_BENCH_JAVA_CLASSPATH" ]; then
    if [ "$OSTYPE" = "msys" ]; then
        export ORA_BENCH_JAVA_CLASSPATH=".;priv/java_jar/*"
    else
        export ORA_BENCH_JAVA_CLASSPATH=".:priv/java_jar/*"
    fi
fi

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - oranif and Elixir."
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
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

EXITCODE="0"

java -cp "priv/java_jar/*" ch.konnexions.orabench.OraBench setup_elixir
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi

cd src_elixir

if [ "$ORA_BENCH_MULTIPLE_RUN" != "true" ]; then
    mix local.hex --force
    if [ $? -ne 0 ]; then
        echo "ERRORLEVEL : $?"
        exit $?
    fi
    mix deps.clean --all
    if [ $? -ne 0 ]; then
        echo "ERRORLEVEL : $?"
        exit $?
    fi
    mix deps.get
    if [ $? -ne 0 ]; then
        echo "ERRORLEVEL : $?"
        exit $?
    fi
    mix deps.compile
    if [ $? -ne 0 ]; then
        echo "ERRORLEVEL : $?"
        exit $?
    fi
fi    

mix run -e "OraBench.CLI.main([\"oranif\"])"
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi
cd ..

EXITCODE=$?

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"

exit $EXITCODE
