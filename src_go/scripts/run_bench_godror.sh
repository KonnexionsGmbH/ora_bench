#!/bin/bash

# ------------------------------------------------------------------------------
#
# run_bench_godror.sh: Oracle Benchmark based on Go.
#
# ------------------------------------------------------------------------------

if [ -z "$ORA_BENCH_BENCHMARK_DATABASE" ]; then
    export ORA_BENCH_BENCHMARK_DATABASE=db_19_3_ee
fi
if [ -z "$ORA_BENCH_CONNECTION_HOST" ]; then
    export ORA_BENCH_CONNECTION_HOST=0.0.0.0
fi
if [ -z "$ORA_BENCH_CONNECTION_PORT" ]; then
    export ORA_BENCH_CONNECTION_PORT=1521
fi
if [ -z "$ORA_BENCH_CONNECTION_SERVICE" ]; then
    export ORA_BENCH_CONNECTION_SERVICE=orclpdb1
fi

if [ "$ORA_BENCH_MULTIPLE_RUN" != "true" ]; then
    export GOPATH=$(pwd)/src_go/go
fi

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - godror and GO."
echo "--------------------------------------------------------------------------------"
echo "MULTIPLE_RUN               : $ORA_BENCH_MULTIPLE_RUN"
echo "--------------------------------------------------------------------------------"
echo "BENCHMARK_DATABASE         : $ORA_BENCH_BENCHMARK_DATABASE"
echo "CONNECTION_HOST            : $ORA_BENCH_CONNECTION_HOST"
echo "CONNECTION_PORT            : $ORA_BENCH_CONNECTION_PORT"
echo "CONNECTION_SERVICE         : $ORA_BENCH_CONNECTION_SERVICE"
echo "--------------------------------------------------------------------------------"
echo "BENCHMARK_BATCH_SIZE       : $ORA_BENCH_BENCHMARK_BATCH_SIZE"
echo "BENCHMARK_CORE_MULTIPLIER  : $ORA_BENCH_BENCHMARK_CORE_MULTIPLIER"
echo "BENCHMARK_TRANSACTION_SIZE : $ORA_BENCH_BENCHMARK_TRANSACTION_SIZE"
echo "--------------------------------------------------------------------------------"
echo "GOPATH                     : $GOPATH"
echo "GOROOT                     : $GOROOT"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

EXITCODE="0"

if [ "$ORA_BENCH_MULTIPLE_RUN" != "true" ]; then
    go get github.com/godror/godror
    if [ $? -ne 0 ]; then
        echo "ERRORLEVEL : $?"
        exit $?
    fi
fi

go run src_go/orabench.go priv/properties/ora_bench.properties
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
