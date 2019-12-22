#!/bin/bash

# ------------------------------------------------------------------------------
#
# run_bench_database_series.sh: Oracle benchmark for a specific database version.
#
# ------------------------------------------------------------------------------

if [ -z "$ORA_BENCH_RUN_CX_ORACLE_PYTHON" ]; then
    export ORA_BENCH_RUN_CX_ORACLE_PYTHON=true
fi
if [ -z "$ORA_BENCH_RUN_JDBC_JAVA" ]; then
    export ORA_BENCH_RUN_JDBC_JAVA=true
fi
if [ -z "$ORA_BENCH_RUN_ORANIF_ERLANG" ]; then
    export ORA_BENCH_RUN_ORANIF_ERLANG=true
fi

export ORA_BENCH_CONNECT_IDENTIFIER=//$ORA_BENCH_CONNECTION_HOST:$ORA_BENCH_CONNECTION_PORT/$ORA_BENCH_CONNECTION_SERVICE

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - specific database."
echo "--------------------------------------------------------------------------------"
echo "BENCHMARK_DATABASE : $ORA_BENCH_BENCHMARK_DATABASE"
echo "CONNECTION_SERVICE : $ORA_BENCH_CONNECTION_SERVICE"
echo "--------------------------------------------------------------------------------"
echo "CONNECT_IDENTIFIER : $ORA_BENCH_CONNECT_IDENTIFIER"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

EXITCODE="0"

docker stop ora_bench_db
docker rm -f ora_bench_db
docker create -e ORACLE_PWD=oracle --name ora_bench_db -p 1521:1521/tcp --shm-size 1G konnexionsgmbh/$ORA_BENCH_BENCHMARK_DATABASE
docker start ora_bench_db
while [ "`docker inspect -f {{.State.Health.Status}} ora_bench_db`" != "healthy" ]; do docker ps --filter "name=ora_bench_db"; sleep 60; done

priv/oracle/sqlcl/bin/sql sys/$ORA_BENCH_PASSWORD_SYS@$ORA_BENCH_CONNECT_IDENTIFIER AS SYSDBA @scripts/run_bench_database.sql

if [ "$ORA_BENCH_RUN_CX_ORACLE_PYTHON" = "true" ]; then
    export ORA_BENCH_BENCHMARK_BATCH_SIZE=$ORA_BENCH_BENCHMARK_BATCH_SIZE_DEFAULT
    export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=$ORA_BENCH_BENCHMARK_CORE_MULTIPLIER_DEFAULT
    export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=$ORA_BENCH_BENCHMARK_TRANSACTION_SIZE_DEFAULT
    java -cp "priv/java_jar/*" ch.konnexions.orabench.OraBench setup_python
    { /bin/bash scripts/run_bench_cx_oracle_python.sh; }
fi

if [ "$ORA_BENCH_RUN_CX_ORACLE_PYTHON" = "true" ]; then
    export ORA_BENCH_BENCHMARK_BATCH_SIZE=$ORA_BENCH_BENCHMARK_BATCH_SIZE_DEFAULT
    export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=$ORA_BENCH_BENCHMARK_TRANSACTION_SIZE_DEFAULT
    java -cp "priv/java_jar/*" ch.konnexions.orabench.OraBench setup_python
    { /bin/bash scripts/run_bench_cx_oracle_python.sh; }
fi

if [ "$ORA_BENCH_RUN_JDBC_JAVA" = "true" ]; then
    export ORA_BENCH_BENCHMARK_BATCH_SIZE=$ORA_BENCH_BENCHMARK_BATCH_SIZE_DEFAULT
    export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=$ORA_BENCH_BENCHMARK_CORE_MULTIPLIER_DEFAULT
    export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=$ORA_BENCH_BENCHMARK_TRANSACTION_SIZE_DEFAULT
    { /bin/bash scripts/run_bench_jdbc_java.sh; }
fi

