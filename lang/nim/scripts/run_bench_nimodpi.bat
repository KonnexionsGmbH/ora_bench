@echo off

rem --------------------------------------------------------------------------------
rem
rem run_bench_nimodpi.bat: Oracle Benchmark based on Go.
rem
rem --------------------------------------------------------------------------------

if ["%ORA_BENCH_BENCHMARK_DATABASE%"] EQU [""] (
    set ORA_BENCH_BENCHMARK_DATABASE=db_21_3_ee
)
if ["%ORA_BENCH_CONNECTION_HOST%"] EQU [""] (
    set javaORA_BENCH_CONNECTION_HOST=localhost
)
if ["%ORA_BENCH_CONNECTION_PORT%"] EQU [""] (
    set ORA_BENCH_CONNECTION_PORT=1521
)
if ["%ORA_BENCH_CONNECTION_SERVICE%"] EQU [""] (
    set ORA_BENCH_CONNECTION_SERVICE=orclpdb1
)

set ORA_BENCH_FILE_CONFIGURATION_NAME=priv\properties\ora_bench.properties
set ORA_BENCH_FILE_CONFIGURATION_NAME_YAML=priv\properties\ora_bench_yaml.properties

echo ===============================================================================
echo Start %0
echo -------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - nimodpi and Nim.
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
echo FILE_CONFIGURATION_NAME_YAML : %ORA_BENCH_FILE_CONFIGURATION_NAME_YAML%
echo -------------------------------------------------------------------------------
echo:| TIME
echo ===============================================================================

if NOT ["%ORA_BENCH_MULTIPLE_RUN%"] == ["true"] (
    make -C lang\nim
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'make' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    call lang\java\scripts\run_gradle
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call lang\java\scripts\run_gradle' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    java -jar priv/libs/ora_bench_java.jar setup_yaml
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'java -jar priv/libs/ora_bench_java.jar setup_yaml' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )
)

lang\nim\bin\ora_bench.exe %ORA_BENCH_FILE_CONFIGURATION_NAME_YAML%
if %ERRORLEVEL% neq 0 (
    echo Processing of the script: %0 - step: 'lang\nim\bin\ora_bench.exe' was aborted, error code=%ERRORLEVEL%
    exit -1073741510
)

echo -------------------------------------------------------------------------------
echo:| TIME
echo -------------------------------------------------------------------------------
echo End   %0
echo ===============================================================================
