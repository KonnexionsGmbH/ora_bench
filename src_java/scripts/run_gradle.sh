#!/bin/bash

# ------------------------------------------------------------------------------
#
# run_gradle.bat: clean and assemble the Java part of the project.
#
# ------------------------------------------------------------------------------

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - Gradle: clean and assemble the Java part of the project."
echo "--------------------------------------------------------------------------------"
echo "MULTIPLE_RUN               : $ORA_BENCH_MULTIPLE_RUN"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

EXITCODE="0"

(
    cd src_java || exit
    
    if ! { ./gradlew clean; }; then
        echo "ERRORLEVEL : $?"
        exit $?
    fi
    
    if ! { ./gradlew assemble; }; then
        echo "ERRORLEVEL : $?"
        exit $?
    fi
    
    cp build/libs/ora_bench.jar ../priv/java_jar
    
    if ! { ./gradlew javadoc; }; then
        echo "ERRORLEVEL : $?"
        exit $?
    fi
)

EXITCODE=$?

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"

exit $EXITCODE
