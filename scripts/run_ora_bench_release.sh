#!/bin/bash

set -e

# ------------------------------------------------------------------------------
#
# run_ora_bench_release.sh: Release run for VMWare and WSL2.
#
# ------------------------------------------------------------------------------

echo ""
echo "Script $0 is now running"

export LOG_FILE=run_ora_bench_release.log

echo ""
echo "You can find the run log in the file $LOG_FILE"
echo ""

exec &> >(tee -i $LOG_FILE) 2>&1
sleep .1

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
export ORA_BENCH_ORACLE_DATABASE_21C=true
export ORA_BENCH_ORACLE_DATABASE_EXISTING=false

export ORA_BENCH_FILE_CONFIGURATION_NAME=priv/properties/ora_bench.properties
export ORA_BENCH_PASSWORD_SYS=oracle

export ORA_BENCH_RUN_CX_ORACLE_PYTHON=true
export ORA_BENCH_RUN_GODROR_GO=true
export ORA_BENCH_RUN_JDBC_JAVA=true
export ORA_BENCH_RUN_JDBC_JULIA=true
export ORA_BENCH_RUN_JDBC_KOTLIN=true
export ORA_BENCH_RUN_NIMODPI_NIM=false
export ORA_BENCH_RUN_ODPI_C=false
export ORA_BENCH_RUN_ORACLE_JULIA=true
export ORA_BENCH_RUN_ORACLE_RUST=true
export ORA_BENCH_RUN_ORANIF_ELIXIR=true
export ORA_BENCH_RUN_ORANIF_ERLANG=true

echo "ORACLE_DATABASE_EXISTING         : ${ORA_BENCH_ORACLE_DATABASE_EXISTING}"
echo "ORACLE_DATABASE_18C              : ${ORA_BENCH_ORACLE_DATABASE_18C}"
echo "ORACLE_DATABASE_19C              : ${ORA_BENCH_ORACLE_DATABASE_19C}"
echo "ORACLE_DATABASE_21C              : ${ORA_BENCH_ORACLE_DATABASE_21C}"
echo "--------------------------------------------------------------------------------"
echo "RUN_CX_ORACLE_PYTHON              : ${ORA_BENCH_RUN_CX_ORACLE_PYTHON}"
echo "RUN_GODROR_GO                     : ${ORA_BENCH_RUN_GODROR_GO}"
echo "RUN_JDBC_JAVA                     : ${ORA_BENCH_RUN_JDBC_JAVA}"
echo "RUN_JDBC_JULIA                    : ${ORA_BENCH_RUN_JDBC_JULIA}"
echo "RUN_JDBC_KOTLIN                   : ${ORA_BENCH_RUN_JDBC_KOTLIN}"
echo "RUN_NIMODPI_NIM                   : ${ORA_BENCH_RUN_NIMODPI_NIM}"
echo "RUN_ODPI_C                        : ${ORA_BENCH_RUN_ODPI_C}"
echo "RUN_ORACLE_JULIA                  : ${ORA_BENCH_RUN_ORACLE_JULIA}"
echo "RUN_ORACLE_RUST                   : ${ORA_BENCH_RUN_ORACLE_RUST}"
echo "RUN_ORANIF_ELIXIR                 : ${ORA_BENCH_RUN_ORANIF_ELIXIR}"
echo "RUN_ORANIF_ERLANG                 : ${ORA_BENCH_RUN_ORANIF_ERLANG}"
echo "================================================================================"

if [ "${ORA_BENCH_ORACLE_DATABASE_EXISTING}" = "true" ] \
|| [ "${ORA_BENCH_ORACLE_DATABASE_18C}" = "true" ] \
|| [ "${ORA_BENCH_ORACLE_DATABASE_19C}" = "true" ] \
|| [ "${ORA_BENCH_ORACLE_DATABASE_21C}" = "true" ]; then
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

        export ORA_BENCH_BENCHMARK_BATCH_SIZE=0
        export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=0
        export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0

        if ! { /bin/bash scripts/run_all_drivers.sh; }; then
                exit 255
        fi

        export ORA_BENCH_BENCHMARK_BATCH_SIZE=0
        export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
        export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0

        if ! { /bin/bash scripts/run_all_drivers.sh; }; then
                exit 255
        fi

        export ORA_BENCH_BENCHMARK_BATCH_SIZE=512
        export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=0
        export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=512

        if ! { /bin/bash scripts/run_all_drivers.sh; }; then
                exit 255
        fi

        export ORA_BENCH_BENCHMARK_BATCH_SIZE=512
        export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
        export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=512

        if ! { /bin/bash scripts/run_all_drivers.sh; }; then
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

    if [ "${ORA_BENCH_ORACLE_DATABASE_21C}" = "true" ]; then
        echo "--------------------------------------------------------------------------------"
        echo "Oracle Database 21c."
        echo "--------------------------------------------------------------------------------"
        export ORA_BENCH_BENCHMARK_DATABASE=db_21_3_xe
        export ORA_BENCH_CONNECTION_SERVICE=orclpdb1
    
        if ! { /bin/bash scripts/run_db_setup.sh; }; then
            exit 255
        fi

        export ORA_BENCH_BENCHMARK_BATCH_SIZE=0
        export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=0
        export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0

        if ! { /bin/bash scripts/run_all_drivers.sh; }; then
                exit 255
        fi

        export ORA_BENCH_BENCHMARK_BATCH_SIZE=0
        export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
        export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
        
        export ORA_BENCH_RUN_JDBC_JULIA=false
        export ORA_BENCH_RUN_ORACLE_JULIA=false
        if ! { /bin/bash scripts/run_all_drivers.sh; }; then
                exit 255
        fi
        export ORA_BENCH_RUN_JDBC_JULIA=true
        export ORA_BENCH_RUN_ORACLE_JULIA=true

        export ORA_BENCH_BENCHMARK_BATCH_SIZE=512
        export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=0
        export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=512

        if ! { /bin/bash scripts/run_all_drivers.sh; }; then
                exit 255
        fi
        export ORA_BENCH_RUN_ORACLE_JL_JULIA=true

        export ORA_BENCH_BENCHMARK_BATCH_SIZE=512
        export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
        export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=512

        export ORA_BENCH_RUN_JDBC_JULIA=false
        export ORA_BENCH_RUN_ORACLE_JULIA=false
        if ! { /bin/bash scripts/run_all_drivers.sh; }; then
                exit 255
        fi
        export ORA_BENCH_RUN_JDBC_JULIA=true
        export ORA_BENCH_RUN_ORACLE_JULIA=true
    fi
fi

echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"
