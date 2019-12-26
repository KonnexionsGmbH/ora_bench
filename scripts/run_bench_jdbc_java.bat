@echo off

rem ------------------------------------------------------------------------------
rem
rem run_bench_jdbc_java.bat: Oracle Benchmark based on Java.
rem
rem ------------------------------------------------------------------------------

if ["%ORA_BENCH_BENCHMARK_DATABASE%"] EQU [""] (
    set ORA_BENCH_BENCHMARK_DATABASE=db_19_3_ee
)
if ["%ORA_BENCH_CONNECTION_HOST%"] EQU [""] (
    set ORA_BENCH_CONNECTION_HOST=0.0.0.0
)
if ["%ORA_BENCH_CONNECTION_PORT%"] EQU [""] (
    set ORA_BENCH_CONNECTION_PORT=1521
)
if ["%ORA_BENCH_CONNECTION_SERVICE%"] EQU [""] (
    set ORA_BENCH_CONNECTION_SERVICE=orclpdb1
)
if ["%ORA_BENCH_JAVA_CLASSPATH%"] EQU [""] (
    set ORA_BENCH_JAVA_CLASSPATH=.;priv\java_jar\*
)

if ["%ORA_BENCH_FILE_CONFIGURATION_NAME%"] EQU [""] (
    set ORA_BENCH_FILE_CONFIGURATION_NAME=priv/properties/ora_bench.properties
    make -f src_java\Makefile clean
    make -f src_java\Makefile
)

echo ================================================================================
echo Start %0
echo --------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - JDBC and Java.
echo --------------------------------------------------------------------------------
echo BENCHMARK_DATABASE      : %ORA_BENCH_BENCHMARK_DATABASE%
echo CONNECTION_HOST         : %ORA_BENCH_CONNECTION_HOST%
echo CONNECTION_PORT         : %ORA_BENCH_CONNECTION_PORT%
echo CONNECTION_SERVICE      : %ORA_BENCH_CONNECTION_SERVICE%
echo FILE_CONFIGURATION_NAME : %ORA_BENCH_FILE_CONFIGURATION_NAME%
echo JAVA_CLASSPATH          : %ORA_BENCH_JAVA_CLASSPATH%
echo --------------------------------------------------------------------------------
echo:| TIME
echo ================================================================================

set PATH=%PATH%;\u01\app\oracle\product\12.2\db_1\jdbc\lib

java -cp "%ORA_BENCH_JAVA_CLASSPATH%" ch.konnexions.orabench.OraBench runBenchmark

echo 
echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================

exit /B %ERRORLEVEL%
