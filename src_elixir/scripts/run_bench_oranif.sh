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
    export ORA_BENCH_CONNECTION_HOST=ora_bench_db
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
        export ORA_BENCH_JAVA_CLASSPATH=".;priv/libs/*"
    else
        export ORA_BENCH_JAVA_CLASSPATH=".:priv/libs/*"
    fi
fi

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - oranif and Elixir."
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
echo "JAVA_CLASSPATH             : $ORA_BENCH_JAVA_CLASSPATH"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

if [ "$ORA_BENCH_MULTIPLE_RUN" != "true" ]; then
    if ! { /bin/bash src_java/scripts/run_gradle.sh; }; then
        exit 255
    fi

    if ! java -cp "$ORA_BENCH_JAVA_CLASSPATH" ch.konnexions.orabench.OraBench setup_elixir; then
        exit 255
    fi
fi    

(
    cd src_elixir || exit 255
    
    if [ -f "mix.lock" ]; then
        rm -f mix.lock
    fi         
    if [ -f "deps" ]; then
        rm -rf deps
    fi         

    if [ "$ORA_BENCH_MULTIPLE_RUN" != "true" ]; then
        if ! mix local.hex --force; then
            exit 255
        fi
        
        if ! mix deps.clean --all; then
            exit 255
        fi
        if ! mix deps.get; then
            exit 255
        fi
        if ! mix deps.compile; then
            exit 255
        fi
    fi    
    
    if ! mix run -e "OraBench.CLI.main([\"oranif\"])"; then
        exit 255
    fi
)

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"
