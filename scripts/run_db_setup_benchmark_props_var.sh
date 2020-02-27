#!/bin/bash

# ------------------------------------------------------------------------------
#
# run_db_setup_benchmark_props_std.sh: Database setup and Oracle benchmark 
#                                      with variations of properties.
#
# ------------------------------------------------------------------------------

export ORA_BENCH_MULTIPLE_RUN=true

if [ -z "$ORA_BENCH_RUN_CX_ORACLE_PYTHON" ]; then
    export ORA_BENCH_RUN_CX_ORACLE_PYTHON=true
fi
if [ -z "$ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG" ]; then
    export ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG=true
fi
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

if [ "$ORA_BENCH_BENCHMARK_JAMDB" = "" ]; then
    export RUN_GLOBAL_JAMDB=true
    export RUN_GLOBAL_NON_JAMDB=true
fi
if [ "$ORA_BENCH_BENCHMARK_JAMDB" = "false" ]; then
    export RUN_GLOBAL_JAMDB=false
    export RUN_GLOBAL_NON_JAMDB=true
fi
if [ "$ORA_BENCH_BENCHMARK_JAMDB" = "true" ]; then
    export RUN_GLOBAL_JAMDB=true
    export RUN_GLOBAL_NON_JAMDB=false
fi

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - database setup and Oracle benchmark - variations."
echo "--------------------------------------------------------------------------------"
echo "BENCHMARK_DATABASE         : $ORA_BENCH_BENCHMARK_DATABASE"
echo "CONNECTION_HOST            : $ORA_BENCH_CONNECTION_HOST"
echo "CONNECTION_PORT            : $ORA_BENCH_CONNECTION_PORT"
echo "CONNECTION_SERVICE         : $ORA_BENCH_CONNECTION_SERVICE"
echo "--------------------------------------------------------------------------------"
echo "BENCHMARK_BATCH_SIZE       : $ORA_BENCH_BENCHMARK_BATCH_SIZE"
echo "BENCHMARK_CORE_MULTIPLIER  : $ORA_BENCH_BENCHMARK_CORE_MULTIPLIER"
echo "BENCHMARK_TRANSACTION_SIZE : $ORA_BENCH_BENCHMARK_TRANSACTION_SIZE"
echo "--------------------------------------------------------------------------------"
echo "ORA_BENCH_BENCHMARK_JAMDB  : $ORA_BENCH_BENCHMARK_JAMDB"
echo "RUN_GLOBAL_JAMDB           : $RUN_GLOBAL_JAMDB"
echo "RUN_GLOBAL_NON_JAMDB       : $RUN_GLOBAL_NON_JAMDB"
echo "--------------------------------------------------------------------------------"
echo "RUN_CX_ORACLE_PYTHON       : $ORA_BENCH_RUN_CX_ORACLE_PYTHON"
echo "RUN_JAMDB_ORACLE_ERLANG    : $ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG"
echo "RUN_JDBC_JAVA              : $ORA_BENCH_RUN_JDBC_JAVA"
echo "RUN_ODPI_C                 : $ORA_BENCH_RUN_ODPI_C"
echo "RUN_ORANIF_ELIXIR          : $ORA_BENCH_RUN_ORANIF_ELIXIR"
echo "RUN_ORANIF_ERLANG          : $ORA_BENCH_RUN_ORANIF_ERLANG"
echo "--------------------------------------------------------------------------------"
echo "FILE_CONFIGURATION_NAME    : $ORA_BENCH_FILE_CONFIGURATION_NAME"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

EXITCODE="0"

