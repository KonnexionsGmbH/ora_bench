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
echo ""
echo "BENCHMARK_COMMENT       : $ORA_BENCH_BENCHMARK_COMMENT"
echo "CONNECTION_HOST         : $ORA_BENCH_CONNECTION_HOST"
echo "CONNECTION_PORT         : $ORA_BENCH_CONNECTION_PORT"
echo "FILE_CONFIGURATION_NAME : $ORA_BENCH_FILE_CONFIGURATION_NAME"
echo "JAVA_CLASSPATH          : $ORA_BENCH_JAVA_CLASSPATH"
echo ""
echo "RUN_DB_11_2_XE          : $ORA_BENCH_RUN_DB_11_2_XE"
echo "RUN_DB_12_2_EE          : $ORA_BENCH_RUN_DB_12_2_EE"
echo "RUN_DB_18_3_EE          : $ORA_BENCH_RUN_DB_18_3_EE"
echo "RUN_DB_19_3_EE          : $ORA_BENCH_RUN_DB_19_3_EE"
echo ""
echo "RUN_CX_ORACLE_PYTHON    : $ORA_BENCH_RUN_CX_ORACLE_PYTHON"
echo "RUN_JDBC_JAVA           : $ORA_BENCH_RUN_JDBC_JAVA"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

EXITCODE="0"

{ /bin/bash scripts/run_bench.sh; }

export ORA_BENCH_BENCHMARK_BATCH_SIZE=0
{ /bin/bash scripts/run_bench.sh; }

export ORA_BENCH_BENCHMARK_BATCH_SIZE=
export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
{ /bin/bash scripts/run_bench.sh; }

export ORA_BENCH_BENCHMARK_BATCH_SIZE=0
export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
{ /bin/bash scripts/run_bench.sh; }

EXITCODE=$?

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"

exit $EXITCODE
