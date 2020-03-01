@echo off

rem ------------------------------------------------------------------------------
rem
rem run_properties_standard.bat: Run with standard properties.
rem
rem ------------------------------------------------------------------------------

setlocal EnableDelayedExpansion

set ORA_BENCH_MULTIPLE_RUN=true

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
if ["%ORA_BENCH_PASSWORD_SYS%"] EQU [""] (
    set ORA_BENCH_PASSWORD_SYS=oracle
)

if ["%ORA_BENCH_RUN_CX_ORACLE_PYTHON%"] EQU [""] (
    set ORA_BENCH_RUN_CX_ORACLE_PYTHON=true
)
if ["%ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG%"] EQU [""] (
    set ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG=true
)
if ["%ORA_BENCH_RUN_JDBC_JAVA%"] EQU [""] (
    set ORA_BENCH_RUN_JDBC_JAVA=true
)
if ["%ORA_BENCH_RUN_ODPI_C%"] EQU [""] (
    set ORA_BENCH_RUN_ODPI_C=true
)
if ["%ORA_BENCH_RUN_ORANIF_ELIXIR%"] EQU [""] (
    set ORA_BENCH_RUN_ORANIF_ELIXIR=true
)
if ["%ORA_BENCH_RUN_ORANIF_ERLANG%"] EQU [""] (
    set ORA_BENCH_RUN_ORANIF_ERLANG=true
)

if ["%RUN_GLOBAL_JAMDB%"] EQU [""] (
    set RUN_GLOBAL_JAMDB=true
)    
if ["%RUN_GLOBAL_NON_JAMDB%"] EQU [""] (
    set RUN_GLOBAL_NON_JAMDB=true
)

echo ================================================================================
echo Start %0
echo --------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - database setup and Oracle benchmark - standard.
echo --------------------------------------------------------------------------------
echo MULTIPLE_RUN               : %ORA_BENCH_MULTIPLE_RUN%
echo --------------------------------------------------------------------------------
echo RUN_GLOBAL_JAMDB           : %RUN_GLOBAL_JAMDB%
echo RUN_GLOBAL_NON_JAMDB       : %RUN_GLOBAL_NON_JAMDB%
echo --------------------------------------------------------------------------------
echo:| TIME
echo ================================================================================

call scripts\run_collect_and_compile.bat
if %ERRORLEVEL% NEQ 0 (
    echo ERRORLEVEL : %ERRORLEVEL%
    GOTO EndOfScript
)

call scripts\run_db_setup.bat
if %ERRORLEVEL% NEQ 0 (
    echo ERRORLEVEL : %ERRORLEVEL%
    GOTO EndOfScript
)

call scripts\run_bench_all_drivers.bat
if %ERRORLEVEL% NEQ 0 (
    echo ERRORLEVEL : %ERRORLEVEL%
)

:EndOfScript
echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================

exit /B %ERRORLEVEL%