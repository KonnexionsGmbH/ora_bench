#!/bin/bash

# ------------------------------------------------------------------------------
#
# collect_and_compile.sh: Collect libraries and compile.
#
# ------------------------------------------------------------------------------

export ORA_BENCH_MULTIPLE_RUN=true

if [ -z "$ORA_BENCH_RUN_CX_ORACLE_PYTHON" ]; then
    export ORA_BENCH_RUN_CX_ORACLE_PYTHON=true
fi
if [ -z "$ORA_BENCH_RUN_GODROR_GO" ]; then
    export ORA_BENCH_RUN_GODROR_GO=true
fi
if [ -z "$ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG" ]; then
    export ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG=true
fi
if [ -z "$ORA_BENCH_RUN_JDBC_JAVA" ]; then
    export ORA_BENCH_RUN_JDBC_JAVA=true
fi
if [ -z "$ORA_BENCH_RUN_ODPI_C" ]; then
    export ORA_BENCH_RUN_ODPI_C=true
fi
if [ -z "$ORA_BENCH_RUN_ORANIF_ELIXIR" ]; then
    export ORA_BENCH_RUN_ORANIF_ELIXIR=true
fi
if [ -z "$ORA_BENCH_RUN_ORANIF_ERLANG" ]; then
    export ORA_BENCH_RUN_ORANIF_ERLANG=true
fi

if [ -z "$ORA_BENCH_FILE_CONFIGURATION_NAME" ]; then
    export ORA_BENCH_FILE_CONFIGURATION_NAME=priv/properties/ora_bench.properties
fi

if [ -z "$ORA_BENCH_JAVA_CLASSPATH" ]; then
    if [ "$OSTYPE" = "msys" ]; then
        export ORA_BENCH_JAVA_CLASSPATH=".;priv/java_jar/*"
    else
        export ORA_BENCH_JAVA_CLASSPATH=".:priv/java_jar/*"
    fi
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
echo "BULKFILE_EXISTING          : $BULKFILE_EXISTING"
echo "--------------------------------------------------------------------------------"
echo "RUN_GLOBAL_JAMDB           : $RUN_GLOBAL_JAMDB"
echo "RUN_GLOBAL_NON_JAMDB       : $RUN_GLOBAL_NON_JAMDB"
echo "--------------------------------------------------------------------------------"
echo "RUN_CX_ORACLE_PYTHON       : $ORA_BENCH_RUN_CX_ORACLE_PYTHON"
echo "RUN_GODROR_GO              : $ORA_BENCH_RUN_GODROR_GO"
echo "RUN_JAMDB_ORACLE_ERLANG    : $ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG"
echo "RUN_JDBC_JAVA              : $ORA_BENCH_RUN_JDBC_JAVA"
echo "RUN_ODPI_C                 : $ORA_BENCH_RUN_ODPI_C"
echo "RUN_ORANIF_ELIXIR          : $ORA_BENCH_RUN_ORANIF_ELIXIR"
echo "RUN_ORANIF_ERLANG          : $ORA_BENCH_RUN_ORANIF_ERLANG"
echo "--------------------------------------------------------------------------------"
echo "FILE_CONFIGURATION_NAME    : $ORA_BENCH_FILE_CONFIGURATION_NAME"
echo "--------------------------------------------------------------------------------"
echo "GOPATH                     : $GOPATH"
echo "GOROOT                     : $GOROOT"
echo "GRADLE_HOME                : $GRADLE_HOME"
echo "JAVA_CLASSPATH             : $ORA_BENCH_JAVA_CLASSPATH"
echo "LD_LIBRARY_PATH            : $LD_LIBRARY_PATH"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

EXITCODE="0"

if [ "$BULKFILE_EXISTING" != "true" ]; then
    if ! { /bin/bash scripts/run_create_bulk_file.sh; }; then
        echo "ERRORLEVEL : $?"
        exit $?
    fi
fi

if [ "$RUN_GLOBAL_NON_JAMDB" = "true" ]; then
    if [ "$ORA_BENCH_RUN_ODPI_C" == "true" ]; then
        echo "Setup C - Start ============================================================" 
        if ! java -cp priv/java_jar/* ch.konnexions.orabench.OraBench setup_c; then
            echo "ERRORLEVEL : $?"
            exit $?
        fi

        if [ "$OSTYPE" = "msys" ]; then
            if ! nmake -f src_c/Makefile.win32 clean; then
                echo "ERRORLEVEL : $?"
                exit $?
            fi
            if ! nmake -f src_c/Makefile.win32; then
                echo "ERRORLEVEL : $?"
                exit $?
            fi
        else
            if ! make -f src_c/Makefile clean; then
                echo "ERRORLEVEL : $?"
                exit $?
            fi
            if ! make -f src_c/Makefile; then
                echo "ERRORLEVEL : $?"
                exit $?
            fi
        fi
        echo "Setup C - End   ============================================================" 
    fi
    
    if [ "$ORA_BENCH_RUN_ORANIF_ELIXIR" == "true" ]; then
        echo "Setup Elixir - Start =======================================================" 
        if ! java -cp priv/java_jar/* ch.konnexions.orabench.OraBench setup_elixir; then
            echo "ERRORLEVEL : $?"
            exit $?
        fi

        (
            cd src_elixir || exit $?
            if ! mix local.hex --force; then
                echo "ERRORLEVEL : $?"
                exit $?
            fi
            
            if ! mix deps.clean --all; then
                echo "ERRORLEVEL : $?"
                exit $?
            fi
            
            if ! mix deps.get; then
                echo "ERRORLEVEL : $?"
                exit $?
            fi
            
            if ! mix deps.compile; then
                echo "ERRORLEVEL : $?"
                exit $?
            fi
        )
        echo "Setup Elixir - End   =======================================================" 
    fi
fi    
    
if [ "$ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG" == "true" ] || [ "$ORA_BENCH_RUN_ORANIF_ERLANG" == "true" ]; then
    echo "Setup Erlang - Start ======================================================="
    if ! java -cp priv/java_jar/* ch.konnexions.orabench.OraBench setup_erlang; then
        echo "ERRORLEVEL : $?"
        exit $?
    fi
    
    (
        cd src_erlang || exit $?
        if ! rebar3 escriptize; then
            echo "ERRORLEVEL : $?"
            exit $?
        fi
    )
    echo "Setup Erlang - End   =======================================================" 
fi

if [ "$RUN_GLOBAL_NON_JAMDB" = "true" ]; then
    if [ "$ORA_BENCH_RUN_GODROR_GO" == "true" ]; then
        echo "Setup Go - Start ===========================================================" 
        if ! go get github.com/godror/godror; then
            echo "ERRORLEVEL : $?"
            exit $?
        fi
        echo "Setup Go - End   ===========================================================" 
    fi    

    if [ "$ORA_BENCH_RUN_CX_ORACLE_PYTHON" == "true" ]; then
        echo "Setup Python - Start =======================================================" 
        if ! java -cp "priv/java_jar/*" ch.konnexions.orabench.OraBench setup_python; then
            echo "ERRORLEVEL : $?"
            exit $?
        fi
        echo "Setup Python - End   =======================================================" 
    fi    
fi    

EXITCODE=$?

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"

exit $EXITCODE
