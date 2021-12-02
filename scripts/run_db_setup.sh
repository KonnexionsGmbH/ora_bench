#!/bin/bash

# ----------------------------------------------------------------------------------
#
# run_db_setup.sh: Database setup.
#
# ----------------------------------------------------------------------------------

set -e

if [ -z "${ORA_BENCH_BENCHMARK_DATABASE}" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_21_3_xe
fi
if [ -z "${ORA_BENCH_CONNECTION_HOST}" ]; then
    export ORA_BENCH_CONNECTION_HOST=localhost
fi
if [ -z "${ORA_BENCH_CONNECTION_PORT}" ]; then
    export ORA_BENCH_CONNECTION_PORT=1521
fi
if [ -z "${ORA_BENCH_CONNECTION_SERVICE}" ]; then
    export ORA_BENCH_CONNECTION_SERVICE=orclpdb1
fi
if [ -z "${ORA_BENCH_PASSWORD_SYS}" ]; then
    export ORA_BENCH_PASSWORD_SYS=oracle
fi

echo "=============================================================================="
echo "Start $0"
echo "------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - database setup."
echo "------------------------------------------------------------------------------"
echo "BENCHMARK_DATABASE                : ${ORA_BENCH_BENCHMARK_DATABASE}"
echo "CONNECTION_HOST                   : ${ORA_BENCH_CONNECTION_HOST}"
echo "CONNECTION_PORT                   : ${ORA_BENCH_CONNECTION_PORT}"
echo "CONNECTION_SERVICE                : ${ORA_BENCH_CONNECTION_SERVICE}"
echo "------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "=============================================================================="

start=$(date +%s)
echo "Docker stop/rm ora_bench_db ...................................................."
docker ps    | grep "ora_bench_db" && docker stop ora_bench_db
docker ps -a | grep "ora_bench_db" && docker rm ora_bench_db

echo "Docker setup network ..........................................................."
docker network prune --force
! docker network ls | grep "ora_bench_net" && docker network create ora_bench_net
docker network ls

echo "Docker create ora_bench_db(${ORA_BENCH_BENCHMARK_DATABASE}) ......................"
docker create -e        ORACLE_PWD=oracle \
              --name    ora_bench_db \
              --network ora_bench_net \
              -p        1521:1521/tcp \
              konnexionsgmbh/${ORA_BENCH_BENCHMARK_DATABASE}

echo "Docker started ora_bench_db(${ORA_BENCH_BENCHMARK_DATABASE}) ....................."
if ! docker start ora_bench_db; then
    exit 255
fi

while [ "`docker inspect -f {{.State.Health.Status}} ora_bench_db`" != "healthy" ]; do docker ps --filter "name=ora_bench_db"; sleep 60; done
if [ $? -ne 0 ]; then
    exit 255
fi
end=$(date +%s)
echo "DOCKER ready in $((end - start)) seconds ......................................."

if [ "$OSTYPE" = "msys" ]; then
    if ! sqlplus.exe sys/${ORA_BENCH_PASSWORD_SYS}@//${ORA_BENCH_CONNECTION_HOST}:${ORA_BENCH_CONNECTION_PORT}/${ORA_BENCH_CONNECTION_SERVICE} AS SYSDBA @scripts/run_db_setup.sql; then
        exit 255
    fi
else
    rm -f ~/.sqlnet.ora
    if [ "${ORA_BENCH_BENCHMARK_DATABASE}" = "db_19_3_ee" ] ||
       [ "${ORA_BENCH_BENCHMARK_DATABASE}" = "db_21_3_ee" ] ||
       [ "${ORA_BENCH_BENCHMARK_DATABASE}" = "db_21_3_xe" ]; then
        echo "DISABLE_OOB=ON" >> ~/.sqlnet.ora
    fi
    if ! sqlplus sys/${ORA_BENCH_PASSWORD_SYS}@//${ORA_BENCH_CONNECTION_HOST}:${ORA_BENCH_CONNECTION_PORT}/${ORA_BENCH_CONNECTION_SERVICE} AS SYSDBA @scripts/run_db_setup.sql; then
        exit 255
    fi
fi  
    
echo ""
echo "------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "------------------------------------------------------------------------------"
echo "End   $0"
echo "=============================================================================="
