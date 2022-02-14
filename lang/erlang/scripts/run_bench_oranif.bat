@echo off

rem --------------------------------------------------------------------------------
rem
rem run_bench_oranif.bat: Oracle Benchmark based on Erlang.
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
set ORA_BENCH_FILE_CONFIGURATION_NAME_ERLANG=priv\properties\ora_bench_erlang.properties

if ["%ORA_BENCH_BENCHMARK_VCVARSALL%"] EQU [""] (
    set "ORA_BENCH_BENCHMARK_VCVARSALL=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat"
)

echo ===============================================================================
echo Start %0
echo -------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - oranif and Erlang.
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
echo BENCHMARK_VCVARSALL            : %ORA_BENCH_BENCHMARK_VCVARSALL%
echo -------------------------------------------------------------------------------
echo FILE_CONFIGURATION_NAME        : %ORA_BENCH_FILE_CONFIGURATION_NAME%
echo FILE_CONFIGURATION_NAME_ERLANG : %ORA_BENCH_FILE_CONFIGURATION_NAME_ERLANG%
echo -------------------------------------------------------------------------------
echo:| TIME
echo ===============================================================================

if NOT ["%ORA_BENCH_MULTIPLE_RUN%"] == ["true"] (
    echo --------------------------------------------------------------------------------
    echo Set environment variables for C / C++ compilation.
    echo --------------------------------------------------------------------------------
    if exist "%ORA_BENCH_BENCHMARK_VCVARSALL%" (
        call "%ORA_BENCH_BENCHMARK_VCVARSALL%" x64
        if ERRORLEVEL 1 (
            echo Processing of the script: %0 - step: 'vcvarsall.bat' was aborted, error code=%ERRORLEVEL%
            exit -1073741510
        )
    )

    cd lang\erlang

    if EXIST _build\ rd /Q/S _build

    call rebar3 steamroll
    if ERRORLEVEL 1 (
        echo Processing of the script: %0 - step: 'call rebar3 steamroll' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    call rebar3 escriptize
    if ERRORLEVEL 1 (
        echo Processing of the script: %0 - step: 'call rebar3 escriptize' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    cd ..\..

    call lang\java\scripts\run_gradle
    if ERRORLEVEL 1 (
        echo Processing of the script: %0 - step: 'call lang\java\scripts\run_gradle' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    java -jar priv/libs/ora_bench_java.jar setup_erlang
    if ERRORLEVEL 1 (
        echo Processing of the script: %0 - step: 'java -jar priv/libs/ora_bench_java.jar setup_erlang' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )
)

lang\erlang\_build\default\bin\orabench %ORA_BENCH_FILE_CONFIGURATION_NAME_ERLANG%
if ERRORLEVEL 1 (
    echo Processing of the script: %0 - step: 'lang\erlang\_build\default\bin\orabench priv\properties\ora_bench_erlang.properties' was aborted, error code=%ERRORLEVEL%
    exit -1073741510
)

echo -------------------------------------------------------------------------------
echo:| TIME
echo -------------------------------------------------------------------------------
echo End   %0
echo ===============================================================================
