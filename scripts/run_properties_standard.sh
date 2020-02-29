#!/bin/bash

# ------------------------------------------------------------------------------
#
# run_properties_standard.sh: Run with standard properties.
#
# ------------------------------------------------------------------------------

export ORA_BENCH_MULTIPLE_RUN=true

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
echo "ora_bench - Oracle benchmark - run with standard properties."
echo "--------------------------------------------------------------------------------"
echo "MULTIPLE_RUN               : $ORA_BENCH_MULTIPLE_RUN"
echo "--------------------------------------------------------------------------------"
echo "ORA_BENCH_BENCHMARK_JAMDB  : $ORA_BENCH_BENCHMARK_JAMDB"
echo "RUN_GLOBAL_JAMDB           : $RUN_GLOBAL_JAMDB"
echo "RUN_GLOBAL_NON_JAMDB       : $RUN_GLOBAL_NON_JAMDB"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

EXITCODE="0"

{ /bin/bash scripts/run_collect_and_compile.sh; }
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi

{ /bin/bash scripts/run_db_setup.sh; }
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi

{ /bin/bash scripts/run_bench_all_drivers.sh; }
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi

EXITCODE=$?

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"

exit $EXITCODE
