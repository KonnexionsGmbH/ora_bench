#!/bin/bash

exec &> >(tee -i run_bench.log)
sleep .1

# ------------------------------------------------------------------------------
#
# run_bench.sh: Oracle Benchmark.
#
# ------------------------------------------------------------------------------

EXITCODE="0"

export ORABENCH_FILE_RESULT_NAME=priv/ora_bench_result.csv

rm -f $ORABENCH_FILE_RESULT_NAME

if [ -z "$ORABENCH_CONNECTION_HOST" ]; then
    export ORABENCH_CONNECTION_HOST=127.0.0.1
fi
if [ -z "$ORABENCH_CONNECTION_PORT" ]; then
    export ORABENCH_CONNECTION_PORT=1521
fi
if [ -z "$ORABENCH_CONNECTION_SERVICE" ]; then
    export ORABENCH_CONNECTION_SERVICE=XE
fi

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark."
echo "--------------------------------------------------------------------------------"
date +"DATE TIME          : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

echo rm /priv/result/ora_bench_test_result.log
rm /priv/result/ora_bench_test_result.log 2> /dev/null

{ /bin/bash run_bench_setup.sh; }

{ /bin/bash run_bench_java.sh; }

EXITCODE=$?

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME          : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"

exit $EXITCODE
