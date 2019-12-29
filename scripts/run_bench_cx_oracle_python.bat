@echo off

rem ------------------------------------------------------------------------------
rem
rem run_bench_cx_oracle_python.bat: Oracle Benchmark based on Python.
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
if ["%ORA_BENCH_FILE_CONFIGURATION_NAME%"] EQU [""] (
    set ORA_BENCH_FILE_CONFIGURATION_NAME=priv/properties/ora_bench.properties
)
if ["%ORA_BENCH_JAVA_CLASSPATH%"] EQU [""] (
    set ORA_BENCH_JAVA_CLASSPATH=.;priv\java_jar\*
)

echo ================================================================================
echo Start %0
echo --------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - cx_Oracle and Python.
echo --------------------------------------------------------------------------------
echo BENCHMARK_DATABASE      : %ORA_BENCH_BENCHMARK_DATABASE%
echo CONNECTION_HOST         : %ORA_BENCH_CONNECTION_HOST%
echo CONNECTION_PORT         : %ORA_BENCH_CONNECTION_PORT%
echo CONNECTION_SERVICE      : %ORA_BENCH_CONNECTION_SERVICE%
echo --------------------------------------------------------------------------------
echo:| TIME
echo ================================================================================

java -cp "priv/java_jar/*" ch.konnexions.orabench.OraBench setup_python

python src_python/OraBench.py

echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================

exit /B %ERRORLEVEL%
