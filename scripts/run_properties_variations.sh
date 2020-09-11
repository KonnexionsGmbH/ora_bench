#!/bin/bash

# ------------------------------------------------------------------------------
#
# run_properties_variations.sh: Run with variations of properties.
#
# ------------------------------------------------------------------------------

set -e

export ORA_BENCH_MULTIPLE_RUN=true

if [ -z "$ORA_BENCH_CHOICE_DRIVER" ]; then
    export ORA_BENCH_CHOICE_DRIVER=complete
fi
if [ -z "$ORA_BENCH_CHOICE_DB" ]; then
    export ORA_BENCH_CHOICE_DB=complete
fi

export ORA_BENCH_RUN_CX_ORACLE_PYTHON=false
export ORA_BENCH_RUN_GODROR_GO=false
export ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG=false
export ORA_BENCH_RUN_JDBC_JAVA=false
export ORA_BENCH_RUN_JDBC_KOTLIN=false
export ORA_BENCH_RUN_ODPI_C=false
export ORA_BENCH_RUN_ORANIF_ELIXIR=false
export ORA_BENCH_RUN_ORANIF_ERLANG=false

if [ "${ORA_BENCH_CHOICE_DRIVER}" = "complete" ]; then
    export ORA_BENCH_RUN_CX_ORACLE_PYTHON=true
    export ORA_BENCH_RUN_GODROR_GO=true
    export ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG=true
    export ORA_BENCH_RUN_JDBC_JAVA=true
    export ORA_BENCH_RUN_JDBC_KOTLIN=true
    export ORA_BENCH_RUN_ODPI_C=true
    export ORA_BENCH_RUN_ORANIF_ELIXIR=true
    export ORA_BENCH_RUN_ORANIF_ERLANG=true
elif [ "${ORA_BENCH_CHOICE_DRIVER}" = "c" ]; then
    export ORA_BENCH_RUN_ODPI_C=true
elif [ "${ORA_BENCH_CHOICE_DRIVER}" = "elixir" ]; then
    export ORA_BENCH_RUN_ORANIF_ELIXIR=true
elif [ "${ORA_BENCH_CHOICE_DRIVER}" = "erlang_jamdb" ]; then
    export ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG=true
elif [ "${ORA_BENCH_CHOICE_DRIVER}" = "erlang_oranif" ]; then
    export ORA_BENCH_RUN_ORANIF_ERLANG=true
elif [ "${ORA_BENCH_CHOICE_DRIVER}" = "go" ]; then
    export ORA_BENCH_RUN_GODROR_GO=true
elif [ "${ORA_BENCH_CHOICE_DRIVER}" = "java" ]; then
    export ORA_BENCH_RUN_JDBC_JAVA=true
elif [ "${ORA_BENCH_CHOICE_DRIVER}" = "kotlin" ]; then
    export ORA_BENCH_RUN_JDBC_KOTLIN=true
elif [ "${ORA_BENCH_CHOICE_DRIVER}" = "python" ]; then
    export ORA_BENCH_RUN_CX_ORACLE_PYTHON=true
fi

if [ -z "$ORA_BENCH_BENCHMARK_DATABASE" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_19_3_ee
fi
if [ -z "$ORA_BENCH_CONNECTION_HOST" ]; then
    export ORA_BENCH_CONNECTION_HOST=ora_bench_db
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
echo "ora_bench - Oracle benchmark - Run with variations of properties."
echo "--------------------------------------------------------------------------------"
echo "MULTIPLE_RUN                  : $ORA_BENCH_MULTIPLE_RUN"
echo "--------------------------------------------------------------------------------"
echo "CHOICE_DB                     : $ORA_BENCH_CHOICE_DB"
echo "CHOICE_DRIVER                 : $ORA_BENCH_CHOICE_DRIVER"
echo "--------------------------------------------------------------------------------"
echo "ORA_BENCH_BENCHMARK_JAMDB     : $ORA_BENCH_BENCHMARK_JAMDB"
echo "RUN_GLOBAL_JAMDB              : $RUN_GLOBAL_JAMDB"
echo "RUN_GLOBAL_NON_JAMDB          : $RUN_GLOBAL_NON_JAMDB"
echo "--------------------------------------------------------------------------------"
echo "RUN_CX_ORACLE_PYTHON          : $ORA_BENCH_RUN_CX_ORACLE_PYTHON"
echo "RUN_GODROR_GO                 : $ORA_BENCH_RUN_GODROR_GO"
echo "RUN_JAMDB_ORACLE_ERLANG       : $ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG"
echo "RUN_JDBC_JAVA                 : $ORA_BENCH_RUN_JDBC_JAVA"
echo "RUN_JDBC_KOTLIN               : $ORA_BENCH_RUN_JDBC_KOTLIN"
echo "RUN_ODPI_C                    : $ORA_BENCH_RUN_ODPI_C"
echo "RUN_ORANIF_ELIXIR             : $ORA_BENCH_RUN_ORANIF_ELIXIR"
echo "RUN_ORANIF_ERLANG             : $ORA_BENCH_RUN_ORANIF_ERLANG"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

if ! { /bin/bash scripts/run_collect_and_compile.sh; }; then
    exit 255
fi

if ! { /bin/bash scripts/run_db_setup.sh; }; then
    exit 255
fi

# #01
export ORA_BENCH_BENCHMARK_BATCH_SIZE=$ORA_BENCH_BENCHMARK_BATCH_SIZE_DEFAULT
export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=$ORA_BENCH_BENCHMARK_CORE_MULTIPLIER_DEFAULT
export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=$ORA_BENCH_BENCHMARK_TRANSACTION_SIZE_DEFAULT
if ! { /bin/bash scripts/run_bench_all_drivers.sh; }; then
    exit 255
fi

# #02
export ORA_BENCH_BENCHMARK_BATCH_SIZE=$ORA_BENCH_BENCHMARK_BATCH_SIZE_DEFAULT
export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=$ORA_BENCH_BENCHMARK_TRANSACTION_SIZE_DEFAULT
if ! { /bin/bash scripts/run_bench_all_drivers.sh; }; then
    exit 255
fi

# #03
export ORA_BENCH_BENCHMARK_BATCH_SIZE=0
export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=$ORA_BENCH_BENCHMARK_CORE_MULTIPLIER_DEFAULT
export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=$ORA_BENCH_BENCHMARK_TRANSACTION_SIZE_DEFAULT
if ! { /bin/bash scripts/run_bench_all_drivers.sh; }; then
    exit 255
fi

# #04
export ORA_BENCH_BENCHMARK_BATCH_SIZE=0
export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=$ORA_BENCH_BENCHMARK_CORE_MULTIPLIER_DEFAULT
export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
if ! { /bin/bash scripts/run_bench_all_drivers.sh; }; then
    exit 255
fi

# #05
export ORA_BENCH_BENCHMARK_BATCH_SIZE=0
export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=$ORA_BENCH_BENCHMARK_TRANSACTION_SIZE_DEFAULT
if ! { /bin/bash scripts/run_bench_all_drivers.sh; }; then
    exit 255
fi

# #06
export ORA_BENCH_BENCHMARK_BATCH_SIZE=0
export ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
export ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
if ! { /bin/bash scripts/run_bench_all_drivers.sh; }; then
    exit 255
fi

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"
