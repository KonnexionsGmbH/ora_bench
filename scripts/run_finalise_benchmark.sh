#!/bin/bash

# ----------------------------------------------------------------------------------
#
# run_finalise_benchmark.sh: Finalise Oracle benchmark run.
#
# ----------------------------------------------------------------------------------

set -e

export ORA_BENCH_FILE_CONFIGURATION_NAME_DEFAULT=priv/properties/ora_bench.properties

if [ -z "${ORA_BENCH_FILE_CONFIGURATION_NAME}" ]; then
    export ORA_BENCH_FILE_CONFIGURATION_NAME=${ORA_BENCH_FILE_CONFIGURATION_NAME_DEFAULT}
fi

echo "=============================================================================="
echo "Start $0"
echo "------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - finalise benchmark run."
echo "------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "=============================================================================="

if ! java -jar priv/libs/ora_bench_java.jar finalise; then
    exit 255
fi

echo ""
echo "------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "------------------------------------------------------------------------------"
echo "End   $0"
echo "=============================================================================="
