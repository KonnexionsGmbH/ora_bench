#!/bin/bash

exec &> >(tee -i run_bench.log)
sleep .1

# ------------------------------------------------------------------------------
#
# run_bench.sh: Oracle Benchmark for all database versions.
#
# ------------------------------------------------------------------------------

export ORA_BENCH_BENCHMARK_COMMENT='Standard tests (locally)'

export ORA_BENCH_CONNECTION_HOST=0.0.0.0
export ORA_BENCH_CONNECTION_PORT=1521

export ORA_BENCH_FILE_CONFIGURATION_NAME=priv/properties/ora_bench.properties

if [ -z "$ORA_BENCH_JAVA_CLASSPATH" ]; then
    export ORA_BENCH_JAVA_CLASSPATH=".;priv/java_jar/*"
fi

export ORA_BENCH_PASSWORD_SYS=oracle

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - all databases."
echo "--------------------------------------------------------------------------------"
echo "BENCHMARK_COMMENT       : $ORA_BENCH_BENCHMARK_COMMENT"
echo "CONNECTION_HOST         : $ORA_BENCH_CONNECTION_HOST"
echo "CONNECTION_PORT         : $ORA_BENCH_CONNECTION_PORT"
echo "FILE_CONFIGURATION_NAME : $ORA_BENCH_FILE_CONFIGURATION_NAME"
echo "JAVA_CLASSPATH          : $ORA_BENCH_JAVA_CLASSPATH"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

EXITCODE="0"

export ORA_BENCH_BENCHMARK_DATABASE=db_11_2_xe
export ORA_BENCH_CONNECTION_SERVICE=xe
{ /bin/bash scripts/run_bench_database.sh; }

export ORA_BENCH_BENCHMARK_DATABASE=db_12_2_ee
export ORA_BENCH_CONNECTION_SERVICE=orclpdb1
{ /bin/bash scripts/run_bench_database.sh; }

export ORA_BENCH_BENCHMARK_DATABASE=db_18_3_ee
export ORA_BENCH_CONNECTION_SERVICE=orclpdb1
{ /bin/bash scripts/run_bench_database.sh; }

export ORA_BENCH_BENCHMARK_DATABASE=db_19_3_ee
export ORA_BENCH_CONNECTION_SERVICE=orclpdb1
{ /bin/bash scripts/run_bench_database.sh; }

EXITCODE=$?

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"

exit $EXITCODE
