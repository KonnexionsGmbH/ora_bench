#!/bin/bash

# ------------------------------------------------------------------------------
#
# run_db_setup.sh: Database setup.
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
if [ -z "$ORA_BENCH_PASSWORD_SYS" ]; then
    export ORA_BENCH_PASSWORD_SYS=oracle
fi

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - database setup."
echo "--------------------------------------------------------------------------------"
echo "BENCHMARK_DATABASE         : $ORA_BENCH_BENCHMARK_DATABASE"
echo "CONNECTION_HOST            : $ORA_BENCH_CONNECTION_HOST"
echo "CONNECTION_PORT            : $ORA_BENCH_CONNECTION_PORT"
echo "CONNECTION_SERVICE         : $ORA_BENCH_CONNECTION_SERVICE"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

EXITCODE="0"

start=$(date +%s)
echo "Docker stop/rm ora_bench_db"
docker stop ora_bench_db
docker rm -f ora_bench_db
echo "Docker create ora_bench_db($ORA_BENCH_BENCHMARK_DATABASE)"
docker create -e ORACLE_PWD=oracle --name ora_bench_db -p 1521:1521/tcp --shm-size 1G konnexionsgmbh/$ORA_BENCH_BENCHMARK_DATABASE
echo "Docker started ora_bench_db($ORA_BENCH_BENCHMARK_DATABASE)..."
if ! docker start ora_bench_db; then
    echo "ERRORLEVEL : $?"
    exit $?
fi

if ! while [ "$(docker inspect -f "{.State.Health.Status}" ora_bench_db)" != "healthy" ]; do docker ps --filter "name=ora_bench_db"; sleep 60; done; then
    echo "ERRORLEVEL : $?"
    exit $?
fi
end=$(date +%s)
echo "DOCKER ready in $((end - start)) seconds"

if [ "$OSTYPE" = "msys" ]; then
  if ! priv/oracle/instantclient-windows.x64/instantclient_19_5/sqlplus.exe sys/$ORA_BENCH_PASSWORD_SYS@//$ORA_BENCH_CONNECTION_HOST:$ORA_BENCH_CONNECTION_PORT/$ORA_BENCH_CONNECTION_SERVICE AS SYSDBA @scripts/run_db_setup.sql; then
        echo "ERRORLEVEL : $?"
        exit $?
  fi      
else
  if ! priv/oracle/instantclient-linux.x64/instantclient_19_5/sqlplus sys/$ORA_BENCH_PASSWORD_SYS@//$ORA_BENCH_CONNECTION_HOST:$ORA_BENCH_CONNECTION_PORT/$ORA_BENCH_CONNECTION_SERVICE AS SYSDBA @scripts/run_db_setup.sql; then
        echo "ERRORLEVEL : $?"
        exit $?
  fi      
fi  
    
EXITCODE=$?

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"

exit $EXITCODE
