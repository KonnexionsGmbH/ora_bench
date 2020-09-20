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

(
    cd src_java || exit
    
    if ! { ./gradle init; }; then
        exit 255
    fi

    if ! { ./gradle clean; }; then
        exit 255
    fi
    
    if ! { ./gradle copyJarToLib; }; then
        exit 255
    fi
    
    if ! { ./gradle javadoc; }; then
        exit 255
    fi

    rm -rf ../priv/docs_java
    mkdir ../priv/docs_java
    cp -R build/docs/* ../priv/docs_java
)

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"
