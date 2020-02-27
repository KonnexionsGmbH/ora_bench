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
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

EXITCODE="0"

{ ./gradlew clean; }
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi

cd src_java

{ ./gradlew assemble; }
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi

cp build/libs/ora_bench.jar ../priv/java_jar

{ ./gradlew javadoc; }
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi

cd ..

EXITCODE=$?

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"

exit $EXITCODE
