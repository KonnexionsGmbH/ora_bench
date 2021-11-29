#!/bin/bash

# ----------------------------------------------------------------------------------
#
# run_all_drivers.sh: Oracle benchmark for all database drivers.
#
# ----------------------------------------------------------------------------------

set -e

echo "=============================================================================="
echo "Start $0"
echo "------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - all drivers."
echo "------------------------------------------------------------------------------"
echo "RUN_CX_ORACLE_PYTHON              : ${ORA_BENCH_RUN_CX_ORACLE_PYTHON}"
echo "RUN_GODROR_GO                     : ${ORA_BENCH_RUN_GODROR_GO}"
echo "RUN_JDBC_JAVA                     : ${ORA_BENCH_RUN_JDBC_JAVA}"
echo "RUN_JDBC_JULIA                    : ${ORA_BENCH_RUN_JDBC_JULIA}"
echo "RUN_JDBC_KOTLIN                   : ${ORA_BENCH_RUN_JDBC_KOTLIN}"
echo "RUN_NIMODPI_NIM                   : ${ORA_BENCH_RUN_NIMODPI_NIM}"
echo "RUN_ODPI_C                        : ${ORA_BENCH_RUN_ODPI_C}"
echo "RUN_ORACLE_JULIA                  : ${ORA_BENCH_RUN_ORACLE_JULIA}"
echo "RUN_ORACLE_RUST                   : ${ORA_BENCH_RUN_ORACLE_RUST}"
echo "RUN_ORANIF_ELIXIR                 : ${ORA_BENCH_RUN_ORANIF_ELIXIR}"
echo "RUN_ORANIF_ERLANG                 : ${ORA_BENCH_RUN_ORANIF_ERLANG}"
echo "------------------------------------------------------------------------------"
echo "BENCHMARK_BATCH_SIZE              : ${ORA_BENCH_BENCHMARK_BATCH_SIZE}"
echo "BENCHMARK_CORE_MULTIPLIER         : ${ORA_BENCH_BENCHMARK_CORE_MULTIPLIER}"
echo "BENCHMARK_TRANSACTION_SIZE        : ${ORA_BENCH_BENCHMARK_TRANSACTION_SIZE}"
echo "------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "=============================================================================="

if [ "${ORA_BENCH_RUN_ODPI_C}" = "true" ]; then
    if ! { /bin/bash lang/c/scripts/run_bench_odpi.sh; }; then
        exit 255
    fi
fi

if [ "${ORA_BENCH_RUN_ORANIF_ELIXIR}" = "true" ]; then
    if ! { /bin/bash lang/elixir/scripts/run_bench_oranif.sh; }; then
        exit 255
    fi
fi

if [ "${ORA_BENCH_RUN_ORANIF_ERLANG}" = "true" ]; then
    if ! { /bin/bash lang/erlang/scripts/run_bench_oranif.sh; }; then
        exit 255
    fi
fi

if [ "${ORA_BENCH_RUN_GODROR_GO}" = "true" ]; then
    if ! { /bin/bash lang/go/scripts/run_bench_godror.sh; }; then
        exit 255
    fi
fi

if [ "${ORA_BENCH_RUN_JDBC_JAVA}" = "true" ]; then
    if ! { /bin/bash lang/java/scripts/run_bench_jdbc.sh; }; then
        exit 255
    fi
fi

if [ "${ORA_BENCH_RUN_JDBC_JULIA}" = "true" ]; then
    if ! { /bin/bash lang/julia/scripts/run_bench_jdbc.sh; }; then
        exit 255
    fi
fi

if [ "${ORA_BENCH_RUN_ORACLE_JULIA}" = "true" ]; then
    if ! { /bin/bash lang/julia/scripts/run_bench_oracle.sh; }; then
        exit 255
    fi
fi

if [ "${ORA_BENCH_RUN_JDBC_KOTLIN}" = "true" ]; then
    if ! { /bin/bash lang/kotlin/scripts/run_bench_jdbc.sh; }; then
        exit 255
    fi
fi

if [ "${ORA_BENCH_RUN_NIMODPI_NIM}" = "true" ]; then
    if ! { /bin/bash lang/nim/scripts/run_bench_nimodpi.sh; }; then
        exit 255
    fi
fi

if [ "${ORA_BENCH_RUN_CX_ORACLE_PYTHON}" = "true" ]; then
    if ! { /bin/bash lang/python/scripts/run_bench_cx_oracle.sh; }; then
        exit 255
    fi
fi

if [ "${ORA_BENCH_RUN_ORACLE_RUST}" = "true" ]; then
    if ! { /bin/bash lang/rust/scripts/run_bench_oracle.sh; }; then
        exit 255
    fi
fi

if ! [ "${ORA_BENCH_CHOICE_DRIVER}" = "none" ]; then
    if ! { /bin/bash scripts/run_finalise_benchmark.sh; }; then
        exit 255
    fi
fi

echo ""
echo "------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "------------------------------------------------------------------------------"
echo "End   $0"
echo "=============================================================================="
