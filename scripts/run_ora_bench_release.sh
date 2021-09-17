#!/bin/bash

set -e

# ------------------------------------------------------------------------------
#
# run_ora_bench_release.bat: Release run for VMWare and WSL2.
#
# ------------------------------------------------------------------------------

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "OraBench - Release run for VMWare and WSL2."
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

export ORA_BENCH_BENCHMARK_COMMENT="Release"
export ORA_BENCH_CONNECTION_HOST=localhost
export ORA_BENCH_CONNECTION_PORT=1521

export ORA_BENCH_ORACLE_DATABASE_ANY=false
export ORA_BENCH_ORACLE_DATABASE_18C=false
export ORA_BENCH_ORACLE_DATABASE_19C=false
export ORA_BENCH_ORACLE_DATABASE_21C=false
export ORA_BENCH_ORACLE_DATABASE_EXISTING=false

export ORA_BENCH_FILE_CONFIGURATION_NAME=priv/properties/ora_bench.properties
export ORA_BENCH_PASSWORD_SYS=oracle

export ORA_BENCH_RUN_CX_ORACLE_PYTHON=false
export ORA_BENCH_RUN_GODROR_GO=false
export ORA_BENCH_RUN_JDBC_JAVA=true
export ORA_BENCH_RUN_JDBC_KOTLIN=false
export ORA_BENCH_RUN_ODPI_C=false
export ORA_BENCH_RUN_ORACLE_JL_JULIA=false
export ORA_BENCH_RUN_ORANIF_ELIXIR=false
export ORA_BENCH_RUN_ORANIF_ERLANG=false

echo "ORACLE_DATABASE_EXISTING : ${ORA_BENCH_ORACLE_DATABASE_EXISTING}"
echo "ORACLE_DATABASE_18C      : ${ORA_BENCH_ORACLE_DATABASE_18C}"
echo "ORACLE_DATABASE_19C      : ${ORA_BENCH_ORACLE_DATABASE_19C}"
echo "ORACLE_DATABASE_21C      : ${ORA_BENCH_ORACLE_DATABASE_21C}"
echo "--------------------------------------------------------------------------------"
echo "RUN_CX_ORACLE_PYTHON     : ${ORA_BENCH_RUN_CX_ORACLE_PYTHON}"
echo "RUN_GODROR_GO            : ${ORA_BENCH_RUN_GODROR_GO}"
echo "RUN_JDBC_JAVA            : ${ORA_BENCH_RUN_JDBC_JAVA}"
echo "RUN_JDBC_KOTLIN          : ${ORA_BENCH_RUN_JDBC_KOTLIN}"
echo "RUN_ODPI_C               : ${ORA_BENCH_RUN_ODPI_C}"
echo "RUN_ORACLE_JL_JULIA      : ${ORA_BENCH_RUN_ORACLE_JL_JULIA}"
echo "RUN_ORANIF_ELIXIR        : ${ORA_BENCH_RUN_ORANIF_ELIXIR}"
echo "RUN_ORANIF_ERLANG        : ${ORA_BENCH_RUN_ORANIF_ERLANG}"
echo "================================================================================"

if [ "${ORA_BENCH_ORACLE_DATABASE_EXISTING}" = "true" \
  || "${ORA_BENCH_ORACLE_DATABASE_18C}" = "true" \
  || "${ORA_BENCH_ORACLE_DATABASE_19C}" = "true" \
  || "${ORA_BENCH_ORACLE_DATABASE_21C}" = "true" ]; then
    export ORA_BENCH_ORACLE_DATABASE_ANY=true
fi

if [ "${ORA_BENCH_ORACLE_DATABASE_ANY}" = "true" ]; then
    rm -f ora_bench.log
    rm -f priv/ora_bench_result.csv
    rm -f priv/ora_bench_result.tsv

    echo "--------------------------------------------------------------------------------"
    echo "Collect libraries and compile."
    echo "--------------------------------------------------------------------------------"
    if ! { /bin/bash scripts/run_collect_and_compile.sh; }; then
        exit 255
    fi

    echo "--------------------------------------------------------------------------------"
    echo "Create bulk file."
    echo "--------------------------------------------------------------------------------"
    if ! { /bin/bash scripts/run_create_bulk_file.sh; }; then
        exit 255
    fi
    
    if [ "${ORA_BENCH_ORACLE_DATABASE_EXISTING}" = "true" ]; then
        echo "--------------------------------------------------------------------------------"
        echo "Oracle Database already existing."
        echo "--------------------------------------------------------------------------------"
        docker ps -a
        docker start ora_bench_db

        if ! { /bin/bash scripts/run_bench_all_drivers.sh; }; then
            exit 255
        fi
    fi

    if [ "${ORA_BENCH_ORACLE_DATABASE_18C}" = "true" ]; then
        echo "--------------------------------------------------------------------------------"
        echo "Oracle Database Express Edition 18c."
        echo "--------------------------------------------------------------------------------"
        export ORA_BENCH_BENCHMARK_DATABASE=db_18_4_xe
        export ORA_BENCH_CONNECTION_SERVICE=xe
    fi

    if [ "${ORA_BENCH_ORACLE_DATABASE_19C}" = "true" ]; then
        echo "--------------------------------------------------------------------------------"
        echo "Oracle Database 19c."
        echo "--------------------------------------------------------------------------------"
        export ORA_BENCH_BENCHMARK_DATABASE=db_19_3_ee
        export ORA_BENCH_CONNECTION_SERVICE=orclpdb1
    fi

    if [${ORA_BENCH_ORACLE_DATABASE_21C}" = "true" ]; then
        echo "--------------------------------------------------------------------------------"
        echo "Oracle Database 21c."
        echo "--------------------------------------------------------------------------------"
        export ORA_BENCH_BENCHMARK_DATABASE=db_21_3_ee
        export ORA_BENCH_CONNECTION_SERVICE=orclpdb1
    
        if ! { /bin/bash scripts/run_db_setup.sh; }; then
            exit 255
        fi

        if ! { /bin/bash scripts/run_bench_all_drivers.sh; }; then
            exit 255
        fi
    )
fi

echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"