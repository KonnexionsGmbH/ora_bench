#!/bin/bash

# ----------------------------------------------------------------------------------
#
# run_bench_cx_oracle.sh: Oracle Benchmark based on Python.
#
# ----------------------------------------------------------------------------------

if [ -z "${ORA_BENCH_BENCHMARK_DATABASE}" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_21_3_xe
fi
if [ -z "${ORA_BENCH_CONNECTION_HOST}" ]; then
    export ORA_BENCH_CONNECTION_HOST=localhost
fi
if [ -z "${ORA_BENCH_CONNECTION_PORT}" ]; then
    export ORA_BENCH_CONNECTION_PORT=1521
fi
if [ -z "${ORA_BENCH_CONNECTION_SERVICE}" ]; then
    export ORA_BENCH_CONNECTION_SERVICE=orclpdb1
fi

export ORA_BENCH_FILE_CONFIGURATION_NAME=priv/properties/ora_bench.properties

echo "=============================================================================="
echo "Start $0"
echo "------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - cx_Oracle and Python 3."
echo "------------------------------------------------------------------------------"
echo "MULTIPLE_RUN                   : ${ORA_BENCH_MULTIPLE_RUN}"
echo "------------------------------------------------------------------------------"
echo "BENCHMARK_DATABASE             : ${ORA_BENCH_BENCHMARK_DATABASE}"
echo "CONNECTION_HOST                : ${ORA_BENCH_CONNECTION_HOST}"
echo "CONNECTION_PORT                : ${ORA_BENCH_CONNECTION_PORT}"
echo "CONNECTION_SERVICE             : ${ORA_BENCH_CONNECTION_SERVICE}"
echo "------------------------------------------------------------------------------"
echo "BENCHMARK_BATCH_SIZE           : ${ORA_BENCH_BENCHMARK_BATCH_SIZE}"
echo "BENCHMARK_CORE_MULTIPLIER      : ${ORA_BENCH_BENCHMARK_CORE_MULTIPLIER}"
echo "BENCHMARK_TRANSACTION_SIZE     : ${ORA_BENCH_BENCHMARK_TRANSACTION_SIZE}"
echo "------------------------------------------------------------------------------"
echo "FILE_CONFIGURATION_NAME        : ${ORA_BENCH_FILE_CONFIGURATION_NAME}"
echo "------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "=============================================================================="

if [ "${ORA_BENCH_MULTIPLE_RUN}" != "true" ]; then
    if ! python3 -m pip install --upgrade pip; then
        exit 255
    fi
    
    if ! python3 -m pip install -r lang/python/requirements.txt; then
        exit 255
    fi
    
    echo "=============================================================================> Version Python: "
    echo " "
    echo "Current version of Python: $(python3 --version)"
    echo " "
    echo "Current version of pip: $(python3 -m pip --version)"
    echo " "
    python3 -m pip freeze | grep -E -i 'cx_oracle|PyYAML'
    echo " "
    echo "=============================================================================>"
    
    if ! python3 -m compileall lang/python/OraBench.py; then
        exit 255
    fi

    if ! { /bin/bash lang/java/scripts/run_gradle.sh; }; then
        exit 255
    fi

    if ! java -jar priv/libs/ora_bench_java.jar setup_python; then
        exit 255
    fi
fi

if ! python3 lang/python/__pycache__/OraBench.cpython-310.pyc; then
    exit 255
fi

echo ""
echo "------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "------------------------------------------------------------------------------"
echo "End   $0"
echo "=============================================================================="
