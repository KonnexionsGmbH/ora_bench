#!/bin/bash

set -e

export ORA_BENCH_PROPERTIES=variations
export ORA_BENCH_PROPERTIES=standard

# ----------------------------------------------------------------------------------
#
# run_ora_bench.sh: Oracle Benchmark for all database versions
#                   with ${ORA_BENCH_PROPERTIES} properties.
#
# ----------------------------------------------------------------------------------

export ORA_BENCH_BENCHMARK_COMMENT='Standard tests (locally)'

export ORA_BENCH_BENCHMARK_DATABASE_DEFAULT=21
export ORA_BENCH_CHOICE_DRIVER_DEFAULT=none
export ORA_BENCH_CONNECTION_HOST_DEFAULT=localhost
export ORA_BENCH_CONNECTION_PORT_DEFAULT=1521

rm -f ora_bench.log
rm -f priv/ora_bench_result.csv
rm -f priv/ora_bench_result.tsv

if [ -z "${ORA_BENCH_CONNECTION_HOST}" ]; then
    export ORA_BENCH_CONNECTION_HOST=${ORA_BENCH_CONNECTION_HOST_DEFAULT}
fi
if [ -z "${ORA_BENCH_CONNECTION_PORT}" ]; then
    export ORA_BENCH_CONNECTION_PORT=${ORA_BENCH_CONNECTION_PORT_DEFAULT}
fi

if [ -z "$1" ]; then
    echo "=============================================================================="
    echo "complete           - All implemented variations"
    echo "none               - Without specific driver run"
    echo "------------------------------------------------------------------------------"
    echo "c                  - C++ [gcc] and Oracle ODPI-C"
    echo "elixir             - Elixir and oranif"
    echo "erlang             - Erlang and oranif"
    echo "go                 - Go and godror"
    echo "java               - Java and Oracle JDBC"
    echo "julia_jdbc         - Julia and JDBC.jl"
    echo "julia_oracle       - Julia and Oracle.jl"
    echo "kotlin             - Kotlin and Oracle JDBC"
    echo "nim                - Nim and nimodpi"
    echo "python             - Python 3 and cx_Oracle"
    echo "rust               - Rust and Rust-oracle"
    echo "------------------------------------------------------------------------------"
    read -rp "Enter the desired programming language (and database driver) [default: ${ORA_BENCH_CHOICE_DRIVER_DEFAULT}] " ORA_BENCH_CHOICE_DRIVER
    export ORA_BENCH_CHOICE_DRIVER=${ORA_BENCH_CHOICE_DRIVER}

    if [ -z "${ORA_BENCH_CHOICE_DRIVER}" ]; then
        export ORA_BENCH_CHOICE_DRIVER=${ORA_BENCH_CHOICE_DRIVER_DEFAULT}
    fi
else
    export ORA_BENCH_CHOICE_DRIVER=$1
fi

if [ -z "$2" ]; then
    echo "=============================================================================="
    echo "complete           - All implemented variations"
    echo "------------------------------------------------------------------------------"
    echo "18xe               - Oracle Database 18c Express Edition"
    echo "19                 - Oracle Database 19c"
    echo "21                 - Oracle Database 21c"
    echo "21xe               - Oracle Database 21c Express Edition"
    echo "------------------------------------------------------------------------------"
    read -rp "Enter the desired database version [default: ${ORA_BENCH_BENCHMARK_DATABASE_DEFAULT}] " ORA_BENCH_CHOICE_DB
    export ORA_BENCH_CHOICE_DB=${ORA_BENCH_CHOICE_DB}

    if [ -z "${ORA_BENCH_CHOICE_DB}" ]; then
        export ORA_BENCH_CHOICE_DB=${ORA_BENCH_BENCHMARK_DATABASE_DEFAULT}
    fi
else
    export ORA_BENCH_CHOICE_DB=$2
fi

export ORA_BENCH_RUN_DB_18_4_XE=false
export ORA_BENCH_RUN_DB_19_3_EE=false
export ORA_BENCH_RUN_DB_21_3_EE=false
export ORA_BENCH_RUN_DB_21_3_XE=false

if [ "${ORA_BENCH_CHOICE_DB}" = "complete" ]; then
    export ORA_BENCH_RUN_DB_18_4_XE=true
    export ORA_BENCH_RUN_DB_19_3_EE=true
    export ORA_BENCH_RUN_DB_21_3_EE=true
    export ORA_BENCH_RUN_DB_21_3_XE=true
elif [ "${ORA_BENCH_CHOICE_DB}" = "18xe" ]; then
    export ORA_BENCH_RUN_DB_18_4_XE=true
elif [ "${ORA_BENCH_CHOICE_DB}" = "19" ]; then
    export ORA_BENCH_RUN_DB_19_3_EE=true
elif [ "${ORA_BENCH_CHOICE_DB}" = "21" ]; then
    export ORA_BENCH_RUN_DB_21_3_EE=true
elif [ "${ORA_BENCH_CHOICE_DB}" = "21xe" ]; then
    export ORA_BENCH_RUN_DB_21_3_XE=true
fi

export ORA_BENCH_PASSWORD_SYS=oracle

if [ -z "${ORA_BENCH_FILE_CONFIGURATION_NAME}" ]; then
    export ORA_BENCH_FILE_CONFIGURATION_NAME=priv/properties/ora_bench.properties
fi

echo ""
echo "Script $0 is now running"

export LOG_FILE=run_ora_bench.log

echo ""
echo "You can find the run log in the file $LOG_FILE"
echo ""

exec &> >(tee -i $LOG_FILE) 2>&1
sleep .1

echo "=============================================================================="
echo "Start $0"
echo "------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - all databases with ${ORA_BENCH_PROPERTIES} properties."
echo "------------------------------------------------------------------------------"
echo "CHOICE_DRIVER                     : ${ORA_BENCH_CHOICE_DRIVER}"
echo "CHOICE_DB                         : ${ORA_BENCH_CHOICE_DB}"
echo "------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "=============================================================================="

if ! { /bin/bash scripts/run_create_bulk_file.sh; }; then
    exit 255
fi

export ORA_BENCH_BULKFILE_EXISTING=true

if [ "${ORA_BENCH_RUN_DB_18_4_XE}" = "true" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_18_4_xe
    export ORA_BENCH_CONNECTION_SERVICE=xe
    if ! { /bin/bash scripts/run_properties_${ORA_BENCH_PROPERTIES}.sh; }; then
        exit 255
    fi
fi

if [ "${ORA_BENCH_RUN_DB_19_3_EE}" = "true" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_19_3_ee
    export ORA_BENCH_CONNECTION_SERVICE=orclpdb1
    if ! { /bin/bash scripts/run_properties_${ORA_BENCH_PROPERTIES}.sh; }; then
        exit 255
    fi
fi

if [ "${ORA_BENCH_RUN_DB_21_3_EE}" = "true" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_21_3_ee
    export ORA_BENCH_CONNECTION_SERVICE=orclpdb1
    if ! { /bin/bash scripts/run_properties_${ORA_BENCH_PROPERTIES}.sh; }; then
        exit 255
    fi
fi

if [ "${ORA_BENCH_RUN_DB_21_3_XE}" = "true" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_21_3_xe
    export ORA_BENCH_CONNECTION_SERVICE=xe 
    if ! { /bin/bash scripts/run_properties_${ORA_BENCH_PROPERTIES}.sh; }; then
        exit 255
    fi
fi

echo ""
echo "------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "------------------------------------------------------------------------------"
echo "End   $0"
echo "=============================================================================="
