#!/bin/bash

# ------------------------------------------------------------------------------
#
# run_bench_all_drivers.sh: Oracle benchmark for all database drivers.
#
# ------------------------------------------------------------------------------

export ORA_BENCH_MULTIPLE_RUN=true

if [ -z "$ORA_BENCH_RUN_CX_ORACLE_PYTHON" ]; then
    export ORA_BENCH_RUN_CX_ORACLE_PYTHON=true
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

if [ -z "$RUN_GLOBAL_JAMDB" ]; then
    export RUN_GLOBAL_JAMDB=true
fi
if [ -z "$RUN_GLOBAL_NON_JAMDB" ]; then
    export RUN_GLOBAL_NON_JAMDB=true
fi

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - all drivers."
echo "--------------------------------------------------------------------------------"
echo "ORA_BENCH_BENCHMARK_JAMDB  : $ORA_BENCH_BENCHMARK_JAMDB"
echo "RUN_GLOBAL_JAMDB           : $RUN_GLOBAL_JAMDB"
echo "RUN_GLOBAL_NON_JAMDB       : $RUN_GLOBAL_NON_JAMDB"
echo "--------------------------------------------------------------------------------"
echo "RUN_CX_ORACLE_PYTHON       : $ORA_BENCH_RUN_CX_ORACLE_PYTHON"
echo "RUN_JAMDB_ORACLE_ERLANG    : $ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG"
echo "RUN_JDBC_JAVA              : $ORA_BENCH_RUN_JDBC_JAVA"
echo "RUN_ODPI_C                 : $ORA_BENCH_RUN_ODPI_C"
echo "RUN_ORANIF_ELIXIR          : $ORA_BENCH_RUN_ORANIF_ELIXIR"
echo "RUN_ORANIF_ERLANG          : $ORA_BENCH_RUN_ORANIF_ERLANG"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

EXITCODE="0"

{ /bin/bash scripts/run_create_bulk_file.sh; }
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi

if [ "$RUN_GLOBAL_NON_JAMDB" = "true" ]; then
    if [ "$ORA_BENCH_RUN_CX_ORACLE_PYTHON" = "true" ]; then
        { /bin/bash src_python/scripts/run_bench_cx_oracle.sh; }
        if [ $? -ne 0 ]; then
            echo "ERRORLEVEL : $?"
            exit $?
        fi
    fi
fi

if [ "$RUN_GLOBAL_JAMDB" = "true" ]; then
    if [ "$ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG" = "true" ]; then
        { /bin/bash src_erlang/scripts/run_bench_jamdb_oracle.sh; }
        if [ $? -ne 0 ]; then
            echo "ERRORLEVEL : $?"
            exit $?
        fi
    fi
fi

if [ "$RUN_GLOBAL_NON_JAMDB" = "true" ]; then
    if [ "$ORA_BENCH_RUN_JDBC_JAVA" = "true" ]; then
        { /bin/bash src_java/scripts/run_bench_jdbc.sh; }
        if [ $? -ne 0 ]; then
            echo "ERRORLEVEL : $?"
            exit $?
        fi
    fi
    
    if [ "$ORA_BENCH_RUN_ODPI_C" = "true" ]; then
        { /bin/bash src_c/scripts/run_bench_odpi.sh; }
        if [ $? -ne 0 ]; then
            echo "ERRORLEVEL : $?"
            exit $?
        fi
    fi
    
    if [ "$ORA_BENCH_RUN_ORANIF_ELIXIR" = "true" ]; then
        { /bin/bash src_elixir/scripts/run_bench_oranif.sh; }
        if [ $? -ne 0 ]; then
            echo "ERRORLEVEL : $?"
            exit $?
        fi
    fi
    
    if [ "$ORA_BENCH_RUN_ORANIF_ERLANG" = "true" ]; then
        { /bin/bash src_erlang/scripts/run_bench_oranif.sh; }
        if [ $? -ne 0 ]; then
            echo "ERRORLEVEL : $?"
            exit $?
        fi
    fi
fi

{ /bin/bash scripts/run_finalise_benchmark.sh; }

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"
