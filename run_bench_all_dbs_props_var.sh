#!/bin/bash

exec &> >(tee -i run_bench_all_dbs_props_var.log)
sleep .1

# ------------------------------------------------------------------------------
#
# run_bench_all_dbs_props_var.sh: Oracle Benchmark for all database versions
#                                 with variations of properties.
#
# ------------------------------------------------------------------------------

export ORA_BENCH_RUN_SERIES=true

export ORA_BENCH_BENCHMARK_COMMENT='Standard series (locally)'

export ORA_BENCH_CONNECTION_HOST=0.0.0.0
export ORA_BENCH_CONNECTION_PORT=1521

export ORA_BENCH_FILE_CONFIGURATION_NAME=priv/properties/ora_bench.properties

export ORA_BENCH_RUN_DB_12_2_EE=true
export ORA_BENCH_RUN_DB_18_3_EE=true
export ORA_BENCH_RUN_DB_19_3_EE=true

export ORA_BENCH_RUN_CX_ORACLE_PYTHON=true
export ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG=true
export ORA_BENCH_RUN_JDBC_JAVA=true
export ORA_BENCH_RUN_ODPI_C=true
export ORA_BENCH_RUN_ORANIF_ELIXIR=true
export ORA_BENCH_RUN_ORANIF_ERLANG=true

if [ -z "$ORA_BENCH_JAVA_CLASSPATH" ]; then
    if [ "$OSTYPE" = "msys" ]; then
        export ORA_BENCH_JAVA_CLASSPATH=".;priv/java_jar/*"
    else
        export ORA_BENCH_JAVA_CLASSPATH=".:priv/java_jar/*"
    fi
fi

export ORA_BENCH_PASSWORD_SYS=oracle

export RUN_GLOBAL_JAMDB=true
export RUN_GLOBAL_NON_JAMDB=true

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - all databases with property variations."
echo "--------------------------------------------------------------------------------"
echo "RUN_SERIES              : $ORA_BENCH_RUN_SERIES"
echo "--------------------------------------------------------------------------------"
echo "BENCHMARK_COMMENT       : $ORA_BENCH_BENCHMARK_COMMENT"
echo "CONNECTION_HOST         : $ORA_BENCH_CONNECTION_HOST"
echo "CONNECTION_PORT         : $ORA_BENCH_CONNECTION_PORT"
echo "FILE_CONFIGURATION_NAME : $ORA_BENCH_FILE_CONFIGURATION_NAME"
echo "JAVA_CLASSPATH          : $ORA_BENCH_JAVA_CLASSPATH"
echo "--------------------------------------------------------------------------------"
echo "RUN_DB_12_2_EE          : $ORA_BENCH_RUN_DB_12_2_EE"
echo "RUN_DB_18_3_EE          : $ORA_BENCH_RUN_DB_18_3_EE"
echo "RUN_DB_19_3_EE          : $ORA_BENCH_RUN_DB_19_3_EE"
echo "--------------------------------------------------------------------------------"
echo "RUN_GLOBAL_JAMDB        : $RUN_GLOBAL_JAMDB"
echo "RUN_GLOBAL_NON_JAMDB    : $RUN_GLOBAL_NON_JAMDB"
echo "--------------------------------------------------------------------------------"
echo "RUN_CX_ORACLE_PYTHON    : $ORA_BENCH_RUN_CX_ORACLE_PYTHON"
echo "RUN_JAMDB_ORACLE_ERLANG : $ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG"
echo "RUN_JDBC_JAVA           : $ORA_BENCH_RUN_JDBC_JAVA"
echo "RUN_ODPI_C              : $ORA_BENCH_RUN_ODPI_C"
echo "RUN_ORANIF_ELIXIR       : $ORA_BENCH_RUN_ORANIF_ELIXIR"
echo "RUN_ORANIF_ERLANG       : $ORA_BENCH_RUN_ORANIF_ERLANG"
echo "--------------------------------------------------------------------------------"
echo "JAVA_HOME               : $JAVA_HOME"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

EXITCODE="0"

export ORA_BENCH_BENCHMARK_BATCH_SIZE_DEFAULT=256
export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER_DEFAULT=0
export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE_DEFAULT=512

if [ "$ORA_BENCH_RUN_DB_12_2_EE" = "true" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_12_2_ee
    export ORA_BENCH_CONNECTION_SERVICE=orclpdb1
    { /bin/bash scripts/run_db_setup_benchmark_props_var.sh; }
    if [ $? -ne 0 ]; then
        exit $?
    fi
fi

if [ "$ORA_BENCH_RUN_DB_18_3_EE" = "true" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_18_3_ee
    export ORA_BENCH_CONNECTION_SERVICE=orclpdb1
    { /bin/bash scripts/run_db_setup_benchmark_props_var.sh; }
    if [ $? -ne 0 ]; then
        exit $?
    fi
fi

if [ "$ORA_BENCH_RUN_DB_19_3_EE" = "true" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_19_3_ee
    export ORA_BENCH_CONNECTION_SERVICE=orclpdb1
    { /bin/bash scripts/run_db_setup_benchmark_props_var.sh; }
    if [ $? -ne 0 ]; then
        exit $?
    fi
fi

export ORA_BENCH_BENCHMARK_BATCH_SIZE=$ORA_BENCH_BENCHMARK_BATCH_SIZE_DEFAULT
export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER_DEFAULT=$ORA_BENCH_BENCHMARK_CORE_MULTIPLIER_DEFAULT
export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=$ORA_BENCH_BENCHMARK_TRANSACTION_SIZE_DEFAULT

EXITCODE=$?

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"

start priv/audio/end_of_series.mp3

exit $EXITCODE