if [ "$ORA_BENCH_RUN_JDBC_JAVA" = "true" ]; then
    export ORA_BENCH_BENCHMARK_BATCH_SIZE=$ORA_BENCH_BENCHMARK_BATCH_SIZE_DEFAULT
    export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=$ORA_BENCH_BENCHMARK_TRANSACTION_SIZE_DEFAULT
    { /bin/bash scripts/run_bench_jdbc_java.sh; }
fi

if [ "$ORA_BENCH_RUN_ORANIF_ERLANG" = "true" ]; then
    export ORA_BENCH_BENCHMARK_BATCH_SIZE=$ORA_BENCH_BENCHMARK_BATCH_SIZE_DEFAULT
    export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=$ORA_BENCH_BENCHMARK_CORE_MULTIPLIER_DEFAULT
    export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=$ORA_BENCH_BENCHMARK_TRANSACTION_SIZE_DEFAULT
    { /bin/bash scripts/run_bench_oranif_erlang.sh; }
fi

if [ "$ORA_BENCH_RUN_ORANIF_ERLANG" = "true" ]; then
    export ORA_BENCH_BENCHMARK_BATCH_SIZE=$ORA_BENCH_BENCHMARK_BATCH_SIZE_DEFAULT
    export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=$ORA_BENCH_BENCHMARK_TRANSACTION_SIZE_DEFAULT
    { /bin/bash scripts/run_bench_oranif_erlang.sh; }
fi

if [ "$ORA_BENCH_RUN_CX_ORACLE_PYTHON" = "true" ]; then
    export ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=$ORA_BENCH_BENCHMARK_CORE_MULTIPLIER_DEFAULT
    export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=$ORA_BENCH_BENCHMARK_TRANSACTION_SIZE_DEFAULT
    java -cp "priv/java_jar/*" ch.konnexions.orabench.OraBench setup_python
    { /bin/bash scripts/run_bench_cx_oracle_python.sh; }
fi

if [ "$ORA_BENCH_RUN_CX_ORACLE_PYTHON" = "true" ]; then
    export ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=$ORA_BENCH_BENCHMARK_TRANSACTION_SIZE_DEFAULT
    java -cp "priv/java_jar/*" ch.konnexions.orabench.OraBench setup_python
    { /bin/bash scripts/run_bench_cx_oracle_python.sh; }
fi

if [ "$ORA_BENCH_RUN_JDBC_JAVA" = "true" ]; then
    export ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER==$ORA_BENCH_BENCHMARK_CORE_MULTIPLIER_DEFAULT
    export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=$ORA_BENCH_BENCHMARK_TRANSACTION_SIZE_DEFAULT
    { /bin/bash scripts/run_bench_jdbc_java.sh; }
fi

if [ "$ORA_BENCH_RUN_JDBC_JAVA" = "true" ]; then
    export ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=$ORA_BENCH_BENCHMARK_TRANSACTION_SIZE_DEFAULT
    { /bin/bash scripts/run_bench_jdbc_java.sh; }
fi

if [ "$ORA_BENCH_RUN_ORANIF_ERLANG" = "true" ]; then
    export ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER==$ORA_BENCH_BENCHMARK_CORE_MULTIPLIER_DEFAULT
    export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=$ORA_BENCH_BENCHMARK_TRANSACTION_SIZE_DEFAULT
    { /bin/bash scripts/run_bench_oranif_erlang.sh; }
fi

if [ "$ORA_BENCH_RUN_ORANIF_ERLANG" = "true" ]; then
    export ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=$ORA_BENCH_BENCHMARK_TRANSACTION_SIZE_DEFAULT
    { /bin/bash scripts/run_bench_oranif_erlang.sh; }
fi

if [ "$ORA_BENCH_RUN_CX_ORACLE_PYTHON" = "true" ]; then
    export ORA_BENCH_BENCHMARK_BATCH_SIZE=$ORA_BENCH_BENCHMARK_BATCH_SIZE_DEFAULT
    export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=$ORA_BENCH_BENCHMARK_CORE_MULTIPLIER_DEFAULT
    export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    java -cp "priv/java_jar/*" ch.konnexions.orabench.OraBench setup_python
    { /bin/bash scripts/run_bench_cx_oracle_python.sh; }
