#!/bin/bash

set -e

# ------------------------------------------------------------------------------
#
# run_bench_all_dbs_props_var.sh: Oracle Benchmark for all database versions
#                                 with variations of properties.
#
# ------------------------------------------------------------------------------

export ORA_BENCH_MULTIPLE_RUN=true

export ORA_BENCH_BENCHMARK_COMMENT='Standard series (locally)'

rm -f ora_bench.log

export ORA_BENCH_CHOICE_DB_DEFAULT=complete
export ORA_BENCH_CHOICE_DRIVER_DEFAULT=complete

if [ -z "$ORA_BENCH_CONNECTION_HOST" ]; then
    export ORA_BENCH_CONNECTION_HOST=0.0.0.0
fi
if [ -z "$ORA_BENCH_CONNECTION_PORT" ]; then
    export ORA_BENCH_CONNECTION_PORT=1521
fi

if [ -z "$1" ]; then
    echo "========================================================="
    echo "complete           - All implemented variations"
    echo "---------------------------------------------------------"
    echo "c                  - C and ODPI"
    echo "elixir             - Elixir and oranif"
    echo "erlang             - Erlang and oranif"
    echo "go                 - Go and GoDROR"
    echo "java               - Java and JDBC"
    echo "kotlin             - Kotlin and JDBC"
    echo "python             - Python and cx_Oracle"
    echo "---------------------------------------------------------"
    read -rp "Enter the desired programming lanuage (and database driver) [default: ${ORA_BENCH_CHOICE_DRIVER_DEFAULT}] " ORA_BENCH_CHOICE_DRIVER
    export ORA_BENCH_CHOICE_DRIVER=${ORA_BENCH_CHOICE_DRIVER}

    if [ -z "${ORA_BENCH_CHOICE_DRIVER}" ]; then
        export ORA_BENCH_CHOICE_DRIVER=${ORA_BENCH_CHOICE_DRIVER_DEFAULT}
    fi
else
    export ORA_BENCH_CHOICE_DRIVER=$1
fi

if [ -z "$2" ]; then
    echo "========================================================="
    echo "complete           - All implemented variations"
    echo "---------------------------------------------------------"
    echo "12                 - Oracle Database 12c Release 2"
    echo "18                 - Oracle Database 18c"
    echo "19                 - Oracle Database 19c"
    echo "---------------------------------------------------------"
    read -rp "Enter the desired database version [default: ${ORA_BENCH_CHOICE_DB_DEFAULT}] " ORA_BENCH_CHOICE_DB
    export ORA_BENCH_CHOICE_DB=${ORA_BENCH_CHOICE_DB}

    if [ -z "${ORA_BENCH_CHOICE_DB}" ]; then
        export ORA_BENCH_CHOICE_DB=${ORA_BENCH_CHOICE_DB_DEFAULT}
    fi
else
    export ORA_BENCH_CHOICE_DB=$2
fi

export ORA_BENCH_RUN_DB_12_2_EE=false
export ORA_BENCH_RUN_DB_18_3_EE=false
export ORA_BENCH_RUN_DB_19_3_EE=false

if [ "${ORA_BENCH_CHOICE_DB}" = "complete" ]; then
    export ORA_BENCH_RUN_DB_12_2_EE=true
    export ORA_BENCH_RUN_DB_18_3_EE=true
    export ORA_BENCH_RUN_DB_19_3_EE=true
elif [ "${ORA_BENCH_CHOICE_DB}" = "12" ]; then
    export ORA_BENCH_RUN_DB_12_2_EE=true
elif [ "${ORA_BENCH_CHOICE_DB}" = "18" ]; then
    export ORA_BENCH_RUN_DB_18_3_EE=true
elif [ "${ORA_BENCH_CHOICE_DB}" = "19" ]; then
    export ORA_BENCH_RUN_DB_19_3_EE=true
fi

export ORA_BENCH_PASSWORD_SYS=oracle

if [ -z "$ORA_BENCH_FILE_CONFIGURATION_NAME" ]; then
    export ORA_BENCH_FILE_CONFIGURATION_NAME=priv/properties/ora_bench.properties
fi

echo ""
echo "Script $0 is now running"

export LOG_FILE=run_bench_all_dbs_props_var.log

echo ""
echo "You can find the run log in the file $LOG_FILE"
echo ""

exec &> >(tee -i $LOG_FILE) 2>&1
sleep .1

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - all databases with property variations."
echo "--------------------------------------------------------------------------------"
echo "CHOICE_DRIVER                     : $ORA_BENCH_CHOICE_DRIVER"
echo "CHOICE_DB                         : $ORA_BENCH_CHOICE_DB"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

export ORA_BENCH_BENCHMARK_BATCH_SIZE_DEFAULT=256
export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER_DEFAULT=0
export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE_DEFAULT=512

if [ "$ORA_BENCH_RUN_DB_12_2_EE" = "true" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_12_2_ee
    export ORA_BENCH_CONNECTION_SERVICE=orclpdb1
    if ! { /bin/bash scripts/run_properties_variations.sh; }; then
        exit 255
    fi
fi

if [ "$ORA_BENCH_RUN_DB_18_3_EE" = "true" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_18_3_ee
    export ORA_BENCH_CONNECTION_SERVICE=orclpdb1
    if ! { /bin/bash scripts/run_properties_variations.sh; }; then
        exit 255
    fi
fi

if [ "$ORA_BENCH_RUN_DB_19_3_EE" = "true" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_19_3_ee
    export ORA_BENCH_CONNECTION_SERVICE=orclpdb1
    if ! { /bin/bash scripts/run_properties_variations.sh; }; then
        exit 255
    fi
fi

export ORA_BENCH_BENCHMARK_BATCH_SIZE=$ORA_BENCH_BENCHMARK_BATCH_SIZE_DEFAULT
export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER_DEFAULT=$ORA_BENCH_BENCHMARK_CORE_MULTIPLIER_DEFAULT
export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=$ORA_BENCH_BENCHMARK_TRANSACTION_SIZE_DEFAULT

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"

if ! start priv/audio/end_of_series.mp3; then
    exit 255
fi
