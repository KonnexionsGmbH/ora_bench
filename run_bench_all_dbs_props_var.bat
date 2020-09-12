@echo off

rem ------------------------------------------------------------------------------
rem
rem run_bench_all_dbs_props_var.bat: Oracle Benchmark for all database versions
rem                                  with variations of properties.
rem
rem ------------------------------------------------------------------------------

setlocal EnableDelayedExpansion

set ORA_BENCH_BENCHMARK_COMMENT="Standard series (locally)"

if exist ora_bench.log del /f /q ora_bench.log

set ORA_BENCH_CHOICE_DB_DEFAULT=complete
set ORA_BENCH_CHOICE_DRIVER_DEFAULT=complete

if ["%ORA_BENCH_CONNECTION_HOST%"] EQU [""] (
    set ORA_BENCH_CONNECTION_HOST=localhost
)
if ["%ORA_BENCH_CONNECTION_PORT%"] EQU [""] (
    set ORA_BENCH_CONNECTION_PORT=1521
)

if ["%1"] EQU [""] (
    echo =========================================================
    echo complete           - All implemented variations
    echo ---------------------------------------------------------
    echo c                  - C and ODPI
    echo elixir             - Elixir and oranif
    echo erlang_jamdb       - Erlang and JamDB
    echo erlang_oranif      - Erlang and oranif
    echo go                 - Go and GoDROR
    echo java               - Java and JDBC
    echo kotlin             - Kotlin and JDBC
    echo python             - Python and cx_Oracle
    echo ---------------------------------------------------------
    set /P ORA_BENCH_CHOICE_DRIVER="Enter the desired programming lanuage (and database driver) [default: %ORA_BENCH_CHOICE_DRIVER_DEFAULT%] "

    if ["!ORA_BENCH_CHOICE_DRIVER!"] EQU [""] (
        set ORA_BENCH_CHOICE_DRIVER=%ORA_BENCH_CHOICE_DRIVER_DEFAULT%
    )
) else (
    set ORA_BENCH_CHOICE_DRIVER=%1
)

set ORA_BENCH_RUN_CX_ORACLE_PYTHON=false
set ORA_BENCH_RUN_GODROR_GO=false
set ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG=false
set ORA_BENCH_RUN_JDBC_JAVA=false
set ORA_BENCH_RUN_JDBC_KOTLIN=false
set ORA_BENCH_RUN_ODPI_C=false
set ORA_BENCH_RUN_ORANIF_ELIXIR=false
set ORA_BENCH_RUN_ORANIF_ERLANG=false

if ["%ORA_BENCH_CHOICE_DRIVER%"] EQU ["complete"] (
    set ORA_BENCH_RUN_CX_ORACLE_PYTHON=true
    set ORA_BENCH_RUN_GODROR_GO=true
    set ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG=true
    set ORA_BENCH_RUN_JDBC_JAVA=true
    set ORA_BENCH_RUN_JDBC_KOTLIN=true
    set ORA_BENCH_RUN_ODPI_C=true
    set ORA_BENCH_RUN_ORANIF_ELIXIR=true
    set ORA_BENCH_RUN_ORANIF_ERLANG=true
)

if ["%ORA_BENCH_CHOICE_DRIVER%"] EQU ["c"] (
    set ORA_BENCH_RUN_ODPI_C=true
)

if ["%ORA_BENCH_CHOICE_DRIVER%"] EQU ["elixir"] (
    set ORA_BENCH_RUN_ORANIF_ELIXIR=true
)

if ["%ORA_BENCH_CHOICE_DRIVER%"] EQU ["erlang_jamdb"] (
    set ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG=true
)

if ["%ORA_BENCH_CHOICE_DRIVER%"] EQU ["erlang_oranif"] (
    set ORA_BENCH_RUN_ORANIF_ERLANG=true
)

if ["%ORA_BENCH_CHOICE_DRIVER%"] EQU ["go"] (
    set ORA_BENCH_RUN_GODROR_GO=true
)

if ["%ORA_BENCH_CHOICE_DRIVER%"] EQU ["java"] (
    set ORA_BENCH_RUN_JDBC_JAVA=true
)

if ["%ORA_BENCH_CHOICE_DRIVER%"] EQU ["kotlin"] (
    set ORA_BENCH_RUN_JDBC_KOTLIN=true
)

if ["%ORA_BENCH_CHOICE_DRIVER%"] EQU ["python"] (
    set ORA_BENCH_RUN_CX_ORACLE_PYTHON=true
)


