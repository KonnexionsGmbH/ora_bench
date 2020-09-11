#!/bin/bash

# ------------------------------------------------------------------------------
#
# run_bench_all_drivers.sh: Oracle benchmark for all database drivers.
#
# ------------------------------------------------------------------------------

set -e

if [ -z "$ORA_BENCH_RUN_CX_ORACLE_PYTHON" ]; then
    export ORA_BENCH_RUN_CX_ORACLE_PYTHON=true
fi
if [ -z "$ORA_BENCH_RUN_JDBC_KOTLIN" ]; then
    export ORA_BENCH_RUN_JDBC_KOTLIN=true
fi
if [ -z "$ORA_BENCH_RUN_GODROR_GO" ]; then
    export ORA_BENCH_RUN_GODROR_GO=true
fi
if [ -z "$ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG" ]; then
    export ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG=true
fi
if [ -z "$ORA_BENCH_RUN_JDBC_JAVA" ]; then
    export ORA_BENCH_RUN_JDBC_JAVA=true
fi
if [ -z "$ORA_BENCH_RUN_ODPI_C" ]; then
    export ORA_BENCH_RUN_ODPI_C=true
fi
if [ -z "$ORA_BENCH_RUN_ORANIF_ELIXIR" ]; then
    export ORA_BENCH_RUN_ORANIF_ELIXIR=true
fi
if [ -z "$ORA_BENCH_RUN_ORANIF_ERLANG" ]; then
    export ORA_BENCH_RUN_ORANIF_ERLANG=true
fi

if [ "$ORA_BENCH_BENCHMARK_JAMDB" = "" ]; then
    export RUN_GLOBAL_JAMDB=true
    export RUN_GLOBAL_NON_JAMDB=true
fi
if [ "$ORA_BENCH_BENCHMARK_JAMDB" = "false" ]; then
    export RUN_GLOBAL_JAMDB=false
    export RUN_GLOBAL_NON_JAMDB=true
fi
if [ "$ORA_BENCH_BENCHMARK_JAMDB" = "true" ]; then
    export RUN_GLOBAL_JAMDB=true
    export RUN_GLOBAL_NON_JAMDB=false
fi

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - all drivers."
echo "--------------------------------------------------------------------------------"
echo "MULTIPLE_RUN               : $ORA_BENCH_MULTIPLE_RUN"
echo "--------------------------------------------------------------------------------"
echo "ORA_BENCH_BENCHMARK_JAMDB  : $ORA_BENCH_BENCHMARK_JAMDB"
echo "RUN_GLOBAL_JAMDB           : $RUN_GLOBAL_JAMDB"
echo "RUN_GLOBAL_NON_JAMDB       : $RUN_GLOBAL_NON_JAMDB"
echo "--------------------------------------------------------------------------------"
echo "RUN_CX_ORACLE_PYTHON       : $ORA_BENCH_RUN_CX_ORACLE_PYTHON"
echo "RUN_JDBC_KOTLIN         : $ORA_BENCH_RUN_JDBC_KOTLIN"
echo "RUN_GODROR_GO              : $ORA_BENCH_RUN_GODROR_GO"
echo "RUN_JAMDB_ORACLE_ERLANG    : $ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG"
echo "RUN_JDBC_JAVA              : $ORA_BENCH_RUN_JDBC_JAVA"
echo "RUN_ODPI_C                 : $ORA_BENCH_RUN_ODPI_C"
echo "RUN_ORANIF_ELIXIR          : $ORA_BENCH_RUN_ORANIF_ELIXIR"
echo "RUN_ORANIF_ERLANG          : $ORA_BENCH_RUN_ORANIF_ERLANG"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

if [ "$RUN_GLOBAL_NON_JAMDB" = "true" ]; then
    if [ "$ORA_BENCH_RUN_CX_ORACLE_PYTHON" = "true" ]; then
        if ! { /bin/bash src_python/scripts/run_bench_cx_oracle.sh; }; then
            exit 255
        fi
    fi
    
    if [ "$ORA_BENCH_RUN_GODROR_GO" = "true" ]; then
        if ! { /bin/bash src_go/scripts/run_bench_godror.sh; }; then
            exit 255
        fi
    fi
    
    if [ "$ORA_BENCH_RUN_JDBC_KOTLIN" = "true" ]; then
        if ! { /bin/bash src_kotlin/scripts/run_bench_jdbc.sh; }; then
            exit 255
        fi
    fi
fi

if [ "$RUN_GLOBAL_JAMDB" = "true" ]; then
    if [ "$ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG" = "true" ]; then
        if ! { /bin/bash src_erlang/scripts/run_bench_jamdb_oracle.sh; }; then
            exit 255
        fi
    fi
fi

if [ "$RUN_GLOBAL_NON_JAMDB" = "true" ]; then
    if [ "$ORA_BENCH_RUN_JDBC_JAVA" = "true" ]; then
        if ! { /bin/bash src_java/scripts/run_bench_jdbc.sh; }; then
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
