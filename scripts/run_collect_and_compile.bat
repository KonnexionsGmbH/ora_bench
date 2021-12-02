@echo off

rem --------------------------------------------------------------------------------
rem
rem collect_and_compile.bat: Collect libraries and compile. 
rem
rem --------------------------------------------------------------------------------

setlocal EnableDelayedExpansion

if ["%ORA_BENCH_BENCHMARK_VCVARSALL%"] EQU [""] (
    set "ORA_BENCH_BENCHMARK_VCVARSALL=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat"
)

echo ===============================================================================
echo Start %0
echo -------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - collect libraries and compile.
echo -------------------------------------------------------------------------------
echo BENCHMARK_VCVARSALL               : %ORA_BENCH_BENCHMARK_VCVARSALL%
echo BULKFILE_EXISTING                 : %ORA_BENCH_BULKFILE_EXISTING%
echo -------------------------------------------------------------------------------
echo RUN_CX_ORACLE_PYTHON              : %ORA_BENCH_RUN_CX_ORACLE_PYTHON%
echo RUN_GODROR_GO                     : %ORA_BENCH_RUN_GODROR_GO%
echo RUN_JDBC_JAVA                     : %ORA_BENCH_RUN_JDBC_JAVA%
echo RUN_JDBC_JULIA                    : %ORA_BENCH_RUN_JDBC_JULIA%
echo RUN_JDBC_KOTLIN                   : %ORA_BENCH_RUN_JDBC_KOTLIN%
echo RUN_NIMODPI_NIM                   : %ORA_BENCH_RUN_NIMODPI_NIM%
echo RUN_ODPI_C                        : %ORA_BENCH_RUN_ODPI_C%
echo RUN_ORACLE_JULIA                  : %ORA_BENCH_RUN_ORACLE_JULIA%
echo RUN_ORACLE_RUST                   : %ORA_BENCH_RUN_ORACLE_RUST%
echo RUN_ORANIF_ELIXIR                 : %ORA_BENCH_RUN_ORANIF_ELIXIR%
echo RUN_ORANIF_ERLANG                 : %ORA_BENCH_RUN_ORANIF_ERLANG%
echo -------------------------------------------------------------------------------
echo GOROOT                            : %GOROOT%
echo GRADLE_HOME                       : %GRADLE_HOME%
echo LD_LIBRARY_PATH                   : %LD_LIBRARY_PATH%
echo -------------------------------------------------------------------------------
echo:| TIME
echo ===============================================================================

echo --------------------------------------------------------------------------------
echo Set environment variables for C / C++ compilation.
echo --------------------------------------------------------------------------------
if exist "%ORA_BENCH_BENCHMARK_VCVARSALL%" (
    call "%ORA_BENCH_BENCHMARK_VCVARSALL%" x64
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'vcvarsall.bat' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )
)

if NOT ["%ORA_BENCH_BULKFILE_EXISTING%"] == ["true"] (
    call scripts\run_create_bulk_file.bat
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call scripts\run_create_bulk_file.bat' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )
)

if ["%ORA_BENCH_RUN_ODPI_C%"] == ["true"] (
    echo Setup C++ [gcc] - Start ========================================================
    nmake -f lang\c\Makefile.win32 clean
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'nmake -f lang\c\Makefile.win32 clean' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    nmake -f lang\c\Makefile.win32
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'nmake -f lang\c\Makefile.win32' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    java -jar priv/libs/ora_bench_java.jar setup_c
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'java -jar priv/libs/ora_bench_java.jar setup_c' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    echo Setup C++ [gcc] - End   ========================================================
)

if ["%ORA_BENCH_RUN_ORANIF_ELIXIR%"] == ["true"] (
    echo Setup Elixir - Start ===========================================================
    cd lang\elixir

    if EXIST deps\    rd /Q/S deps 
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'rd /Q/S deps' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    if EXIST mix.lock del /s mix.lock 
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'del /s mix.lock' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    call mix local.hex --force
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call mix local.hex --force' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    call mix local.rebar --force
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call mix local.rebar --force' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    call mix deps.clean --all
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call mix deps.clean --all' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    call mix deps.get
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call mix deps.get' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    call mix deps.compile
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call mix deps.compile' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    cd ..\..

    java -jar priv/libs/ora_bench_java.jar setup_elixir
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'java -jar priv/libs/ora_bench_java.jar setup_elixir' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    echo Setup Elixir - End   ===========================================================
)

