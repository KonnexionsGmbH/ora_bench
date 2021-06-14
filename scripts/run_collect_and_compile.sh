#!/bin/bash

# ------------------------------------------------------------------------------
#
# collect_and_compile.sh: Collect libraries and compile.
#
# ------------------------------------------------------------------------------

set -e

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - collect libraries and compile."
echo "--------------------------------------------------------------------------------"
echo "BULKFILE_EXISTING                 : $BULKFILE_EXISTING"
echo "--------------------------------------------------------------------------------"
echo "RUN_CX_ORACLE_PYTHON              : $ORA_BENCH_RUN_CX_ORACLE_PYTHON"
echo "RUN_JDBC_KOTLIN                   : $ORA_BENCH_RUN_JDBC_KOTLIN"
echo "RUN_GODROR_GO                     : $ORA_BENCH_RUN_GODROR_GO"
echo "RUN_JDBC_JAVA                     : $ORA_BENCH_RUN_JDBC_JAVA"
echo "RUN_ODPI_C                        : $ORA_BENCH_RUN_ODPI_C"
echo "RUN_ORANIF_ELIXIR                 : $ORA_BENCH_RUN_ORANIF_ELIXIR"
echo "RUN_ORANIF_ERLANG                 : $ORA_BENCH_RUN_ORANIF_ERLANG"
echo "--------------------------------------------------------------------------------"
echo "GOROOT                            : $GOROOT"
echo "GRADLE_HOME                       : $GRADLE_HOME"
echo "LD_LIBRARY_PATH                   : $LD_LIBRARY_PATH"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

if [ "$BULKFILE_EXISTING" != "true" ]; then
    if ! { /bin/bash scripts/run_create_bulk_file.sh; }; then
        exit 255
    fi
fi

if [ "$ORA_BENCH_RUN_ODPI_C" == "true" ]; then
    echo "Setup C++ [gcc] - Start ===================================================="
    if ! java -jar priv/libs/ora_bench_java.jar setup_c; then
        exit 255
    fi

    if [ "$OSTYPE" = "msys" ]; then
        if ! nmake -f src_c/Makefile.win32 clean; then
            exit 255
        fi
        if ! nmake -f src_c/Makefile.win32; then
            exit 255
        fi
    else
        if ! make -f src_c/Makefile clean; then
            exit 255
        fi
        if ! make -f src_c/Makefile; then
            exit 255
        fi
    fi
    echo "Setup C++ [gcc] - End   ===================================================="
fi

if [ "$ORA_BENCH_RUN_GODROR_GO" == "true" ]; then
    echo "Setup Go - Start ==========================================================="
    if ! go get github.com/godror/godror; then
        exit 255
    fi
    echo "Setup Go - End   ==========================================================="
fi

if [ "$ORA_BENCH_RUN_JDBC_KOTLIN" == "true" ]; then
    echo "Setup Kotlin - Start ======================================================="
    if ! ./src_kotlin/scripts/run_gradle.sh; then
        exit 255
    fi
    echo "Setup Kotlin - End   ======================================================="
fi

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"
