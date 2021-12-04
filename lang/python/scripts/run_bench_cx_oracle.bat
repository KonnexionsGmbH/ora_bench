@echo off

rem --------------------------------------------------------------------------------
rem
rem run_bench_cx_oracle.bat: Oracle Benchmark based on Python 3.
rem
rem --------------------------------------------------------------------------------

set ORA_BENCH_BENCHMARK_DATABASE_DEFAULT=db_21_3
set ORA_BENCH_CONNECTION_HOST_DEFAULT=localhost
set ORA_BENCH_CONNECTION_PORT_DEFAULT=1521
set ORA_BENCH_CONNECTION_SERVICE_DEFAULT=orclpdb1
set ORA_BENCH_PASSWORD_SYS_DEFAULT=oracle
set ORA_BENCH_FILE_CONFIGURATION_NAME_DEFAULT=priv/properties/ora_bench.properties

if ["%ORA_BENCH_BENCHMARK_DATABASE%"] EQU [""] (
    set ORA_BENCH_BENCHMARK_DATABASE=%ORA_BENCH_BENCHMARK_DATABASE_DEFAULT%
)
if ["%ORA_BENCH_CONNECTION_HOST%"] EQU [""] (
    set ORA_BENCH_CONNECTION_HOST=%ORA_BENCH_CONNECTION_HOST_DEFAULT%
)
if ["%ORA_BENCH_CONNECTION_PORT%"] EQU [""] (
    set ORA_BENCH_CONNECTION_PORT=%ORA_BENCH_CONNECTION_PORT_DEFAULT%
)
if ["%ORA_BENCH_CONNECTION_SERVICE%"] EQU [""] (
    set ORA_BENCH_CONNECTION_SERVICE=%ORA_BENCH_CONNECTION_SERVICE_DEFAULT%
)
if ["%ORA_BENCH_PASSWORD_SYS%"] EQU [""] (
    set ORA_BENCH_PASSWORD_SYS=%ORA_BENCH_PASSWORD_SYS_DEFAULT%
)

set ORA_BENCH_FILE_CONFIGURATION_NAME=priv\properties\ora_bench.properties
set ORA_BENCH_FILE_CONFIGURATION_NAME_PYTHON=priv\properties\ora_bench_python.properties

echo ===============================================================================
echo Start %0
echo -------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - cx_Oracle and Python 3.
echo -------------------------------------------------------------------------------
echo MULTIPLE_RUN                   : %ORA_BENCH_MULTIPLE_RUN%
echo -------------------------------------------------------------------------------
echo BENCHMARK_DATABASE             : %ORA_BENCH_BENCHMARK_DATABASE%
echo CONNECTION_HOST                : %ORA_BENCH_CONNECTION_HOST%
echo CONNECTION_PORT                : %ORA_BENCH_CONNECTION_PORT%
echo CONNECTION_SERVICE             : %ORA_BENCH_CONNECTION_SERVICE%
echo -------------------------------------------------------------------------------
echo BENCHMARK_BATCH_SIZE           : %ORA_BENCH_BENCHMARK_BATCH_SIZE%
echo BENCHMARK_CORE_MULTIPLIER      : %ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%
echo BENCHMARK_TRANSACTION_SIZE     : %ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%
echo -------------------------------------------------------------------------------
echo FILE_CONFIGURATION_NAME        : %ORA_BENCH_FILE_CONFIGURATION_NAME%
echo -------------------------------------------------------------------------------
echo:| TIME
echo ===============================================================================

if NOT ["%ORA_BENCH_MULTIPLE_RUN%"] == ["true"] (
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
    
    call lang\java\scripts\run_gradle
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call lang\java\scripts\run_gradle' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    java -jar priv/libs/ora_bench_java.jar setup_python
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'java -jar priv/libs/ora_bench_java.jar setup_python' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )
)

python lang/python/__pycache__/OraBench.cpython-310.pyc
if %ERRORLEVEL% neq 0 (
    echo Processing of the script: %0 - step: 'python lang/python/__pycache__/OraBench.cpython-310.pyc' was aborted, error code=%ERRORLEVEL%
    exit -1073741510
)

echo -------------------------------------------------------------------------------
echo:| TIME
echo -------------------------------------------------------------------------------
echo End   %0
echo ===============================================================================