if ["%ORA_BENCH_RUN_ORANIF_ERLANG%"] == ["true"] (
    echo Setup Erlang - Start ===========================================================
    cd lang\erlang

    if EXIST _build\ rd /Q/S _build

    call rebar3 steamroll
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call rebar3 steamroll' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    call rebar3 escriptize
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call rebar3 escriptize' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    cd ..\..

    java -jar priv/libs/ora_bench_java.jar setup_erlang
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'java -jar priv/libs/ora_bench_java.jar setup_erlang' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    echo Setup Erlang - End   ===========================================================
)

if ["%ORA_BENCH_RUN_GODROR_GO%"] == ["true"] (
    echo Setup Go - Start ===============================================================
    make -C lang\go
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'make' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    java -jar priv/libs/ora_bench_java.jar setup_default
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'java -jar priv/libs/ora_bench_java.jar setup_default' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    echo Setup Go - End   ===============================================================
)
set ORA_BENCH_RUN_JULIA=false

if ["%ORA_BENCH_RUN_JDBC_JULIA%"] == ["true"] (
    set ORA_BENCH_RUN_JULIA=true
)

if ["%ORA_BENCH_RUN_ORACLE_JULIA%"] == ["true"] (
    set ORA_BENCH_RUN_JULIA=true
)

if ["%ORA_BENCH_RUN_JULIA%"] == ["true"] (
    echo Setup Julia - Start =============================================================
    java -jar priv/libs/ora_bench_java.jar setup_toml
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'java -jar priv/libs/ora_bench_java.jar setup_toml' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    echo Setup Julia - End   =============================================================
)

if ["%ORA_BENCH_RUN_JDBC_KOTLIN%"] == ["true"] (
    echo Setup Kotlin - Start ===========================================================
    call lang\kotlin\scripts\run_gradle.bat
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call lang\kotlin\scripts\run_gradle.bat' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    java -jar priv/libs/ora_bench_java.jar setup_default
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'java -jar priv/libs/ora_bench_java.jar setup_default' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    echo Setup Kotlin - End   ===========================================================
)

if ["%ORA_BENCH_RUN_NIMODPI_NIM%"] == ["true"] (
    echo Setup Nim - Start ==============================================================
    make -C lang\nim
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'make' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    java -jar priv/libs/ora_bench_java.jar setup_yaml
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'java -jar priv/libs/ora_bench_java.jar setup_yaml' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    echo Setup Nim - End   ==============================================================
)

if ["%ORA_BENCH_RUN_CX_ORACLE_PYTHON%"] == ["true"] (
    echo Setup Python 3 - Start =========================================================
    python -m pip install --upgrade pip
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'python -m pip install -r lang/python/requirements.txt' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )
    
    python -m pip install -r lang/python/requirements.txt
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'python -m pip install -r lang/python/requirements.txt' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )
    
    echo ============================================================================== Version Python:
    echo.
    python --version
    echo.
    python -m pip --version
    python -m pip freeze | findstr /i "cx-oracle pyyaml"
    echo.
    echo ==============================================================================
    
    python -m compileall lang/python/OraBench.py
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'python -m compileall lang/python/OraBench.py' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    java -jar priv/libs/ora_bench_java.jar setup_python
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'java -jar priv/libs/ora_bench_java.jar setup_python' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    echo Setup Python 3 - End   =========================================================
)

if ["%ORA_BENCH_RUN_ORACLE_RUST%"] == ["true"] (
    echo Setup Rust - Start =============================================================
    make -C lang\rust
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'make' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    java -jar priv/libs/ora_bench_java.jar setup_default
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'java -jar priv/libs/ora_bench_java.jar setup_default' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    echo Setup Rust - End   =============================================================
)

echo -------------------------------------------------------------------------------
echo:| TIME
echo -------------------------------------------------------------------------------
echo End   %0
echo ===============================================================================
