#!/bin/bash

# ------------------------------------------------------------------------------
#
# run_create_bulk_file.sh: Oracle Benchmark Run Setup.
#
# ------------------------------------------------------------------------------

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

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - setup benchmark run."
echo "--------------------------------------------------------------------------------"
echo "MULTIPLE_RUN               : $ORA_BENCH_MULTIPLE_RUN"
echo "--------------------------------------------------------------------------------"
echo "FILE_CONFIGURATION_NAME    : $ORA_BENCH_FILE_CONFIGURATION_NAME"
echo "--------------------------------------------------------------------------------"
echo "JAVA_CLASSPATH             : $ORA_BENCH_JAVA_CLASSPATH"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

EXITCODE="0"

{ /bin/bash scripts/run_show_environment.sh; }
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi

{ /bin/bash src_java/scripts/run_gradle.sh; }
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi

java -cp "$ORA_BENCH_JAVA_CLASSPATH" ch.konnexions.orabench.OraBench setup
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
