#!/bin/bash

# ----------------------------------------------------------------------------------
#
# run_gradle.bat: clean and assemble the Java part of the project.
#
# ----------------------------------------------------------------------------------

echo "=============================================================================="
echo "Start $0"
echo "------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - Gradle: clean and assemble the Java part of the project."
echo "------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "=============================================================================="

(
    cd lang/java || exit
    
    if ! { gradle init --warning-mode all; }; then
        exit 255
    fi

    if ! { gradle clean --warning-mode all; }; then
        exit 255
    fi
    
    if ! { gradle copyJarToLib --warning-mode all; }; then
        exit 255
    fi
)

echo ""
echo "------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "------------------------------------------------------------------------------"
echo "End   $0"
echo "=============================================================================="
