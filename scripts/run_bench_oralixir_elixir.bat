@echo off

rem ------------------------------------------------------------------------------
rem
rem run_bench_oralixir_elixir.bat: Oracle Benchmark based on Elixir.
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
echo ora_bench - Oracle benchmark - OraLixir and Elixir.
echo --------------------------------------------------------------------------------
echo BENCHMARK_DATABASE      : %ORA_BENCH_BENCHMARK_DATABASE%
echo CONNECTION_HOST         : %ORA_BENCH_CONNECTION_HOST%
echo CONNECTION_PORT         : %ORA_BENCH_CONNECTION_PORT%
echo CONNECTION_SERVICE      : %ORA_BENCH_CONNECTION_SERVICE%
echo --------------------------------------------------------------------------------
echo:| TIME
echo ================================================================================

java -cp "priv/java_jar/*" ch.konnexions.orabench.OraBench setup_elixir

cd src_elixir
mix deps.get
mix deps.compile
mix run -e "OraBench.CLI.main([\"OraLixir\"])"

echo 
echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================

exit /B %ERRORLEVEL%
