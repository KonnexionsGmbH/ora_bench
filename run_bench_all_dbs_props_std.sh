#!/bin/bash

set -e

exec &> >(tee -i run_bench_all_dbs_props_std.log)
sleep .1

# ------------------------------------------------------------------------------
#
# run_bench_all_dbs_props_std.sh: Oracle Benchmark for all database versions
#                                 with standard properties.
#
# ------------------------------------------------------------------------------

export ORA_BENCH_BENCHMARK_COMMENT='Standard tests (locally)'

if [ -z "$ORA_BENCH_CONNECTION_HOST" ]; then
    export ORA_BENCH_CONNECTION_HOST=0.0.0.0
fi
if [ -z "$ORA_BENCH_CONNECTION_PORT" ]; then
    export ORA_BENCH_CONNECTION_PORT=1521
fi

export ORA_BENCH_RUN_DB_12_2_EE=true
export ORA_BENCH_RUN_DB_18_3_EE=true
export ORA_BENCH_RUN_DB_19_3_EE=true

export ORA_BENCH_RUN_CX_ORACLE_PYTHON=true
export ORA_BENCH_RUN_GODROR_GO=true
export ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG=true
export ORA_BENCH_RUN_JDBC_JAVA=true
export ORA_BENCH_RUN_ODPI_C=true
export ORA_BENCH_RUN_ORANIF_ELIXIR=true
export ORA_BENCH_RUN_ORANIF_ERLANG=true

export ORA_BENCH_PASSWORD_SYS=oracle

if [ -z "$ORA_BENCH_FILE_CONFIGURATION_NAME" ]; then
    export ORA_BENCH_FILE_CONFIGURATION_NAME=priv/properties/ora_bench.properties
fi

if [ -z "$ORA_BENCH_JAVA_CLASSPATH" ]; then
    if [ "$OSTYPE" = "msys" ]; then
        export ORA_BENCH_JAVA_CLASSPATH=".;priv/java_jar/*"
    else
        export ORA_BENCH_JAVA_CLASSPATH=".:priv/java_jar/*"
    fi
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
echo "ora_bench - Oracle benchmark - all databases with standard properties."
echo "--------------------------------------------------------------------------------"
echo "BENCHMARK_BATCH_SIZE       : $ORA_BENCH_BENCHMARK_BATCH_SIZE"
echo "BENCHMARK_COMMENT          : $ORA_BENCH_BENCHMARK_COMMENT"
echo "BULKFILE_EXISTING          : $ORA_BENCH_BULKFILE_EXISTING"
echo "BENCHMARK_TRANSACTION_SIZE : $ORA_BENCH_BENCHMARK_TRANSACTION_SIZE"
echo "CONNECTION_HOST            : $ORA_BENCH_CONNECTION_HOST"
echo "CONNECTION_PORT            : $ORA_BENCH_CONNECTION_PORT"
echo "FILE_CONFIGURATION_NAME    : $ORA_BENCH_FILE_CONFIGURATION_NAME"
echo "JAVA_CLASSPATH             : $ORA_BENCH_JAVA_CLASSPATH"
echo "--------------------------------------------------------------------------------"
echo "RUN_DB_12_2_EE             : $ORA_BENCH_RUN_DB_12_2_EE"
echo "RUN_DB_18_3_EE             : $ORA_BENCH_RUN_DB_18_3_EE"
echo "RUN_DB_19_3_EE             : $ORA_BENCH_RUN_DB_19_3_EE"
echo "--------------------------------------------------------------------------------"
echo "RUN_GLOBAL_JAMDB           : $RUN_GLOBAL_JAMDB"
echo "RUN_GLOBAL_NON_JAMDB       : $RUN_GLOBAL_NON_JAMDB"
echo "--------------------------------------------------------------------------------"
echo "RUN_CX_ORACLE_PYTHON       : $ORA_BENCH_RUN_CX_ORACLE_PYTHON"
echo "RUN_GODROR_GO              : $ORA_BENCH_RUN_GODROR_GO"
echo "RUN_JAMDB_ORACLE_ERLANG    : $ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG"
echo "RUN_JDBC_JAVA              : $ORA_BENCH_RUN_JDBC_JAVA"
echo "RUN_ODPI_C                 : $ORA_BENCH_RUN_ODPI_C"
echo "RUN_ORANIF_ELIXIR          : $ORA_BENCH_RUN_ORANIF_ELIXIR"
echo "RUN_ORANIF_ERLANG          : $ORA_BENCH_RUN_ORANIF_ERLANG"
echo "--------------------------------------------------------------------------------"
echo "JAVA_CLASSPATH             : $ORA_BENCH_JAVA_CLASSPATH"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

if ! { /bin/bash scripts/run_create_bulk_file.sh; }; then
    exit 255
fi

export ORA_BENCH_BULKFILE_EXISTING=true

 if [ "$ORA_BENCH_RUN_DB_12_2_EE" = "true" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_12_2_ee
    export ORA_BENCH_CONNECTION_SERVICE=orclpdb1
    if ! { /bin/bash scripts/run_properties_standard.sh; }; then
        exit 255
    fi
fi

if [ "$ORA_BENCH_RUN_DB_18_3_EE" = "true" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_18_3_ee
    export ORA_BENCH_CONNECTION_SERVICE=orclpdb1
    if ! { /bin/bash scripts/run_properties_standard.sh; }; then
        exit 255
    fi
fi

if [ "$ORA_BENCH_RUN_DB_19_3_EE" = "true" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_19_3_ee
    export ORA_BENCH_CONNECTION_SERVICE=orclpdb1
    if ! { /bin/bash scripts/run_properties_standard.sh; }; then
        exit 255
    fi
fi

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"
