#!/bin/bash

# ----------------------------------------------------------------------------------
#
# run_bench_oranif.sh: Oracle Benchmark based on Erlang.
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
export ORA_BENCH_FILE_CONFIGURATION_NAME_ERLANG=priv/properties/ora_bench_erlang.properties

echo "=============================================================================="
echo "Start $0"
echo "------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - oranif and Erlang."
echo "------------------------------------------------------------------------------"
echo "MULTIPLE_RUN                   : ${ORA_BENCH_MULTIPLE_RUN}"
echo "------------------------------------------------------------------------------"
echo "BENCHMARK_DATABASE             : ${ORA_BENCH_BENCHMARK_DATABASE}"
echo "CONNECTION_HOST                : ${ORA_BENCH_CONNECTION_HOST}"
echo "CONNECTION_PORT                : ${ORA_BENCH_CONNECTION_PORT}"
echo "CONNECTION_SERVICE             : ${ORA_BENCH_CONNECTION_SERVICE}"
echo "------------------------------------------------------------------------------"
echo "BENCHMARK_BATCH_SIZE           : ${ORA_BENCH_BENCHMARK_BATCH_SIZE}"
echo "BENCHMARK_CORE_MULTIPLIER      : ${ORA_BENCH_BENCHMARK_CORE_MULTIPLIER}"
echo "BENCHMARK_TRANSACTION_SIZE     : ${ORA_BENCH_BENCHMARK_TRANSACTION_SIZE}"
echo "------------------------------------------------------------------------------"
echo "FILE_CONFIGURATION_NAME        : ${ORA_BENCH_FILE_CONFIGURATION_NAME}"
echo "FILE_CONFIGURATION_NAME_ERLANG : ${ORA_BENCH_FILE_CONFIGURATION_NAME_ERLANG}"
echo "------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "=============================================================================="

if [ "${ORA_BENCH_MULTIPLE_RUN}" != "true" ]; then
    cd lang/erlang || exit 255

    if [ -d "_build" ]; then
        rm -rf _build
    fi

    if ! rebar3 steamroll; then
        exit 255
    fi

    if ! rebar3 escriptize; then
        exit 255
    fi

    cd ../..
  
    if ! { /bin/bash lang/java/scripts/run_gradle.sh; }; then
        exit 255
    fi
    
    if ! java -jar priv/libs/ora_bench_java.jar setup_erlang; then
        exit 255
    fi
fi    

if ! lang/erlang/_build/default/bin/orabench ${ORA_BENCH_FILE_CONFIGURATION_NAME_ERLANG}; then
    exit 255
fi

echo ""
echo "------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "------------------------------------------------------------------------------"
echo "End   $0"
echo "=============================================================================="
