#!/bin/bash

# ------------------------------------------------------------------------------
#
 # run_bench_database.sh: Oracle benchmark for a specific database version.
#
# ------------------------------------------------------------------------------

if [ -z "$ORA_BENCH_BENCHMARK_DATABASE" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_19_3_ee
fi
if [ -z "$ORA_BENCH_CONNECTION_HOST" ]; then
    export ORA_BENCH_CONNECTION_HOST=0.0.0.0
fi
if [ -z "$ORA_BENCH_CONNECTION_PORT" ]; then
    export ORA_BENCH_CONNECTION_PORT=1521
fi
if [ -z "$ORA_BENCH_CONNECTION_SERVICE" ]; then
    export ORA_BENCH_CONNECTION_SERVICE=orclpdb1
fi
if [ -z "$ORA_BENCH_FILE_CONFIGURATION_NAME" ]; then
    export ORA_BENCH_FILE_CONFIGURATION_NAME=priv/properties/ora_bench.properties
fi
if [ -z "$ORA_BENCH_PASSWORD_SYS" ]; then
    export ORA_BENCH_PASSWORD_SYS=oracle
fi

if [ -z "$ORA_BENCH_RUN_CX_ORACLE_PYTHON" ]; then
    export ORA_BENCH_RUN_CX_ORACLE_PYTHON=true
fi
if [ -z "$ORA_BENCH_RUN_JDBC_JAVA" ]; then
    export ORA_BENCH_RUN_JDBC_JAVA=true
fi

export ORA_BENCH_CONNECT_IDENTIFIER=//$ORA_BENCH_CONNECTION_HOST:$ORA_BENCH_CONNECTION_PORT/$ORA_BENCH_CONNECTION_SERVICE

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - specific database."
echo "--------------------------------------------------------------------------------"
echo "BENCHMARK_DATABASE      : $ORA_BENCH_BENCHMARK_DATABASE"
echo "CONNECTION_HOST         : $ORA_BENCH_CONNECTION_HOST"
echo "CONNECTION_PORT         : $ORA_BENCH_CONNECTION_PORT"
echo "CONNECTION_SERVICE      : $ORA_BENCH_CONNECTION_SERVICE"
echo "FILE_CONFIGURATION_NAME : $ORA_BENCH_FILE_CONFIGURATION_NAME"
echo "--------------------------------------------------------------------------------"
echo "RUN_CX_ORACLE_PYTHON    : $ORA_BENCH_RUN_CX_ORACLE_PYTHON"
echo "RUN_JDBC_JAVA           : $ORA_BENCH_RUN_JDBC_JAVA"
echo "--------------------------------------------------------------------------------"
echo "CONNECT_IDENTIFIER      : $ORA_BENCH_CONNECT_IDENTIFIER"
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
    { /bin/bash scripts/run_bench_cx_oracle_python.sh; }
fi

if [ "$ORA_BENCH_RUN_JDBC_JAVA" = "true" ]; then
    { /bin/bash scripts/run_bench_jdbc_java.sh; }
fi

EXITCODE=$?

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"

exit $EXITCODE
