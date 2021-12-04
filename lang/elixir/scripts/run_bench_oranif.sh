#!/bin/bash

# ----------------------------------------------------------------------------------
#
# run_bench_oranif.sh: Oracle Benchmark based on Elixir.
#
# ----------------------------------------------------------------------------------


export ORA_BENCH_BENCHMARK_DATABASE_DEFAULT=db_21_3
export ORA_BENCH_CONNECTION_HOST_DEFAULT=localhost
export ORA_BENCH_CONNECTION_PORT_DEFAULT=1521
export ORA_BENCH_CONNECTION_SERVICE_DEFAULT=orclpdb1
export ORA_BENCH_PASSWORD_SYS_DEFAULT=oracle

if [ -z "${ORA_BENCH_BENCHMARK_DATABASE}" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=${ORA_BENCH_BENCHMARK_DATABASE_DEFAULT}
fi
if [ -z "${ORA_BENCH_CONNECTION_HOST}" ]; then
    export ORA_BENCH_CONNECTION_HOST=${ORA_BENCH_CONNECTION_HOST_DEFAULT}
fi
if [ -z "${ORA_BENCH_CONNECTION_PORT}" ]; then
    export ORA_BENCH_CONNECTION_PORT=${ORA_BENCH_CONNECTION_PORT_DEFAULT}
fi
if [ -z "${ORA_BENCH_CONNECTION_SERVICE}" ]; then
    export ORA_BENCH_CONNECTION_SERVICE=${ORA_BENCH_CONNECTION_SERVICE_DEFAULT}
fi
if [ -z "${ORA_BENCH_PASSWORD_SYS}" ]; then
    export ORA_BENCH_PASSWORD_SYS=${ORA_BENCH_PASSWORD_SYS_DEFAULT}
fi

export ORA_BENCH_FILE_CONFIGURATION_NAME=priv/properties/ora_bench.properties

echo "=============================================================================="
echo "Start $0"
echo "------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - oranif and Elixir."
echo "------------------------------------------------------------------------------"
echo "MULTIPLE_RUN               : ${ORA_BENCH_MULTIPLE_RUN}"
echo "------------------------------------------------------------------------------"
echo "BENCHMARK_DATABASE         : ${ORA_BENCH_BENCHMARK_DATABASE}"
echo "CONNECTION_HOST            : ${ORA_BENCH_CONNECTION_HOST}"
echo "CONNECTION_PORT            : ${ORA_BENCH_CONNECTION_PORT}"
echo "CONNECTION_SERVICE         : ${ORA_BENCH_CONNECTION_SERVICE}"
echo "------------------------------------------------------------------------------"
echo "BENCHMARK_BATCH_SIZE       : ${ORA_BENCH_BENCHMARK_BATCH_SIZE}"
echo "BENCHMARK_CORE_MULTIPLIER  : ${ORA_BENCH_BENCHMARK_CORE_MULTIPLIER}"
echo "BENCHMARK_TRANSACTION_SIZE : ${ORA_BENCH_BENCHMARK_TRANSACTION_SIZE}"
echo "------------------------------------------------------------------------------"
echo "FILE_CONFIGURATION_NAME    : ${ORA_BENCH_FILE_CONFIGURATION_NAME}"
echo "------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "=============================================================================="

if [ "${ORA_BENCH_MULTIPLE_RUN}" != "true" ]; then
    cd lang/elixir || exit 255

    if [ -f "mix.lock" ]; then
        if ! rm -f mix.lock; then
            exit 255
        fi
    fi

    if [ -f "deps" ]; then
        if ! rm -rf deps; then
            exit 255
        fi
    fi

    if ! mix local.hex --force; then
        exit 255
    fi
    
    if ! mix local.rebar --force; then
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

    cd ../..

    if ! { /bin/bash lang/java/scripts/run_gradle.sh; }; then
        exit 255
    fi

    if ! java -jar priv/libs/ora_bench_java.jar setup_elixir; then
        exit 255
    fi
fi
    
cd lang/elixir || exit 255

if ! mix run -e "OraBench.CLI.main([\"oranif\"])"; then
    exit 255
fi

cd ../..

echo ""
echo "------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "------------------------------------------------------------------------------"
echo "End   $0"
echo "=============================================================================="
