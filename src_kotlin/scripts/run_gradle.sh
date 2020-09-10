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
echo "MULTIPLE_RUN               : $ORA_BENCH_MULTIPLE_RUN"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

(
    cd src_kotlin || exit
    
    if ! { ./gradlew clean; }; then
        exit 255
    fi
    
    if ! { ./gradlew jar; }; then
        exit 255
    fi
    
    mkdir -p ../priv/kotlin_jar
    mv -fT build/libs/ora_bench.jar ../priv/libs/ora_bench_kotlin.jar

    if ! { ./gradlew dokkaHtml; }; then
        exit 255
    fi

    rm -rf ../priv/docs_kotlin
    mkdir ../priv/docs_kotlin
    cp -R build/dokka/* ../priv/docs_kotlin
)

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"
