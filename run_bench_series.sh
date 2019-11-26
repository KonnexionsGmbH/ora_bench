#!/bin/bash

exec &> >(tee -i run_bench_series.log)
sleep .1

# ------------------------------------------------------------------------------
#
# run_bench_series.sh: Oracle Benchmark series.
#
# ------------------------------------------------------------------------------

export ORA_BENCH_RUN_SERIES=true

export ORA_BENCH_BENCHMARK_COMMENT='Standard series (locally)'

export ORA_BENCH_CONNECTION_HOST=0.0.0.0
export ORA_BENCH_CONNECTION_PORT=1521

export ORA_BENCH_FILE_CONFIGURATION_NAME=priv/properties/ora_bench.properties

export ORA_BENCH_RUN_DB_11_2_XE=true
export ORA_BENCH_RUN_DB_12_2_EE=true
export ORA_BENCH_RUN_DB_18_3_EE=true
export ORA_BENCH_RUN_DB_19_3_EE=true

export ORA_BENCH_RUN_CX_ORACLE_PYTHON=true
export ORA_BENCH_RUN_JDBC_JAVA=true

if [ -z "$ORA_BENCH_JAVA_CLASSPATH" ]; then
    export ORA_BENCH_JAVA_CLASSPATH=".;priv/java_jar/*"
fi

export ORA_BENCH_PASSWORD_SYS=oracle

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - series."
echo "--------------------------------------------------------------------------------"
echo "RUN_SERIES              : $ORA_BENCH_RUN_SERIES"
echo "--------------------------------------------------------------------------------"
echo "BENCHMARK_COMMENT       : $ORA_BENCH_BENCHMARK_COMMENT"
echo "CONNECTION_HOST         : $ORA_BENCH_CONNECTION_HOST"
echo "CONNECTION_PORT         : $ORA_BENCH_CONNECTION_PORT"
echo "FILE_CONFIGURATION_NAME : $ORA_BENCH_FILE_CONFIGURATION_NAME"
echo "JAVA_CLASSPATH          : $ORA_BENCH_JAVA_CLASSPATH"
echo "--------------------------------------------------------------------------------"
echo "RUN_DB_11_2_XE          : $ORA_BENCH_RUN_DB_11_2_XE"
echo "RUN_DB_12_2_EE          : $ORA_BENCH_RUN_DB_12_2_EE"
echo "RUN_DB_18_3_EE          : $ORA_BENCH_RUN_DB_18_3_EE"
echo "RUN_DB_19_3_EE          : $ORA_BENCH_RUN_DB_19_3_EE"
echo "--------------------------------------------------------------------------------"
echo "RUN_CX_ORACLE_PYTHON    : $ORA_BENCH_RUN_CX_ORACLE_PYTHON"
echo "RUN_JDBC_JAVA           : $ORA_BENCH_RUN_JDBC_JAVA"
echo "--------------------------------------------------------------------------------"
echo "JAVA_HOME               : $JAVA_HOME"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

EXITCODE="0"

export ORA_BENCH_BENCHMARK_BATCH_SIZE_DEFAULT=256
export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE_DEFAULT=512

{ /bin/bash scripts/run_bench_setup.sh; }

if [ "$ORA_BENCH_RUN_DB_11_2_XE" = "true" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_11_2_xe
    export ORA_BENCH_CONNECTION_SERVICE=xe
    { /bin/bash scripts/run_bench_database_series.sh; }
fi

if [ "$ORA_BENCH_RUN_DB_12_2_EE" = "true" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_12_2_ee
    export ORA_BENCH_CONNECTION_SERVICE=orclpdb1
    { /bin/bash scripts/run_bench_database_series.sh; }
fi

if [ "$ORA_BENCH_RUN_DB_18_3_EE" = "true" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_18_3_ee
    export ORA_BENCH_CONNECTION_SERVICE=orclpdb1
    { /bin/bash scripts/run_bench_database_series.sh; }
fi

if [ "$ORA_BENCH_RUN_DB_19_3_EE" = "true" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_19_3_ee
    export ORA_BENCH_CONNECTION_SERVICE=orclpdb1
    { /bin/bash scripts/run_bench_database_series.sh; }
fi

export ORA_BENCH_BENCHMARK_BATCH_SIZE=$ORA_BENCH_BENCHMARK_BATCH_SIZE_DEFAULT
export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=$ORA_BENCH_BENCHMARK_TRANSACTION_SIZE_DEFAULT

{ /bin/bash scripts/run_bench_finalise.sh; }

EXITCODE=$?

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"

exit $EXITCODE
