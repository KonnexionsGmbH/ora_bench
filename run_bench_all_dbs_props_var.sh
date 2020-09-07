#!/bin/bash

set -e

exec &> >(tee -i run_bench_all_dbs_props_var.log)
sleep .1

# ------------------------------------------------------------------------------
#
# run_bench_all_dbs_props_var.sh: Oracle Benchmark for all database versions
#                                 with variations of properties.
#
# ------------------------------------------------------------------------------

rm -f ora_bench.log

export ORA_BENCH_MULTIPLE_RUN=true

export ORA_BENCH_BENCHMARK_COMMENT='Standard series (locally)'

export ORA_BENCH_CHOICE_DB_DEFAULT=complete
export ORA_BENCH_CHOICE_DRIVER_DEFAULT=complete

if [ -z "$ORA_BENCH_CONNECTION_HOST" ]; then
    export ORA_BENCH_CONNECTION_HOST=ora_bench_db
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
    echo "python             - Python and cx_Oracle"
    echo "---------------------------------------------------------"
    read -p "Enter the desired programming lanuage (and database driver) [default: ${ORA_BENCH_CHOICE_DRIVER_DEFAULT}] " ORA_BENCH_CHOICE_DRIVER
    export ORA_BENCH_CHOICE_DRIVER=${ORA_BENCH_CHOICE_DRIVER}

    if [ -z "${ORA_BENCH_CHOICE_DRIVER}" ]; then
        export ORA_BENCH_CHOICE_DRIVER=${ORA_BENCH_CHOICE_DRIVER_DEFAULT}
    fi
else
    export ORA_BENCH_CHOICE_DRIVER=$1
fi

export ORA_BENCH_RUN_CX_ORACLE_PYTHON=false
export ORA_BENCH_RUN_GODROR_GO=false
export ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG=false
export ORA_BENCH_RUN_JDBC_JAVA=false
export ORA_BENCH_RUN_ODPI_C=false
export ORA_BENCH_RUN_ORANIF_ELIXIR=false
export ORA_BENCH_RUN_ORANIF_ERLANG=false

if [ ${ORA_BENCH_CHOICE_DRIVER} = "complete" ]; then
    export ORA_BENCH_RUN_CX_ORACLE_PYTHON=true
    export ORA_BENCH_RUN_GODROR_GO=true
    export ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG=true
    export ORA_BENCH_RUN_JDBC_JAVA=true
    export ORA_BENCH_RUN_ODPI_C=true
    export ORA_BENCH_RUN_ORANIF_ELIXIR=true
    export ORA_BENCH_RUN_ORANIF_ERLANG=true
elif [ ${ORA_BENCH_CHOICE_DRIVER} = "c" ]; then
    export ORA_BENCH_RUN_ODPI_C=true
elif [ ${ORA_BENCH_CHOICE_DRIVER} = "elixir" ]; then
    export ORA_BENCH_RUN_ORANIF_ELIXIR=true
elif [ ${ORA_BENCH_CHOICE_DRIVER} = "erlang_jamdb" ]; then
    export ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG=true
elif [ ${ORA_BENCH_CHOICE_DRIVER} = "erlang_oranif" ]; then
    export ORA_BENCH_RUN_ORANIF_ERLANG=true
elif [ ${ORA_BENCH_CHOICE_DRIVER} = "go" ]; then
    export ORA_BENCH_RUN_GODROR_GO=true
elif [ ${ORA_BENCH_CHOICE_DRIVER} = "java" ]; then
    export ORA_BENCH_RUN_JDBC_JAVA=true
elif [ ${ORA_BENCH_CHOICE_DRIVER} = "python" ]; then
    export ORA_BENCH_RUN_CX_ORACLE_PYTHON=true
fi

if [ -z "$2" ]; then
    echo "========================================================="
    echo "complete           - All implemented variations"
    echo "---------------------------------------------------------"
    echo "12                 - Oracle Database 12c Release 2"
    echo "18                 - Oracle Database 18c"
    echo "19                 - Oracle Database 19c"
    echo "---------------------------------------------------------"
    read -p "Enter the desired database version [default: ${ORA_BENCH_CHOICE_DB_DEFAULT}] " ORA_BENCH_CHOICE_DB
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