if [ "$RUN_GLOBAL_NON_JAMDB" = "true" ]; then
    if [ "$ORA_BENCH_RUN_ODPI_C" == "true" ]; then
        echo "Setup C - Start ============================================================" 
        if [ "$OSTYPE" = "msys" ]; then
            nmake -f src_c/Makefile.win32 clean
            if [ $? -ne 0 ]; then
                echo "ERRORLEVEL : $?"
                exit $?
            fi
            nmake -f src_c/Makefile.win32
        else
            make -f src_c/Makefile clean
            if [ $? -ne 0 ]; then
                echo "ERRORLEVEL : $?"
                exit $?
            fi
            make -f src_c/Makefile
        fi
        if [ $? -ne 0 ]; then
            echo "ERRORLEVEL : $?"
            exit $?
        fi
        echo "Setup C - End   ============================================================" 
    fi
    
    if [ "$ORA_BENCH_RUN_ORANIF_ELIXIR" == "true" ]; then
        echo "Setup Elixir - Start =======================================================" 
        cd src_elixir
        mix local.hex --force
        if [ $? -ne 0 ]; then
            echo "ERRORLEVEL : $?"
            exit $?
        fi
        mix deps.clean --all
        if [ $? -ne 0 ]; then
            echo "ERRORLEVEL : $?"
            exit $?
        fi
        mix deps.get
        if [ $? -ne 0 ]; then
            echo "ERRORLEVEL : $?"
            exit $?
        fi
        mix deps.compile
        if [ $? -ne 0 ]; then
            echo "ERRORLEVEL : $?"
            exit $?
        fi
        cd ..
        echo "Setup Elixir - End   =======================================================" 
    fi
fi    
    
if [ "$ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG" == "true" ] || [ "$ORA_BENCH_RUN_ORANIF_ERLANG" == "true" ]; then
    echo "Setup Erlang - Start ======================================================="
    cd src_erlang
    rebar3 escriptize
    if [ $? -ne 0 ]; then
        echo "ERRORLEVEL : $?"
        exit $?
    fi
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
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi

while [ "`docker inspect -f {{.State.Health.Status}} ora_bench_db`" != "healthy" ]; do docker ps --filter "name=ora_bench_db"; sleep 60; done
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi
end=$(date +%s)
echo "DOCKER ready in $((end - start)) seconds"

if [ "$OSTYPE" = "msys" ]; then
  priv/oracle/instantclient-windows.x64/instantclient_19_5/sqlplus.exe sys/$ORA_BENCH_PASSWORD_SYS@//$ORA_BENCH_CONNECTION_HOST:$ORA_BENCH_CONNECTION_PORT/$ORA_BENCH_CONNECTION_SERVICE AS SYSDBA @scripts/run_db_setup.sql
else
  priv/oracle/instantclient-linux.x64/instantclient_19_5/sqlplus sys/$ORA_BENCH_PASSWORD_SYS@//$ORA_BENCH_CONNECTION_HOST:$ORA_BENCH_CONNECTION_PORT/$ORA_BENCH_CONNECTION_SERVICE AS SYSDBA @scripts/run_db_setup.sql
fi  
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi

# #01
export ORA_BENCH_BENCHMARK_BATCH_SIZE=$ORA_BENCH_BENCHMARK_BATCH_SIZE_DEFAULT
export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=$ORA_BENCH_BENCHMARK_CORE_MULTIPLIER_DEFAULT
export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=$ORA_BENCH_BENCHMARK_TRANSACTION_SIZE_DEFAULT
{ /bin/bash scripts/run_bench_all_drivers.sh; }
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi

# #02
export ORA_BENCH_BENCHMARK_BATCH_SIZE=$ORA_BENCH_BENCHMARK_BATCH_SIZE_DEFAULT
export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=$ORA_BENCH_BENCHMARK_TRANSACTION_SIZE_DEFAULT
{ /bin/bash scripts/run_bench_all_drivers.sh; }
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi

# #03
export ORA_BENCH_BENCHMARK_BATCH_SIZE=0
export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=$ORA_BENCH_BENCHMARK_CORE_MULTIPLIER_DEFAULT
export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=$ORA_BENCH_BENCHMARK_TRANSACTION_SIZE_DEFAULT
{ /bin/bash scripts/run_bench_all_drivers.sh; }
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi

# #04
export ORA_BENCH_BENCHMARK_BATCH_SIZE=0
export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=$ORA_BENCH_BENCHMARK_CORE_MULTIPLIER_DEFAULT
export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
{ /bin/bash scripts/run_bench_all_drivers.sh; }
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi

# #05
export ORA_BENCH_BENCHMARK_BATCH_SIZE=0
export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=$ORA_BENCH_BENCHMARK_TRANSACTION_SIZE_DEFAULT
{ /bin/bash scripts/run_bench_all_drivers.sh; }
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi

# #06
export ORA_BENCH_BENCHMARK_BATCH_SIZE=0
export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
{ /bin/bash scripts/run_bench_all_drivers.sh; }
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi

EXITCODE=$?

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"

exit $EXITCODE
