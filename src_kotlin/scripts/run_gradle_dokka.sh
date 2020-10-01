#!/bin/bash

# ------------------------------------------------------------------------------
#
# run_gradle_dokka.bat: create the Kotlin documentation.
#
# ------------------------------------------------------------------------------

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - Gradle: create the Kotlin documentation."
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

(
    cd src_kotlin || exit
    
    if ! { gradle dokkaHtml; }; then
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
