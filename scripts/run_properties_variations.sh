#!/bin/bash

# ----------------------------------------------------------------------------------
#
# run_properties_variations.sh: Run with variations of properties.
#
# ----------------------------------------------------------------------------------

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
export ORA_BENCH_RUN_JDBC_JAVA=false
export ORA_BENCH_RUN_JDBC_KOTLIN=false
export ORA_BENCH_RUN_ODPI_C=false
export ORA_BENCH_RUN_ORACLE_JL_JULIA=false
export ORA_BENCH_RUN_ORANIF_ELIXIR=false
export ORA_BENCH_RUN_ORANIF_ERLANG=false

if [ "${ORA_BENCH_CHOICE_DRIVER}" = "complete" ]; then
    export ORA_BENCH_RUN_CX_ORACLE_PYTHON=true
    export ORA_BENCH_RUN_GODROR_GO=true
    export ORA_BENCH_RUN_JDBC_JAVA=true
    export ORA_BENCH_RUN_JDBC_KOTLIN=true
    export ORA_BENCH_RUN_ODPI_C=true
    export ORA_BENCH_RUN_ORACLE_JL_JULIA=true
    export ORA_BENCH_RUN_ORANIF_ELIXIR=true
    export ORA_BENCH_RUN_ORANIF_ERLANG=true
elif [ "${ORA_BENCH_CHOICE_DRIVER}" = "c" ]; then
    export ORA_BENCH_RUN_ODPI_C=true
elif [ "${ORA_BENCH_CHOICE_DRIVER}" = "elixir" ]; then
    export ORA_BENCH_RUN_ORANIF_ELIXIR=true
elif [ "${ORA_BENCH_CHOICE_DRIVER}" = "erlang" ]; then
    export ORA_BENCH_RUN_ORANIF_ERLANG=true
elif [ "${ORA_BENCH_CHOICE_DRIVER}" = "go" ]; then
    export ORA_BENCH_RUN_GODROR_GO=true
elif [ "${ORA_BENCH_CHOICE_DRIVER}" = "java" ]; then
    export ORA_BENCH_RUN_JDBC_JAVA=true
elif [ "${ORA_BENCH_CHOICE_DRIVER}" = "julia" ]; then
    export ORA_BENCH_RUN_ORACLE_JL_JULIA=true
elif [ "${ORA_BENCH_CHOICE_DRIVER}" = "kotlin" ]; then
    export ORA_BENCH_RUN_JDBC_KOTLIN=true
elif [ "${ORA_BENCH_CHOICE_DRIVER}" = "python" ]; then
    export ORA_BENCH_RUN_CX_ORACLE_PYTHON=true
fi

if [ "${ORA_BENCH_CHOICE_DB}" = "18" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_18_4_xe
fi
if [ "${ORA_BENCH_CHOICE_DB}" = "19" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_19_3_ee
fi
if [ "${ORA_BENCH_CHOICE_DB}" = "21" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_21_3_ee
fi

if [ -z "$ORA_BENCH_CONNECTION_HOST" ]; then
    export ORA_BENCH_CONNECTION_HOST=localhost
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

echo "=============================================================================="
echo "Start $0"
echo "------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - Run with variations of properties."
echo "------------------------------------------------------------------------------"
echo "MULTIPLE_RUN                      : $ORA_BENCH_MULTIPLE_RUN"
echo "------------------------------------------------------------------------------"
echo "BENCHMARK_DATABASE                : $ORA_BENCH_BENCHMARK_DATABASE"
echo "CHOICE_DRIVER                     : $ORA_BENCH_CHOICE_DRIVER"
echo "------------------------------------------------------------------------------"
echo "RUN_CX_ORACLE_PYTHON              : $ORA_BENCH_RUN_CX_ORACLE_PYTHON"
echo "RUN_GODROR_GO                     : $ORA_BENCH_RUN_GODROR_GO"
echo "RUN_JDBC_JAVA                     : $ORA_BENCH_RUN_JDBC_JAVA"
echo "RUN_JDBC_KOTLIN                   : $ORA_BENCH_RUN_JDBC_KOTLIN"
echo "RUN_ODPI_C                        : $ORA_BENCH_RUN_ODPI_C"
echo "RUN_ORACLE_JL_JULIA               : $ORA_BENCH_RUN_ORACLE_JL_JULIA"
echo "RUN_ORANIF_ELIXIR                 : $ORA_BENCH_RUN_ORANIF_ELIXIR"
echo "RUN_ORANIF_ERLANG                 : $ORA_BENCH_RUN_ORANIF_ERLANG"
echo "------------------------------------------------------------------------------"
echo "RUN_DB_18_4_EE                    : $ORA_BENCH_RUN_DB_18_4_XE"
echo "RUN_DB_19_3_EE                    : $ORA_BENCH_RUN_DB_19_3_EE"
echo "RUN_DB_21_3_EE                    : $ORA_BENCH_RUN_DB_21_3_EE"
echo "------------------------------------------------------------------------------"
echo "BENCHMARK_BATCH_SIZE              : $ORA_BENCH_BENCHMARK_BATCH_SIZE"
echo "BENCHMARK_COMMENT                 : $ORA_BENCH_BENCHMARK_COMMENT"
echo "BENCHMARK_TRANSACTION_SIZE        : $ORA_BENCH_BENCHMARK_TRANSACTION_SIZE"
echo "BULKFILE_EXISTING                 : $ORA_BENCH_BULKFILE_EXISTING"
echo "CONNECTION_HOST                   : $ORA_BENCH_CONNECTION_HOST"
echo "CONNECTION_PORT                   : $ORA_BENCH_CONNECTION_PORT"
echo "FILE_CONFIGURATION_NAME           : $ORA_BENCH_FILE_CONFIGURATION_NAME"
echo "------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "=============================================================================="

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
echo "------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "------------------------------------------------------------------------------"
echo "End   $0"
echo "=============================================================================="
