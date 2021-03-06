#!/bin/bash

# ------------------------------------------------------------------------------
#
# run_bench_all_drivers.sh: Oracle benchmark for all database drivers.
#
# ------------------------------------------------------------------------------

set -e

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - all drivers."
echo "--------------------------------------------------------------------------------"
echo "RUN_CX_ORACLE_PYTHON              : $ORA_BENCH_RUN_CX_ORACLE_PYTHON"
echo "RUN_JDBC_KOTLIN                   : $ORA_BENCH_RUN_JDBC_KOTLIN"
echo "RUN_GODROR_GO                     : $ORA_BENCH_RUN_GODROR_GO"
echo "RUN_JDBC_JAVA                     : $ORA_BENCH_RUN_JDBC_JAVA"
echo "RUN_ODPI_C                        : $ORA_BENCH_RUN_ODPI_C"
echo "RUN_ORANIF_ELIXIR                 : $ORA_BENCH_RUN_ORANIF_ELIXIR"
echo "RUN_ORANIF_ERLANG                 : $ORA_BENCH_RUN_ORANIF_ERLANG"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

if [ "$ORA_BENCH_RUN_GODROR_GO" = "true" ]; then
    if ! { /bin/bash src_go/scripts/run_bench_godror.sh; }; then
        exit 255
    fi
fi

if [ "$ORA_BENCH_RUN_CX_ORACLE_PYTHON" = "true" ]; then
    if ! { /bin/bash src_python/scripts/run_bench_cx_oracle.sh; }; then
        exit 255
    fi
fi

if [ "$ORA_BENCH_RUN_JDBC_JAVA" = "true" ]; then
    if ! { /bin/bash src_java/scripts/run_bench_jdbc.sh; }; then
        exit 255
    fi
fi

if [ "$ORA_BENCH_RUN_JDBC_KOTLIN" = "true" ]; then
    if ! { /bin/bash src_kotlin/scripts/run_bench_jdbc.sh; }; then
        exit 255
    fi
fi

if [ "$ORA_BENCH_RUN_ODPI_C" = "true" ]; then
    if ! { /bin/bash src_c/scripts/run_bench_odpi.sh; }; then
        exit 255
    fi
fi

if [ "$ORA_BENCH_RUN_ORANIF_ELIXIR" = "true" ]; then
    if ! { /bin/bash src_elixir/scripts/run_bench_oranif.sh; }; then
        exit 255
    fi
fi

if [ "$ORA_BENCH_RUN_ORANIF_ERLANG" = "true" ]; then
    if ! { /bin/bash src_erlang/scripts/run_bench_oranif.sh; }; then
        exit 255
    fi
fi

if ! { /bin/bash scripts/run_finalise_benchmark.sh; }; then
    exit 255
fi

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"
