@echo off

rem ------------------------------------------------------------------------------
rem
rem run_bench_oranif.bat: Oracle Benchmark based on Erlang.
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
    set ORA_BENCH_FILE_CONFIGURATION_NAME=priv\properties\ora_bench.properties
)
if ["%ORA_BENCH_JAVA_CLASSPATH%"] EQU [""] (
    set ORA_BENCH_JAVA_CLASSPATH=.;priv\java_jar\*
)

echo ================================================================================
echo Start %0
echo --------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - oranif and Erlang.
echo --------------------------------------------------------------------------------
echo BENCHMARK_DATABASE      : %ORA_BENCH_BENCHMARK_DATABASE%
echo CONNECTION_HOST         : %ORA_BENCH_CONNECTION_HOST%
echo CONNECTION_PORT         : %ORA_BENCH_CONNECTION_PORT%
echo CONNECTION_SERVICE      : %ORA_BENCH_CONNECTION_SERVICE%
echo --------------------------------------------------------------------------------
echo:| TIME
echo ================================================================================

java -cp "priv/java_jar/*" ch.konnexions.orabench.OraBench setup_erlang

cd src_erlang
call rebar3 escriptize
cd ..

src_erlang\_build\default\bin\orabench priv\properties\ora_bench_oranif_erlang.properties

echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================

exit /B %ERRORLEVEL%
