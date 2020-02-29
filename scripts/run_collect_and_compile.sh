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
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

EXITCODE="0"

if [ "$$BULKFILE_EXISTING" != "true" ]; then
    { /bin/bash scripts/run_create_bulk_file.sh; }
    if [ $? -ne 0 ]; then
        echo "ERRORLEVEL : $?"
        exit $?
    fi
fi

if [ "$RUN_GLOBAL_NON_JAMDB" = "true" ]; then
    if [ "$ORA_BENCH_RUN_ODPI_C" == "true" ]; then
        echo "Setup C - Start ============================================================" 
        if [ "$OSTYPE" = "msys" ]; then
            nmake -f src_c/Makefile.win32 clean
            if [ $? -ne 0 ]; then
                echo "ERRORLEVEL : $?"
                exit $?
            fi
            nmake -f src_c/Makefile.win32
        else
            make -f src_c/Makefile clean
            if [ $? -ne 0 ]; then
                echo "ERRORLEVEL : $?"
                exit $?
            fi
            make -f src_c/Makefile
        fi
        if [ $? -ne 0 ]; then
            echo "ERRORLEVEL : $?"
            exit $?
        fi

        java -cp "priv/java_jar/*" ch.konnexions.orabench.OraBench setup_c
        if [ $? -ne 0 ]; then
            echo "ERRORLEVEL : $?"
            exit $?
        fi
        echo "Setup C - End   ============================================================" 
    fi
    
    if [ "$ORA_BENCH_RUN_ORANIF_ELIXIR" == "true" ]; then
        echo "Setup Elixir - Start =======================================================" 
        java -cp "priv/java_jar/*" ch.konnexions.orabench.OraBench setup_elixir
        if [ $? -ne 0 ]; then
            echo "ERRORLEVEL : $?"
            exit $?
        fi

        cd src_elixir
        mix local.hex --force
        if [ $? -ne 0 ]; then
            echo "ERRORLEVEL : $?"
            exit $?
        fi
        
        mix deps.clean --all
        if [ $? -ne 0 ]; then
            echo "ERRORLEVEL : $?"
            exit $?
        fi
        
        mix deps.get
        if [ $? -ne 0 ]; then
            echo "ERRORLEVEL : $?"
            exit $?
        fi
        
        mix deps.compile
        if [ $? -ne 0 ]; then
            echo "ERRORLEVEL : $?"
            exit $?
        fi
        cd ..
        echo "Setup Elixir - End   =======================================================" 
    fi
fi    
    
if [ "$ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG" == "true" ] || [ "$ORA_BENCH_RUN_ORANIF_ERLANG" == "true" ]; then
    echo "Setup Erlang - Start ======================================================="
    java -cp "priv/java_jar/*" ch.konnexions.orabench.OraBench setup_erlang
    if [ $? -ne 0 ]; then
        echo "ERRORLEVEL : $?"
        exit $?
    fi
    
    cd src_erlang
    rebar3 escriptize
    if [ $? -ne 0 ]; then
        echo "ERRORLEVEL : $?"
        exit $?
    fi
    echo "Setup Erlang - End   =======================================================" 
    cd ..
fi

if [ "$RUN_GLOBAL_NON_JAMDB" = "true" ]; then
    if [ "$ORA_BENCH_RUN_GODROR_GO" == "true" ]; then
        echo "Setup Go - Start ===========================================================" 
        echo go get github.com/godror/godror
        go get github.com/godror/godror
        if [ $? -ne 0 ]; then
            echo "ERRORLEVEL : $?"
            exit $?
        fi
        echo "Setup Go - End   ===========================================================" 
    fi    

    if [ "$ORA_BENCH_RUN_CX_ORACLE_PYTHON" == "true" ]; then
        echo "Setup Python - Start =======================================================" 
        java -cp "priv/java_jar/*" ch.konnexions.orabench.OraBench setup_python
        if [ $? -ne 0 ]; then
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
