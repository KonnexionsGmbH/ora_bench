#!/bin/bash

# ----------------------------------------------------------------------------------
#
# collect_and_compile.sh: Collect libraries and compile.
#
# ----------------------------------------------------------------------------------

set -e

echo "================================================================================="
echo "Start $0"
echo "---------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - collect libraries and compile."
echo "---------------------------------------------------------------------------------"
echo "BULKFILE_EXISTING                 : $BULKFILE_EXISTING"
echo "---------------------------------------------------------------------------------"
echo "RUN_CX_ORACLE_PYTHON              : ${ORA_BENCH_RUN_CX_ORACLE_PYTHON}"
echo "RUN_GODROR_GO                     : ${ORA_BENCH_RUN_GODROR_GO}"
echo "RUN_JDBC_JAVA                     : ${ORA_BENCH_RUN_JDBC_JAVA}"
echo "RUN_JDBC_JULIA                    : ${ORA_BENCH_RUN_JDBC_JULIA}"
echo "RUN_JDBC_KOTLIN                   : ${ORA_BENCH_RUN_JDBC_KOTLIN}"
echo "RUN_NIMODPI_NIM                   : ${ORA_BENCH_RUN_NIMODPI_NIM}"
echo "RUN_ODPI_C                        : ${ORA_BENCH_RUN_ODPI_C}"
echo "RUN_ORACLE_JULIA                  : ${ORA_BENCH_RUN_ORACLE_JULIA}"
echo "RUN_ORACLE_RUST                   : ${ORA_BENCH_RUN_ORACLE_RUST}"
echo "RUN_ORANIF_ELIXIR                 : ${ORA_BENCH_RUN_ORANIF_ELIXIR}"
echo "RUN_ORANIF_ERLANG                 : ${ORA_BENCH_RUN_ORANIF_ERLANG}"
echo "---------------------------------------------------------------------------------"
echo "GOROOT                            : $GOROOT"
echo "GRADLE_HOME                       : $GRADLE_HOME"
echo "LD_LIBRARY_PATH                   : $LD_LIBRARY_PATH"
echo "---------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================="

if [ "$BULKFILE_EXISTING" != "true" ]; then
    if ! { /bin/bash scripts/run_create_bulk_file.sh; }; then
        exit 255
    fi
fi

if [ "${ORA_BENCH_RUN_ODPI_C}" == "true" ]; then
    echo "Setup C++ [gcc] - Start ========================================================="
    if [ "$OSTYPE" = "msys" ]; then
        if ! nmake -f lang/c/Makefile.win32 clean; then
            exit 255
        fi
        if ! nmake -f lang/c/Makefile.win32; then
            exit 255
        fi
    else
        if ! make -f lang/c/Makefile clean; then
            exit 255
        fi
        if ! make -f lang/c/Makefile; then
            exit 255
        fi
    fi

    if ! java -jar priv/libs/ora_bench_java.jar setup_c; then
        exit 255
    fi
    echo "Setup C++ [gcc] - End   ========================================================="
fi

if [ "${ORA_BENCH_RUN_ORANIF_ELIXIR}" == "true" ]; then
    echo "Setup Elixir - Start ============================================================"
    cd lang/elixir || exit 255

    if [ -f "mix.lock" ]; then
        if ! rm -f mix.lock; then
            exit 255
        fi
    fi

    if [ -f "deps" ]; then
        if ! rm -rf deps; then
            exit 255
        fi
    fi
    
    if ! mix local.hex --force; then
        exit 255
    fi
    
    if ! mix local.rebar --force; then
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

    cd ../..

    if ! java -jar priv/libs/ora_bench_java.jar setup_elixir; then
        exit 255
    fi
    echo "Setup Elixir - End   ============================================================"
fi

if [ "${ORA_BENCH_RUN_ORANIF_ERLANG}" == "true" ]; then
    echo "Setup Erlang - Start ============================================================"
    cd lang/erlang || exit 255

    if [ -d "_build" ]; then
        rm -rf _build
    fi

    if ! rebar3 steamroll; then
        exit 255
    fi

    if ! rebar3 escriptize; then
        exit 255
    fi

    cd ../..
  
    if ! java -jar priv/libs/ora_bench_java.jar setup_erlang; then
        exit 255
    fi
    echo "Setup Erlang - End   ============================================================"
fi

if [ "${ORA_BENCH_RUN_GODROR_GO}" == "true" ]; then
    echo "Setup Go - Start ================================================================"
    if ! make -C lang/go; then
        exit 255
    fi
    
    if ! java -jar priv/libs/ora_bench_java.jar setup_default; then
        exit 255
    fi
    echo "Setup Go - End   ================================================================"
fi

if [ "${ORA_BENCH_RUN_JDBC_JULIA}" == "true" ] ||
   [ "${ORA_BENCH_RUN_ORACLE_JULIA}" == "true" ]; then
    echo "Setup Julia - Start ============================================================="
    if ! java -jar priv/libs/ora_bench_java.jar setup_toml; then
        exit 255
    fi
    echo "Setup Julia - End   ============================================================="
fi

if [ "${ORA_BENCH_RUN_JDBC_KOTLIN}" == "true" ]; then
    echo "Setup Kotlin - Start ============================================================"
    if ! { ./lang/kotlin/scripts/run_gradle.sh; }; then
        exit 255
    fi

    if ! java -jar priv/libs/ora_bench_java.jar setup_default; then
        exit 255
    fi
    echo "Setup Kotlin - End   ============================================================"
fi

if [ "${ORA_BENCH_RUN_NIMODPI_NIM}" == "true" ]; then
    echo "Setup Nim - Start ==============================================================="
    if ! make -C lang/nim; then
        exit 255
    fi
    
    if ! java -jar priv/libs/ora_bench_java.jar setup_yaml; then
        exit 255
    fi
    echo "Setup Nim - End   ==============================================================="
fi

if [ "${ORA_BENCH_RUN_CX_ORACLE_PYTHON}" == "true" ]; then
    echo "Setup Python 3 - Start =========================================================="
    if ! python3 -m pip install --upgrade pip; then
        exit 255
    fi
    
    if ! python3 -m pip install -r lang/python/requirements.txt; then
        exit 255
    fi
    
    echo "=============================================================================> Version Python: "
    echo " "
    echo "Current version of Python: $(python3 --version)"
    echo " "
    echo "Current version of pip: $(python3 -m pip --version)"
    echo " "
    python3 -m pip freeze | grep -E -i 'cx_oracle|PyYAML'
    echo " "
    echo "=============================================================================>"
    
    if ! python3 -m compileall lang/python/OraBench.py; then
        exit 255
    fi

    if ! java -jar priv/libs/ora_bench_java.jar setup_python; then
        exit 255
    fi
    echo "Setup Python 3 - End   =========================================================="
fi

if [ "${ORA_BENCH_RUN_ORACLE_RUST}" == "true" ]; then
    echo "Setup Rust - Start =============================================================="
    if ! make -C lang/rust; then
        exit 255
    fi
    
    if ! java -jar priv/libs/ora_bench_java.jar setup_default; then
      exit 255
    fi
    echo "Setup Rust - End   =============================================================="
fi

echo ""
echo "---------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "---------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================="