if [ ${ORA_BENCH_CHOICE_DB} = "complete" ]; then
    export ORA_BENCH_RUN_DB_12_2_EE=true
    export ORA_BENCH_RUN_DB_18_3_EE=true
    export ORA_BENCH_RUN_DB_19_3_EE=true
elif [ ${ORA_BENCH_CHOICE_DB} = "12" ]; then
    export ORA_BENCH_RUN_DB_12_2_EE=true
elif [ ${ORA_BENCH_CHOICE_DB} = "18" ]; then
    export ORA_BENCH_RUN_DB_18_3_EE=true
elif [ ${ORA_BENCH_CHOICE_DB} = "19" ]; then
    export ORA_BENCH_RUN_DB_19_3_EE=true
fi

export ORA_BENCH_PASSWORD_SYS=oracle

if [ -z "$ORA_BENCH_FILE_CONFIGURATION_NAME" ]; then
    export ORA_BENCH_FILE_CONFIGURATION_NAME=priv/properties/ora_bench.properties
fi

if [ -z "$ORA_BENCH_JAVA_CLASSPATH" ]; then
    if [ "$OSTYPE" = "msys" ]; then
        export ORA_BENCH_JAVA_CLASSPATH=".;priv/java_jar/*"
    else
        export ORA_BENCH_JAVA_CLASSPATH=".:priv/java_jar/*"
    fi
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
echo "ora_bench - Oracle benchmark - all databases with property variations."
echo "--------------------------------------------------------------------------------"
echo "CHOICE_DB               : $ORA_BENCH_CHOICE_DB"
echo "CHOICE_DRIVER           : $ORA_BENCH_CHOICE_DRIVER"
echo "--------------------------------------------------------------------------------"
echo "BENCHMARK_COMMENT       : $ORA_BENCH_BENCHMARK_COMMENT"
echo "BULKFILE_EXISTING       : $ORA_BENCH_BULKFILE_EXISTING"
echo "CONNECTION_HOST         : $ORA_BENCH_CONNECTION_HOST"
echo "CONNECTION_PORT         : $ORA_BENCH_CONNECTION_PORT"
echo "FILE_CONFIGURATION_NAME : $ORA_BENCH_FILE_CONFIGURATION_NAME"
echo "JAVA_CLASSPATH          : $ORA_BENCH_JAVA_CLASSPATH"
echo "--------------------------------------------------------------------------------"
echo "RUN_DB_12_2_EE          : $ORA_BENCH_RUN_DB_12_2_EE"
echo "RUN_DB_18_3_EE          : $ORA_BENCH_RUN_DB_18_3_EE"
echo "RUN_DB_19_3_EE          : $ORA_BENCH_RUN_DB_19_3_EE"
echo "--------------------------------------------------------------------------------"
echo "RUN_GLOBAL_JAMDB        : $RUN_GLOBAL_JAMDB"
echo "RUN_GLOBAL_NON_JAMDB    : $RUN_GLOBAL_NON_JAMDB"
echo "--------------------------------------------------------------------------------"
echo "RUN_CX_ORACLE_PYTHON    : $ORA_BENCH_RUN_CX_ORACLE_PYTHON"
echo "RUN_GODROR_GO           : $ORA_BENCH_RUN_GODROR_GO"
echo "RUN_JAMDB_ORACLE_ERLANG : $ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG"
echo "RUN_JDBC_JAVA           : $ORA_BENCH_RUN_JDBC_JAVA"
echo "RUN_ODPI_C              : $ORA_BENCH_RUN_ODPI_C"
echo "RUN_ORANIF_ELIXIR       : $ORA_BENCH_RUN_ORANIF_ELIXIR"
echo "RUN_ORANIF_ERLANG       : $ORA_BENCH_RUN_ORANIF_ERLANG"
echo "--------------------------------------------------------------------------------"
echo "JAVA_CLASSPATH          : $ORA_BENCH_JAVA_CLASSPATH"
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
