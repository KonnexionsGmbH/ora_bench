@echo off

rem ------------------------------------------------------------------------------
rem
rem run_bench_jdbc.bat: Oracle Benchmark based on Kotlin.
rem
rem ------------------------------------------------------------------------------

if ["%ORA_BENCH_BENCHMARK_DATABASE%"] EQU [""] (
    set ORA_BENCH_BENCHMARK_DATABASE=db_19_3_ee
)
if ["%ORA_BENCH_CONNECTION_HOST%"] EQU [""] (
    set ORA_BENCH_CONNECTION_HOST=ora_bench_db
)
if ["%ORA_BENCH_CONNECTION_PORT%"] EQU [""] (
    set ORA_BENCH_CONNECTION_PORT=1521
)
if ["%ORA_BENCH_CONNECTION_SERVICE%"] EQU [""] (
    set ORA_BENCH_CONNECTION_SERVICE=orclpdb1
)

if ["%ORA_BENCH_FILE_CONFIGURATION_NAME%"] EQU [""] (
    set ORA_BENCH_FILE_CONFIGURATION_NAME=priv/properties/ora_bench.properties
)

if ["%ORA_BENCH_JAVA_CLASSPATH%"] EQU [""] (
    set ORA_BENCH_JAVA_CLASSPATH=.;priv/libs/*;JAVA_HOME/lib;
)

echo ================================================================================
echo Start %0
echo --------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - JDBC and Kotlin.
echo --------------------------------------------------------------------------------
echo MULTIPLE_RUN               : %ORA_BENCH_MULTIPLE_RUN%
echo --------------------------------------------------------------------------------
echo BENCHMARK_DATABASE         : %ORA_BENCH_BENCHMARK_DATABASE%
echo CONNECTION_HOST            : %ORA_BENCH_CONNECTION_HOST%
echo CONNECTION_PORT            : %ORA_BENCH_CONNECTION_PORT%
echo CONNECTION_SERVICE         : %ORA_BENCH_CONNECTION_SERVICE%
echo --------------------------------------------------------------------------------
echo BENCHMARK_BATCH_SIZE       : %ORA_BENCH_BENCHMARK_BATCH_SIZE%
echo BENCHMARK_CORE_MULTIPLIER  : %ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%
echo BENCHMARK_TRANSACTION_SIZE : %ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%
echo --------------------------------------------------------------------------------
echo FILE_CONFIGURATION_NAME    : %ORA_BENCH_FILE_CONFIGURATION_NAME%
echo --------------------------------------------------------------------------------
echo JAVA_CLASSPATH             : %ORA_BENCH_JAVA_CLASSPATH%
echo --------------------------------------------------------------------------------
echo:| TIME
echo ================================================================================

if NOT ["%ORA_BENCH_MULTIPLE_RUN%"] == ["true"] (
    call src_kotlin\scripts\run_gradle
    if %ERRORLEVEL% NEQ 0 (
        echo Processing of the script was aborted, error code=%ERRORLEVEL%
        exit %ERRORLEVEL%
    )

    call src_java\scripts\run_gradle
    if %ERRORLEVEL% NEQ 0 (
        echo Processing of the script was aborted, error code=%ERRORLEVEL%
        exit %ERRORLEVEL%
    )
)    

java -cp %ORA_BENCH_JAVA_CLASSPATH% ch.konnexions.orabench.OraBench setup
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)    

java -jar priv/libs/ora_bench_kotlin.jar
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)

echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================
