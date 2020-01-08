@echo off

rem ------------------------------------------------------------------------------
rem
rem run_bench.bat: Oracle Benchmark for all database versions.
rem
rem ------------------------------------------------------------------------------

set ORA_BENCH_BENCHMARK_COMMENT="Standard tests (locally)"

set ORA_BENCH_CONNECTION_HOST=0.0.0.0
set ORA_BENCH_CONNECTION_PORT=1521

set ORA_BENCH_FILE_CONFIGURATION_NAME=priv\properties\ora_bench.properties

set ORA_BENCH_RUN_DB_12_2_EE=true
set ORA_BENCH_RUN_DB_18_3_EE=true
set ORA_BENCH_RUN_DB_19_3_EE=true

set ORA_BENCH_RUN_CX_ORACLE_PYTHON=true
set ORA_BENCH_RUN_JAMDB_ORACLE_ELIXIR=false
set ORA_BENCH_RUN_JDBC_JAVA=true
set ORA_BENCH_RUN_ODPI_C=true
set ORA_BENCH_RUN_ORANIF_ELIXIR=true
set ORA_BENCH_RUN_ORANIF_ERLANG=true

if ["%ORA_BENCH_JAVA_CLASSPATH%"] EQU [""] (
    set ORA_BENCH_JAVA_CLASSPATH=.;priv\java_jar\*
)

set ORA_BENCH_PASSWORD_SYS=oracle

echo.
echo Skript %0 is now running
echo.
echo You can find the run log in the file run_bench.log
echo.
echo Please wait ...
echo.

> run_bench.log 2>&1 (

    echo ================================================================================
    echo Start %0
    echo --------------------------------------------------------------------------------
    echo ora_bench - Oracle benchmark - all databases.
    echo --------------------------------------------------------------------------------
    echo BENCHMARK_BATCH_SIZE       : %ORA_BENCH_BENCHMARK_BATCH_SIZE%
    echo BENCHMARK_COMMENT          : %ORA_BENCH_BENCHMARK_COMMENT%
    echo BENCHMARK_TRANSACTION_SIZE : %ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%
    echo CONNECTION_HOST            : %ORA_BENCH_CONNECTION_HOST%
    echo CONNECTION_PORT            : %ORA_BENCH_CONNECTION_PORT%
    echo FILE_CONFIGURATION_NAME    : %ORA_BENCH_FILE_CONFIGURATION_NAME%
    echo JAVA_CLASSPATH             : %ORA_BENCH_JAVA_CLASSPATH%
    echo --------------------------------------------------------------------------------
    echo RUN_DB_12_2_EE             : %ORA_BENCH_RUN_DB_12_2_EE%
    echo RUN_DB_18_3_EE             : %ORA_BENCH_RUN_DB_18_3_EE%
    echo RUN_DB_19_3_EE             : %ORA_BENCH_RUN_DB_19_3_EE%
    echo --------------------------------------------------------------------------------
    echo RUN_CX_ORACLE_PYTHON       : %ORA_BENCH_RUN_CX_ORACLE_PYTHON%
    echo RUN_JAMDB_ORACLE_ELIXIR    : %ORA_BENCH_RUN_JAMDB_ORACLE_ELIXIR%
    echo RUN_JDBC_JAVA              : %ORA_BENCH_RUN_JDBC_JAVA%
    echo RUN_ODPI_C                 : %ORA_BENCH_RUN_ODPI_C%
    echo RUN_ORANIF_ELIXIR          : %ORA_BENCH_RUN_ORANIF_ELIXIR%
    echo RUN_ORANIF_ERLANG          : %ORA_BENCH_RUN_ORANIF_ERLANG%
    echo --------------------------------------------------------------------------------
    echo JAVA_HOME                  : %JAVA_HOME%
    echo --------------------------------------------------------------------------------
    echo:| TIME
    echo ================================================================================
    
    call scripts\run_bench_setup.bat
    
    if ["%ORA_BENCH_RUN_DB_12_2_EE%"] EQU ["true"] (
        set ORA_BENCH_BENCHMARK_DATABASE=db_12_2_ee
        set ORA_BENCH_CONNECTION_SERVICE=orclpdb1
        call scripts\run_bench_database.bat
    )
    
    if ["%ORA_BENCH_RUN_DB_18_3_EE%"] EQU ["true"] (
        set ORA_BENCH_BENCHMARK_DATABASE=db_18_3_ee
        set ORA_BENCH_CONNECTION_SERVICE=orclpdb1
        call scripts\run_bench_database.bat
    )
    
    if ["%ORA_BENCH_RUN_DB_19_3_EE%"] EQU ["true"] (
        set ORA_BENCH_BENCHMARK_DATABASE=db_19_3_ee
        set ORA_BENCH_CONNECTION_SERVICE=orclpdb1
        call scripts\run_bench_database.bat
    )
    
    call scripts\run_bench_finalise.bat

    echo --------------------------------------------------------------------------------
    echo:| TIME
    echo --------------------------------------------------------------------------------
    echo End   %0
    echo ================================================================================
    
    exit /B %ERRORLEVEL%
)
