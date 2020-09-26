#!/bin/bash

# ------------------------------------------------------------------------------
#
# run_gradle.bat: clean and assemble the Kotlin part of the project.
#
# ------------------------------------------------------------------------------

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - Gradle: clean and assemble the Kotlin part of the project."
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

(
    cd src_kotlin || exit
    
    if ! { gradle init; }; then
        exit 255
    fi

    if ! { gradle clean; }; then
        exit 255
    fi
    
    if ! { gradle jar; }; then
        exit 255
    fi
    
    mkdir -p ../priv/kotlin_jar
    cp -f build/libs/ora_bench.jar ../priv/libs/ora_bench_kotlin.jar
)

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"
