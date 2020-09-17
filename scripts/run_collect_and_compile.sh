#!/bin/bash

# ------------------------------------------------------------------------------
#
# collect_and_compile.sh: Collect libraries and compile.
#
# ------------------------------------------------------------------------------

set -e

if [ -z "$GOPATH" ]; then
    GOPATH=$(pwd)/src_go/go
fi

if [ -z "$RUN_GLOBAL_JAMDB" ]; then
    export RUN_GLOBAL_JAMDB=true
fi
if [ -z "$RUN_GLOBAL_NON_JAMDB" ]; then
    export RUN_GLOBAL_NON_JAMDB=true
fi

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - collect libraries and compile."
echo "--------------------------------------------------------------------------------"
echo "BULKFILE_EXISTING                 : $BULKFILE_EXISTING"
echo "--------------------------------------------------------------------------------"
echo "RUN_GLOBAL_JAMDB                  : $RUN_GLOBAL_JAMDB"
echo "RUN_GLOBAL_NON_JAMDB              : $RUN_GLOBAL_NON_JAMDB"
echo "--------------------------------------------------------------------------------"
echo "RUN_CX_ORACLE_PYTHON              : $ORA_BENCH_RUN_CX_ORACLE_PYTHON"
echo "RUN_JDBC_KOTLIN                   : $ORA_BENCH_RUN_JDBC_KOTLIN"
echo "RUN_GODROR_GO                     : $ORA_BENCH_RUN_GODROR_GO"
echo "RUN_JAMDB_ORACLE_ERLANG           : $ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG"
echo "RUN_JDBC_JAVA                     : $ORA_BENCH_RUN_JDBC_JAVA"
echo "RUN_ODPI_C                        : $ORA_BENCH_RUN_ODPI_C"
echo "RUN_ORANIF_ELIXIR                 : $ORA_BENCH_RUN_ORANIF_ELIXIR"
echo "RUN_ORANIF_ERLANG                 : $ORA_BENCH_RUN_ORANIF_ERLANG"
echo "--------------------------------------------------------------------------------"
echo "GOPATH                            : $GOPATH"
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

if [ "$RUN_GLOBAL_NON_JAMDB" = "true" ]; then
    if [ "$ORA_BENCH_RUN_ODPI_C" == "true" ]; then
        echo "Setup C - Start ============================================================" 
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
        echo "Setup C - End   ============================================================" 
    fi
    
    if [ "$ORA_BENCH_RUN_ORANIF_ELIXIR" == "true" ]; then
        echo "Setup Elixir - Start =======================================================" 
        if ! java -jar priv/libs/ora_bench_java.jar setup_elixir; then
            exit 255
        fi

        (
            cd src_elixir || exit 255

            if [ -f "mix.lock" ]; then
                rm -f mix.lock
            fi         
            if [ -f "deps" ]; then
                rm -rf deps
            fi         

            if ! mix local.hex --force; then
                exit 255
            fi
            
            if ! mix deps.clean --all; then
               exit 255
            fi
            
            if ! mix deps.get; then
                exit 255
            fi
            
            if ! mix deps.compile; then
                exit 255
            fi
        )
        echo "Setup Elixir - End   =======================================================" 
    fi
fi    
    
if [ "$ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG" == "true" ] || [ "$ORA_BENCH_RUN_ORANIF_ERLANG" == "true" ]; then
    echo "Setup Erlang - Start ======================================================="
    if ! java -jar priv/libs/ora_bench_java.jar setup_erlang; then
        exit 255
    fi
    
    (
        cd src_erlang || exit 255

        if [ -d "_build" ]; then
            rm -rf _build
        fi         

        if ! rebar3 escriptize; then
            exit 255
        fi
    )
    echo "Setup Erlang - End   =======================================================" 
fi

if [ "$RUN_GLOBAL_NON_JAMDB" = "true" ]; then
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

    if [ "$ORA_BENCH_RUN_CX_ORACLE_PYTHON" == "true" ]; then
        echo "Setup Python - Start =======================================================" 
        if ! java -jar priv/libs/ora_bench_java.jar setup_python; then
            exit 255
        fi
        echo "Setup Python - End   =======================================================" 
    fi    
fi    

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"
