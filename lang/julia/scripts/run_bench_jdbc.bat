@echo off

rem --------------------------------------------------------------------------------
rem
rem run_bench_jdbc.bat: Oracle Benchmark based on Julia.
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

set ORA_BENCH_FILE_CONFIGURATION_NAME_TOML=priv\properties\ora_bench_toml.properties

echo ===============================================================================
echo Start %0
echo -------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - JDBC.jl and Julia.
echo -------------------------------------------------------------------------------
echo MULTIPLE_RUN                 : %ORA_BENCH_MULTIPLE_RUN%
echo -------------------------------------------------------------------------------
echo BENCHMARK_DATABASE           : %ORA_BENCH_BENCHMARK_DATABASE%
echo CONNECTION_HOST              : %ORA_BENCH_CONNECTION_HOST%
echo CONNECTION_PORT              : %ORA_BENCH_CONNECTION_PORT%
echo CONNECTION_SERVICE           : %ORA_BENCH_CONNECTION_SERVICE%
echo -------------------------------------------------------------------------------
echo BENCHMARK_BATCH_SIZE         : %ORA_BENCH_BENCHMARK_BATCH_SIZE%
echo BENCHMARK_CORE_MULTIPLIER    : %ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%
echo BENCHMARK_TRANSACTION_SIZE   : %ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%
echo -------------------------------------------------------------------------------
echo FILE_CONFIGURATION_NAME      : %ORA_BENCH_FILE_CONFIGURATION_NAME%
echo FILE_CONFIGURATION_NAME_TOML : %ORA_BENCH_FILE_CONFIGURATION_NAME_TOML%
echo -------------------------------------------------------------------------------
echo:| TIME
echo ===============================================================================

if NOT ["%ORA_BENCH_MULTIPLE_RUN%"] == ["true"] (
    call lang\java\scripts\run_gradle
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call lang\java\scripts\run_gradle' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    java -jar priv/libs/ora_bench_java.jar setup_toml
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'java -jar priv/libs/ora_bench_java.jar setup_toml' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )
)

set JULIA_COPY_STACKS=yes
julia --threads 8 lang\julia\OraBenchJdbc.jl %ORA_BENCH_FILE_CONFIGURATION_NAME_TOML%
if %ERRORLEVEL% neq 0 (
    echo Processing of the script: %0 - step: 'julia OraBenchJdbc.jl' was aborted, error code=%ERRORLEVEL%
    exit -1073741510
)

echo -------------------------------------------------------------------------------
echo:| TIME
echo -------------------------------------------------------------------------------
echo End   %0
echo ===============================================================================
