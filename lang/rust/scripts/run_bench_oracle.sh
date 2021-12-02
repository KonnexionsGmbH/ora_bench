#!/bin/bash

# ----------------------------------------------------------------------------------
#
# run_bench_oracle.sh: Oracle Benchmark based on Rust.
#
# ----------------------------------------------------------------------------------

if [ -z "${ORA_BENCH_BENCHMARK_DATABASE}" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_21_3_xe
fi
if [ -z "${ORA_BENCH_CONNECTION_HOST}" ]; then
    export ORA_BENCH_CONNECTION_HOST=localhost
fi
if [ -z "${ORA_BENCH_CONNECTION_PORT}" ]; then
    export ORA_BENCH_CONNECTION_PORT=1521
fi
if [ -z "${ORA_BENCH_CONNECTION_SERVICE}" ]; then
    export ORA_BENCH_CONNECTION_SERVICE=orclpdb1
fi

export ORA_BENCH_FILE_CONFIGURATION_NAME=priv/properties/ora_bench.properties

export ORA_BENCH_RUST_LOG_LEVEL=debug
export ORA_BENCH_RUST_LOG_LEVEL=info

echo "=============================================================================="
echo "Start $0"
echo "------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - Rust-oracle and Rust."
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
echo "RUST_LOG_LEVEL             : ${ORA_BENCH_RUST_LOG_LEVEL}"
echo "------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "=============================================================================="

if [ "${ORA_BENCH_MULTIPLE_RUN}" != "true" ]; then
    if ! make -C lang/rust; then
        exit 255
    fi
    
    if ! { /bin/bash lang/java/scripts/run_gradle.sh; }; then
        exit 255
    fi

    if ! java -jar priv/libs/ora_bench_java.jar setup_default; then
      exit 255
    fi
fi

if ! cargo run --manifest-path lang/rust/Cargo.toml --release ${ORA_BENCH_FILE_CONFIGURATION_NAME}; then
    exit 255
fi

echo ""
echo "------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "------------------------------------------------------------------------------"
echo "End   $0"
echo "=============================================================================="
