#!/bin/bash

# ----------------------------------------------------------------------------------
#
# run_create_bulk_file.sh: Oracle Benchmark Run Setup.
#
# ----------------------------------------------------------------------------------

set -e

if [ -z "${ORA_BENCH_FILE_CONFIGURATION_NAME}" ]; then
    export ORA_BENCH_FILE_CONFIGURATION_NAME=priv/properties/ora_bench.properties
fi

echo "=============================================================================="
echo "Start $0"
echo "------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - setup benchmark run."
echo "------------------------------------------------------------------------------"
echo "CHOICE_DRIVER                     : ${ORA_BENCH_CHOICE_DRIVER}"
echo "------------------------------------------------------------------------------"
echo "FILE_CONFIGURATION_NAME           : ${ORA_BENCH_FILE_CONFIGURATION_NAME}"
echo "------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "=============================================================================="

if [ "${ORA_BENCH_CHOICE_DRIVER}" = "complete" ]; then
    if ! { /bin/bash scripts/run_show_environment.sh; }; then
        exit 255
    fi
fi

if ! { /bin/bash lang/java/scripts/run_gradle.sh; }; then
    exit 255
fi

if ! java -jar priv/libs/ora_bench_java.jar setup; then
    exit 255
fi

echo ""
echo "------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "------------------------------------------------------------------------------"
echo "End   $0"
echo "=============================================================================="
