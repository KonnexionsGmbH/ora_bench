@echo off

rem --------------------------------------------------------------------------------
rem
rem run_bench_odpi.sh: Oracle Benchmark based on ODPI-C.
rem
rem --------------------------------------------------------------------------------

set ORA_BENCH_BENCHMARK_DATABASE_DEFAULT=db_21_3
set ORA_BENCH_CONNECTION_HOST_DEFAULT=localhost
set ORA_BENCH_CONNECTION_PORT_DEFAULT=1521
set ORA_BENCH_CONNECTION_SERVICE_DEFAULT=orclpdb1
set ORA_BENCH_PASSWORD_SYS_DEFAULT=oracle

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

if ["%ORA_BENCH_BENCHMARK_VCVARSALL%"] EQU [""] (
    set "ORA_BENCH_BENCHMARK_VCVARSALL=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat"
)

set ORA_BENCH_FILE_CONFIGURATION_NAME=priv\properties\ora_bench.properties
set ORA_BENCH_FILE_CONFIGURATION_NAME_C=priv\properties\ora_bench_c.properties

echo ===============================================================================
echo Start %0
echo -------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - ODPI-C and C.
echo -------------------------------------------------------------------------------
echo MULTIPLE_RUN               : %ORA_BENCH_MULTIPLE_RUN%
echo -------------------------------------------------------------------------------
echo BENCHMARK_DATABASE         : %ORA_BENCH_BENCHMARK_DATABASE%
echo CONNECTION_HOST            : %ORA_BENCH_CONNECTION_HOST%
echo CONNECTION_PORT            : %ORA_BENCH_CONNECTION_PORT%
echo CONNECTION_SERVICE         : %ORA_BENCH_CONNECTION_SERVICE%
echo -------------------------------------------------------------------------------
echo BENCHMARK_BATCH_SIZE       : %ORA_BENCH_BENCHMARK_BATCH_SIZE%
echo BENCHMARK_CORE_MULTIPLIER  : %ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%
echo BENCHMARK_TRANSACTION_SIZE : %ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%
echo BENCHMARK_VCVARSALL        : %ORA_BENCH_BENCHMARK_VCVARSALL%
echo -------------------------------------------------------------------------------
echo FILE_CONFIGURATION_NAME    : %ORA_BENCH_FILE_CONFIGURATION_NAME%
echo FILE_CONFIGURATION_NAME_C  : %ORA_BENCH_FILE_CONFIGURATION_NAME_C%
echo -------------------------------------------------------------------------------
echo:| TIME
echo ===============================================================================

if NOT ["%ORA_BENCH_MULTIPLE_RUN%"] == ["true"] (
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

    call lang\java\scripts\run_gradle
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call lang\java\scripts\run_gradle' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )
    
    call lang\java\scripts\run_gradle
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call lang\java\scripts\run_gradle' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    java -jar priv/libs/ora_bench_java.jar setup_c
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'java -jar priv/libs/ora_bench_java.jar setup_c' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )
)

OraBench.exe %ORA_BENCH_FILE_CONFIGURATION_NAME_C%
if %ERRORLEVEL% neq 0 (
    echo Processing of the script: %0 - step: '.\OraBench.exe priv\properties\ora_bench_c.properties' was aborted, error code=%ERRORLEVEL%
    exit -1073741510
)

echo -------------------------------------------------------------------------------
echo:| TIME
echo -------------------------------------------------------------------------------
echo End   %0
echo ===============================================================================
