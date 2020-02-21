#!/bin/bash

# ------------------------------------------------------------------------------
#
# run_create_bulk_file.sh: Oracle Benchmark Run Setup.
#
# ------------------------------------------------------------------------------

export ORA_BENCH_MULTIPLE_RUN=

if [ -z "$ORA_BENCH_FILE_CONFIGURATION_NAME" ]; then
    export ORA_BENCH_FILE_CONFIGURATION_NAME=priv/properties/ora_bench.properties
fi

if [ "$OSTYPE" = "msys" ]; then
    export ORA_BENCH_JAVA_CLASSPATH=".;priv/java_jar/*"
else
    export ORA_BENCH_JAVA_CLASSPATH=".:priv/java_jar/*"
fi

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - setup benchmark run."
echo "--------------------------------------------------------------------------------"
echo "FILE_CONFIGURATION_NAME : $ORA_BENCH_FILE_CONFIGURATION_NAME"
echo "JAVA_CLASSPATH          : $ORA_BENCH_JAVA_CLASSPATH"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

EXITCODE="0"

{ /bin/bash src_java/scripts/run_gradle.sh; }

PATH=$PATH:/u01/app/oracle/product/12.2/db_1/jdbc/lib

java -cp "$ORA_BENCH_JAVA_CLASSPATH" ch.konnexions.orabench.OraBench setup

EXITCODE=$?

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"

exit $EXITCODE