if ["%2"] EQU [""] (
    echo =========================================================
    echo complete           - All implemented variations
    echo ---------------------------------------------------------
    echo 12                 - Oracle Database 12c Release 2
    echo 18                 - Oracle Database 18c 
    echo 19                 - Oracle Database 19c 
    echo ---------------------------------------------------------
    set /P  ORA_BENCH_CHOICE_DB="Enter the desired database version [default: %ORA_BENCH_CHOICE_DB_DEFAULT%] "

    if ["!ORA_BENCH_CHOICE_DB!"] EQU [""] (
        set ORA_BENCH_CHOICE_DB=%ORA_BENCH_CHOICE_DB_DEFAULT%
    )
) else (
    set ORA_BENCH_CHOICE_DB=%2
)

set ORA_BENCH_RUN_DB_12_2_EE=false
set ORA_BENCH_RUN_DB_18_3_EE=false
set ORA_BENCH_RUN_DB_19_3_EE=false

if ["%ORA_BENCH_CHOICE_DB%"] EQU ["complete"] (
    set ORA_BENCH_RUN_DB_12_2_EE=true
    set ORA_BENCH_RUN_DB_18_3_EE=true
    set ORA_BENCH_RUN_DB_19_3_EE=true
)

if ["%ORA_BENCH_CHOICE_DB%"] EQU ["12"] (
    set ORA_BENCH_RUN_DB_12_2_EE=true
)

if ["%ORA_BENCH_CHOICE_DB%"] EQU ["18"] (
    set ORA_BENCH_RUN_DB_18_3_EE=true
)

if ["%ORA_BENCH_CHOICE_DB%"] EQU ["19"] (
    set ORA_BENCH_RUN_DB_19_3_EE=true
)

set ORA_BENCH_PASSWORD_SYS=oracle

if ["%ORA_BENCH_CONNECTION_PORT%"] EQU [""] (
    set ORA_BENCH_FILE_CONFIGURATION_NAME=priv\properties\ora_bench.properties
)

if ["%RUN_GLOBAL_JAMDB%"] EQU [""] (
    set RUN_GLOBAL_JAMDB=true
)
if ["%RUN_GLOBAL_NON_JAMDB%"] EQU [""] (
    set RUN_GLOBAL_NON_JAMDB=true
)

echo.
echo Script %0 is now running
echo.
echo You can find the run log in the file run_bench_all_dbs_props_var.log
echo.
echo Please wait ...
echo.

> run_bench_all_dbs_props_var.log 2>&1 (

    echo ================================================================================
    echo Start %0
    echo --------------------------------------------------------------------------------
    echo ora_bench - Oracle benchmark - all databases with property variations.
    echo --------------------------------------------------------------------------------
    echo CHOICE_DB                     : %ORA_BENCH_CHOICE_DB%
    echo CHOICE_DRIVER                 : %ORA_BENCH_CHOICE_DRIVER%
    echo --------------------------------------------------------------------------------
    echo:| TIME
    echo ================================================================================
    
    set ORA_BENCH_BENCHMARK_BATCH_SIZE_DEFAULT=256
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER_DEFAULT=0
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE_DEFAULT=512
    
    if ["%ORA_BENCH_RUN_DB_12_2_EE%"] EQU ["true"] (
        set ORA_BENCH_BENCHMARK_DATABASE=db_12_2_ee
        set ORA_BENCH_CONNECTION_SERVICE=orclpdb1
        call scripts\run_properties_variations.bat
        if %ERRORLEVEL% NEQ 0 (
            echo Processing of the script was aborted, error code=%ERRORLEVEL%
            exit %ERRORLEVEL%
        )
    )
    
    if ["%ORA_BENCH_RUN_DB_18_3_EE%"] EQU ["true"] (
        set ORA_BENCH_BENCHMARK_DATABASE=db_18_3_ee
        set ORA_BENCH_CONNECTION_SERVICE=orclpdb1
        call scripts\run_properties_variations.bat
        if %ERRORLEVEL% NEQ 0 (
            echo Processing of the script was aborted, error code=%ERRORLEVEL%
            exit %ERRORLEVEL%
        )
    )
    
    if ["%ORA_BENCH_RUN_DB_19_3_EE%"] EQU ["true"] (
        set ORA_BENCH_BENCHMARK_DATABASE=db_19_3_ee
        set ORA_BENCH_CONNECTION_SERVICE=orclpdb1
        call scripts\run_properties_variations.bat
        if %ERRORLEVEL% NEQ 0 (
            echo Processing of the script was aborted, error code=%ERRORLEVEL%
            exit %ERRORLEVEL%
        )
    )
    
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER_DEFAULT=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    
    echo --------------------------------------------------------------------------------
    echo:| TIME
    echo --------------------------------------------------------------------------------
    echo End   %0
    echo ================================================================================
    
    start priv\audio\end_of_series.mp3
    if %ERRORLEVEL% NEQ 0 (
        echo Processing of the script was aborted, error code=%ERRORLEVEL%
        exit %ERRORLEVEL%
    )
)
