#!/bin/bash

# ------------------------------------------------------------------------------
#
# run_bench_database.sh: Oracle benchmark for a specific database version.
#
# ------------------------------------------------------------------------------

EXITCODE="0"

if [ -z "$ORA_BENCH_BENCHMARK_DATABASE" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_18_4_xe
fi
if [ -z "$ORA_BENCH_CONNECTION_SERVICE" ]; then
    export ORA_BENCH_CONNECTION_SERVICE=xe
fi

docker stop ora_bench_db
docker rm -f ora_bench_db
docker create -e ORACLE_PWD=oracle --health-retries 10 --name ora_bench_db -p 1521:1521/tcp --shm-size 1G konnexionsgmbh/$ORA_BENCH_BENCHMARK_DATABASE
docker start ora_bench_db
while [ "`docker inspect -f {{.State.Health.Status}} ora_bench_db`" != "healthy" ]; do docker ps --filter "name=ora_bench_db"; sleep 60; done

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "BENCHMARK_COMMENT  : $ORA_BENCH_BENCHMARK_COMMENT"
echo "BENCHMARK_DATABASE : $ORA_BENCH_BENCHMARK_DATABASE"
echo "CONNECTION_SERVICE : $ORA_BENCH_CONNECTION_SERVICE"
echo "CONNECTION_HOST    : $ORA_BENCH_CONNECTION_HOST"
echo "CONNECTION_PORT    : $ORA_BENCH_CONNECTION_PORT"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark."
echo "--------------------------------------------------------------------------------"
date +"DATE TIME          : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

{ /bin/bash run_bench_setup.sh; }

{ /bin/bash run_bench_java.sh; }

EXITCODE=$?

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME          : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"

exit $EXITCODE