fi

if [ "$ORA_BENCH_RUN_CX_ORACLE_PYTHON" = "true" ]; then
    export ORA_BENCH_BENCHMARK_BATCH_SIZE=$ORA_BENCH_BENCHMARK_BATCH_SIZE_DEFAULT
    export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    java -cp "priv/java_jar/*" ch.konnexions.orabench.OraBench setup_python
    { /bin/bash scripts/run_bench_cx_oracle_python.sh; }
fi

if [ "$ORA_BENCH_RUN_JDBC_JAVA" = "true" ]; then
    export ORA_BENCH_BENCHMARK_BATCH_SIZE=$ORA_BENCH_BENCHMARK_BATCH_SIZE_DEFAULT
    export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=$ORA_BENCH_BENCHMARK_CORE_MULTIPLIER_DEFAULT
    export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    { /bin/bash scripts/run_bench_jdbc_java.sh; }
fi

if [ "$ORA_BENCH_RUN_JDBC_JAVA" = "true" ]; then
    export ORA_BENCH_BENCHMARK_BATCH_SIZE=$ORA_BENCH_BENCHMARK_BATCH_SIZE_DEFAULT
    export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    { /bin/bash scripts/run_bench_jdbc_java.sh; }
fi

if [ "$ORA_BENCH_RUN_ORANIF_ERLANG" = "true" ]; then
    export ORA_BENCH_BENCHMARK_BATCH_SIZE=$ORA_BENCH_BENCHMARK_BATCH_SIZE_DEFAULT
    export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=$ORA_BENCH_BENCHMARK_CORE_MULTIPLIER_DEFAULT
    export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    { /bin/bash scripts/run_bench_oranif_erlang.sh; }
fi

if [ "$ORA_BENCH_RUN_ORANIF_ERLANG" = "true" ]; then
    export ORA_BENCH_BENCHMARK_BATCH_SIZE=$ORA_BENCH_BENCHMARK_BATCH_SIZE_DEFAULT
    export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    { /bin/bash scripts/run_bench_oranif_erlang.sh; }
fi

if [ "$ORA_BENCH_RUN_CX_ORACLE_PYTHON" = "true" ]; then
    export ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=$ORA_BENCH_BENCHMARK_CORE_MULTIPLIER_DEFAULT
    export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    java -cp "priv/java_jar/*" ch.konnexions.orabench.OraBench setup_python
    { /bin/bash scripts/run_bench_cx_oracle_python.sh; }
fi

if [ "$ORA_BENCH_RUN_CX_ORACLE_PYTHON" = "true" ]; then
    export ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    java -cp "priv/java_jar/*" ch.konnexions.orabench.OraBench setup_python
    { /bin/bash scripts/run_bench_cx_oracle_python.sh; }
fi
if [ "$ORA_BENCH_RUN_JDBC_JAVA" = "true" ]; then
    export ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=$ORA_BENCH_BENCHMARK_CORE_MULTIPLIER_DEFAULT
    export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    { /bin/bash scripts/run_bench_jdbc_java.sh; }
fi

if [ "$ORA_BENCH_RUN_JDBC_JAVA" = "true" ]; then
    export ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    { /bin/bash scripts/run_bench_jdbc_java.sh; }
fi

if [ "$ORA_BENCH_RUN_ORANIF_ERLANG" = "true" ]; then
    export ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=$ORA_BENCH_BENCHMARK_CORE_MULTIPLIER_DEFAULT
    export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    { /bin/bash scripts/run_bench_oranif_erlang.sh; }
fi

if [ "$ORA_BENCH_RUN_ORANIF_ERLANG" = "true" ]; then
    export ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    { /bin/bash scripts/run_bench_oranif_erlang.sh; }
fi

EXITCODE=$?

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"

exit $EXITCODE
