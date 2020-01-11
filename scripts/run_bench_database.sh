#!/bin/bash

# ------------------------------------------------------------------------------
#
 # run_bench_database.sh: Oracle benchmark for a specific database version.
#
# ------------------------------------------------------------------------------

export ORA_BENCH_MULTIPLE_RUN=true

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
if [ -z "$ORA_BENCH_RUN_JAMDB_ORACLE_ELIXIR" ]; then
    export ORA_BENCH_RUN_JAMDB_ORACLE_ELIXIR=true
fi
export ORA_BENCH_RUN_JAMDB_ORACLE_ELIXIR=false
if [ -z "$ORA_BENCH_RUN_JDBC_JAVA" ]; then
    export ORA_BENCH_RUN_JDBC_JAVA=true
fi
if [ -z "$ORA_BENCH_RUN_ODPI_C" ]; then
    export ORA_BENCH_RUN_ODPI_C=true
fi
if [ -z "$ORA_BENCH_RUN_ORANIF_ELIXIR" ]; then
    export ORA_BENCH_RUN_ORANIF_ELIXIR=true
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
echo "BENCHMARK_DATABASE         : $ORA_BENCH_BENCHMARK_DATABASE"
echo "CONNECTION_HOST            : $ORA_BENCH_CONNECTION_HOST"
echo "CONNECTION_PORT            : $ORA_BENCH_CONNECTION_PORT"
echo "CONNECTION_SERVICE         : $ORA_BENCH_CONNECTION_SERVICE"
echo "FILE_CONFIGURATION_NAME    : $ORA_BENCH_FILE_CONFIGURATION_NAME"
echo "--------------------------------------------------------------------------------"
echo "BENCHMARK_BATCH_SIZE       : $ORA_BENCH_BENCHMARK_BATCH_SIZE"
echo "BENCHMARK_CORE_MULTIPLIER  : $ORA_BENCH_BENCHMARK_CORE_MULTIPLIER"
echo "BENCHMARK_TRANSACTION_SIZE : $ORA_BENCH_BENCHMARK_TRANSACTION_SIZE"
echo "--------------------------------------------------------------------------------"
echo "RUN_CX_ORACLE_PYTHON       : $ORA_BENCH_RUN_CX_ORACLE_PYTHON"
echo "RUN_JAMDB_ORACLE_ELIXIR    : $ORA_BENCH_RUN_JAMDB_ORACLE_ELIXIR"
echo "RUN_JDBC_JAVA              : $ORA_BENCH_RUN_JDBC_JAVA"
echo "RUN_ODPI_C                 : $ORA_BENCH_RUN_ODPI_C"
echo "RUN_ORANIF_ELIXIR          : $ORA_BENCH_RUN_ORANIF_ELIXIR"
echo "RUN_ORANIF_ERLANG          : $ORA_BENCH_RUN_ORANIF_ERLANG"
echo "--------------------------------------------------------------------------------"
echo "CONNECT_IDENTIFIER         : $ORA_BENCH_CONNECT_IDENTIFIER"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

EXITCODE="0"

if [ "$ORA_BENCH_RUN_ODPI_C" == "true" ]; then
    echo "Setup C - Start ============================================================" 
    if [ "$OSTYPE" = "msys" ]; then
        nmake -f src_c/Makefile.win32 clean
        nmake -f src_c/Makefile.win32
    else
        make -f src_c/Makefile clean
        make -f src_c/Makefile
    fi
    echo "Setup C - End   ============================================================" 
fi

if ["$ORA_BENCH_RUN_JAMDB_ORACLE_ELIXIR" == "true" or "$ORA_BENCH_RUN_ORANIF_ELIXIR" == "true"]: then
    echo "Setup Elixir - Start =======================================================" 
    call mix deps.get
    call mix deps.compile
    echo "Setup Elixir - End   =======================================================" 
fi

if ["$$ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG" == "true"]: then
    echo "Setup Erlang - Start =======================================================" 
    cd src_erlang
    rebar3 escriptize
    echo "Setup Erlang - End   =======================================================" 
    cd ..
fi

start=$(date +%s)
echo "Docker stop/rm ora_bench_db"
docker stop ora_bench_db
docker rm -f ora_bench_db
echo "Docker create ora_bench_db($ORA_BENCH_BENCHMARK_DATABASE)"
docker create -e ORACLE_PWD=oracle --name ora_bench_db -p 1521:1521/tcp --shm-size 1G konnexionsgmbh/$ORA_BENCH_BENCHMARK_DATABASE
echo "Docker started ora_bench_db($ORA_BENCH_BENCHMARK_DATABASE)..."
docker start ora_bench_db
while [ "`docker inspect -f {{.State.Health.Status}} ora_bench_db`" != "healthy" ]; do docker ps --filter "name=ora_bench_db"; sleep 60; done
end=$(date +%s)
echo "DOCKER ready in $((end - start)) seconds"

if [ "$OSTYPE" = "msys" ]; then
  priv/oracle/instantclient-windows.x64/instantclient_19_5/sqlplus.exe sys/$ORA_BENCH_PASSWORD_SYS@$ORA_BENCH_CONNECT_IDENTIFIER AS SYSDBA @scripts/run_bench_database.sql
else
  priv/oracle/instantclient-linux.x64/instantclient_19_5/sqlplus sys/$ORA_BENCH_PASSWORD_SYS@$ORA_BENCH_CONNECT_IDENTIFIER AS SYSDBA @scripts/run_bench_database.sql
fi  
if [ $? -ne 0 ]; then
    exit $?
fi
    
{ /bin/bash scripts/run_bench_all_drivers.sh; }
if [ $? -ne 0 ]; then
    exit $?
fi

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"
