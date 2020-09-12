#!/bin/bash

set -e

exec &> >(tee -i run_bench_all_dbs_props_std.log)
sleep .1

# ------------------------------------------------------------------------------
#
# run_bench_all_dbs_props_std.sh: Oracle Benchmark for all database versions
#                                 with standard properties.
#
# ------------------------------------------------------------------------------

export ORA_BENCH_BENCHMARK_COMMENT='Standard tests (locally)'

rm -f ora_bench.log

export ORA_BENCH_CHOICE_DB_DEFAULT=complete
export ORA_BENCH_CHOICE_DRIVER_DEFAULT=complete

if [ -z "$ORA_BENCH_CONNECTION_HOST" ]; then
    export ORA_BENCH_CONNECTION_HOST=localhost
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
    echo "erlang_jamdb       - Erlang and JamDB"
    echo "erlang_oranif      - Erlang and oranif"
    echo "go                 - Go and GoDROR"
    echo "java               - Java and JDBC"
    echo "kotlin             - Kotlin and JDBC"
    echo "python             - Python and cx_Oracle"
    echo "---------------------------------------------------------"
    read -pr "Enter the desired programming lanuage (and database driver) [default: ${ORA_BENCH_CHOICE_DRIVER_DEFAULT}] " ORA_BENCH_CHOICE_DRIVER
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
    read -pr "Enter the desired database version [default: ${ORA_BENCH_CHOICE_DB_DEFAULT}] " ORA_BENCH_CHOICE_DB
    export ORA_BENCH_CHOICE_DB=${ORA_BENCH_CHOICE_DB}

    if [ -z "${ORA_BENCH_CHOICE_DB}" ]; then
        export ORA_BENCH_CHOICE_DB=${ORA_BENCH_CHOICE_DB}
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

if [ -z "$RUN_GLOBAL_JAMDB" ]; then
    export RUN_GLOBAL_JAMDB=true
fi
if [ -z "$RUN_GLOBAL_NON_JAMDB" ]; then
    export RUN_GLOBAL_NON_JAMDB=true
fi

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - all databases with standard properties."
echo "--------------------------------------------------------------------------------"
echo "CHOICE_DRIVER                     : $ORA_BENCH_CHOICE_DRIVER"
echo "CHOICE_DB                         : $ORA_BENCH_CHOICE_DB"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

if ! { /bin/bash scripts/run_create_bulk_file.sh; }; then
    exit 255
fi

export ORA_BENCH_BULKFILE_EXISTING=true

 if [ "$ORA_BENCH_RUN_DB_12_2_EE" = "true" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_12_2_ee
    export ORA_BENCH_CONNECTION_SERVICE=orclpdb1
    if ! { /bin/bash scripts/run_properties_standard.sh; }; then
        exit 255
    fi
fi

if [ "$ORA_BENCH_RUN_DB_18_3_EE" = "true" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_18_3_ee
    export ORA_BENCH_CONNECTION_SERVICE=orclpdb1
    if ! { /bin/bash scripts/run_properties_standard.sh; }; then
        exit 255
    fi
fi

if [ "$ORA_BENCH_RUN_DB_19_3_EE" = "true" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_19_3_ee
    export ORA_BENCH_CONNECTION_SERVICE=orclpdb1
    if ! { /bin/bash scripts/run_properties_standard.sh; }; then
        exit 255
    fi
fi

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"
