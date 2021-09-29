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
echo "RUN_JDBC_JL_JULIA                 : ${ORA_BENCH_RUN_JDBC_JL_JULIA}"
echo "RUN_JDBC_KOTLIN                   : ${ORA_BENCH_RUN_JDBC_KOTLIN}"
echo "RUN_ODPI_C                        : ${ORA_BENCH_RUN_ODPI_C}"
echo "RUN_ORACLE_JL_JULIA               : ${ORA_BENCH_RUN_ORACLE_JL_JULIA}"
echo "RUN_ORANIF_ELIXIR                 : ${ORA_BENCH_RUN_ORANIF_ELIXIR}"
echo "RUN_ORANIF_ERLANG                 : ${ORA_BENCH_RUN_ORANIF_ERLANG}"
echo "------------------------------------------------------------------------------"
echo "BATCH_SIZE                        : ${ORA_BENCH_BATCH_SIZE}"
echo "CORE_MULTIPLIER                   : ${ORA_BENCH_CORE_MULTIPLIER}"
echo "TRANSACTION_SIZE                  : ${ORA_BENCH_TRANSACTION_SIZE}"
echo "------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "=============================================================================="

if [ "${ORA_BENCH_RUN_CX_ORACLE_PYTHON}" = "true" ]; then
    if ! { /bin/bash lang/python/scripts/run_bench_cx_oracle.sh; }; then
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

if [ "${ORA_BENCH_RUN_JDBC_JL_JULIA}" = "true" ]; then
    if ! { /bin/bash lang/julia/scripts/run_bench_jdbc_jl.sh; }; then
        exit 255
    fi
fi

if [ "${ORA_BENCH_RUN_JDBC_KOTLIN}" = "true" ]; then
    if ! { /bin/bash lang/kotlin/scripts/run_bench_jdbc.sh; }; then
        exit 255
    fi
fi

if [ "${ORA_BENCH_RUN_ODPI_C}" = "true" ]; then
    if ! { /bin/bash lang/c/scripts/run_bench_odpi.sh; }; then
        exit 255
    fi
fi

if [ "${ORA_BENCH_RUN_ORACLE_JL_JULIA}" = "true" ]; then
    if ! { /bin/bash lang/julia/scripts/run_bench_oracle_jl.sh; }; then
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
