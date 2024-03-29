@echo off

rem --------------------------------------------------------------------------------
rem
rem run_all_dbs_props_var.bat: Oracle Benchmark for all database versions
rem                            with variations of properties.
rem
rem --------------------------------------------------------------------------------

setlocal EnableDelayedExpansion

set ORA_BENCH_MULTIPLE_RUN=true

set ORA_BENCH_BENCHMARK_COMMENT="Standard series (locally)"

set ORA_BENCH_BENCHMARK_DATABASE_DEFAULT=21
set ORA_BENCH_CHOICE_DRIVER_DEFAULT=none
set ORA_BENCH_CONNECTION_HOST_DEFAULT=localhost
set ORA_BENCH_CONNECTION_PORT_DEFAULT=1521

if exist ora_bench.log del /f /q ora_bench.log
if exist priv\ora_bench_result.csv del /f /q priv\ora_bench_result.csv
if exist priv\ora_bench_result.tsv del /f /q priv\ora_bench_result.tsv

if ["%ORA_BENCH_CONNECTION_HOST%"] EQU [""] (
    set ORA_BENCH_CONNECTION_HOST=%ORA_BENCH_CONNECTION_HOST_DEFAULT%
)
if ["%ORA_BENCH_CONNECTION_PORT%"] EQU [""] (
    set ORA_BENCH_CONNECTION_PORT=%ORA_BENCH_CONNECTION_PORT_DEFAULT%
)

if ["%1"] EQU [""] (
    echo ===============================================================================
    echo complete           - All implemented variations
    echo none               - Without specific driver run
    echo -------------------------------------------------------------------------------
    echo c                  - C++ [gcc] and Oracle ODPI-C
    echo elixir             - Elixir and oranif
    echo erlang             - Erlang and oranif
    echo go                 - Go and godror
    echo java               - Java and Oracle JDBC
    echo julia_jdbc         - Julia and JDBC.jl
    echo julia_oracle       - Julia and Oracle.jl
    echo kotlin             - Kotlin and Oracle JDBC
    echo nim                - Nim and nimodpi
    echo python             - Python 3 and cx_Oracle
    echo rust               - Rust and Rust-oracle
    echo -------------------------------------------------------------------------------
    set /P ORA_BENCH_CHOICE_DRIVER="Enter the desired programming language (and database driver) [default: %ORA_BENCH_CHOICE_DRIVER_DEFAULT%] "

    if ["!ORA_BENCH_CHOICE_DRIVER!"] EQU [""] (
        set ORA_BENCH_CHOICE_DRIVER=%ORA_BENCH_CHOICE_DRIVER_DEFAULT%
    )
) else (
    set ORA_BENCH_CHOICE_DRIVER=%1
)

if ["%2"] EQU [""] (
    echo ===============================================================================
    echo complete           - All implemented variations
    echo -------------------------------------------------------------------------------
    echo 18xe               - Oracle Database 18c Express Edition
    echo 19                 - Oracle Database 19c 
    echo 21                 - Oracle Database 21c
    echo 21xe               - Oracle Database 21c Express Edition
    echo -------------------------------------------------------------------------------
    set /P  ORA_BENCH_CHOICE_DB="Enter the desired database version [default: %ORA_BENCH_BENCHMARK_DATABASE_DEFAULT%] "

    if ["!ORA_BENCH_CHOICE_DB!"] EQU [""] (
        set ORA_BENCH_CHOICE_DB=%ORA_BENCH_BENCHMARK_DATABASE_DEFAULT%
    )
) else (
    set ORA_BENCH_CHOICE_DB=%2
)

set ERRORLEVEL=0

set ORA_BENCH_RUN_DB_18_4_XE=false
set ORA_BENCH_RUN_DB_19_3_EE=false
set ORA_BENCH_RUN_DB_21_3_EE=false
set ORA_BENCH_RUN_DB_21_3_XE=false

if ["%ORA_BENCH_CHOICE_DB%"] EQU ["complete"] (
    set ORA_BENCH_RUN_DB_18_4_XE=true
    set ORA_BENCH_RUN_DB_19_3_EE=true
    set ORA_BENCH_RUN_DB_21_3_EE=true
    set ORA_BENCH_RUN_DB_21_3_XE=true
)

if ["%ORA_BENCH_CHOICE_DB%"] EQU ["18xe"] (
    set ORA_BENCH_RUN_DB_18_4_XE=true
)

if ["%ORA_BENCH_CHOICE_DB%"] EQU ["19"] (
    set ORA_BENCH_RUN_DB_19_3_EE=true
)

if ["%ORA_BENCH_CHOICE_DB%"] EQU ["21"] (
    set ORA_BENCH_RUN_DB_21_3_EE=true
)

if ["%ORA_BENCH_CHOICE_DB%"] EQU ["21xe"] (
    set ORA_BENCH_RUN_DB_21_3_XE=true
)

set ORA_BENCH_PASSWORD_SYS=oracle

if ["%ORA_BENCH_CONNECTION_PORT%"] EQU [""] (
    set ORA_BENCH_FILE_CONFIGURATION_NAME=priv\properties\ora_bench.properties
)

echo.
echo Script %0 is now running
echo.
echo You can find the run log in the file run_all_dbs_props_var.log
echo.
echo Please wait ...
echo.

> run_all_dbs_props_var.log 2>&1 (

    echo ===============================================================================
    echo Start %0
    echo -------------------------------------------------------------------------------
    echo ora_bench - Oracle benchmark - all databases with property variations.
    echo -------------------------------------------------------------------------------
    echo MULTIPLE_RUN                      : %ORA_BENCH_MULTIPLE_RUN%
    echo ------------------------------------------------------------------------------
    echo CHOICE_DRIVER                     : %ORA_BENCH_CHOICE_DRIVER%
    echo CHOICE_DB                         : %ORA_BENCH_CHOICE_DB%
    echo -------------------------------------------------------------------------------
    echo:| TIME
    echo ===============================================================================
    
    set ORA_BENCH_BENCHMARK_BATCH_SIZE_DEFAULT=256
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER_DEFAULT=0
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE_DEFAULT=512
    
    if ["%ORA_BENCH_RUN_DB_18_4_XE%"] EQU ["true"] (
        set ORA_BENCH_BENCHMARK_DATABASE=db_18_4_xe
        set ORA_BENCH_CONNECTION_SERVICE=xe
        call scripts\run_properties_variations.bat
        if %ERRORLEVEL% neq 0 (
            echo Processing of the script: %0 - step: 'call scripts\run_properties_variations.bat' was aborted, error code=%ERRORLEVEL%
            exit -1073741510
        )
    )
    
    if ["%ORA_BENCH_RUN_DB_19_3_EE%"] EQU ["true"] (
        set ORA_BENCH_BENCHMARK_DATABASE=db_19_3_ee
        set ORA_BENCH_CONNECTION_SERVICE=orclpdb1
        call scripts\run_properties_variations.bat
        if %ERRORLEVEL% neq 0 (
            echo Processing of the script: %0 - step: 'call scripts\run_properties_variations.bat' was aborted, error code=%ERRORLEVEL%
            exit -1073741510
        )
    )

    if ["%ORA_BENCH_RUN_DB_21_3_EE%"] EQU ["true"] (
        set ORA_BENCH_BENCHMARK_DATABASE=db_21_3_ee
        set ORA_BENCH_CONNECTION_SERVICE=orclpdb1
        call scripts\run_properties_variations.bat
        if %ERRORLEVEL% neq 0 (
            echo Processing of the script: %0 - step: 'call scripts\run_properties_variations.bat' was aborted, error code=%ERRORLEVEL%
            exit -1073741510
        )
    )

    if ["%ORA_BENCH_RUN_DB_21_3_XE%"] EQU ["true"] (
        set ORA_BENCH_BENCHMARK_DATABASE=db_21_3_xe
        set ORA_BENCH_CONNECTION_SERVICE=xe
        call scripts\run_properties_variations.bat
        if %ERRORLEVEL% neq 0 (
            echo Processing of the script: %0 - step: 'call scripts\run_properties_variations.bat' was aborted, error code=%ERRORLEVEL%
            exit -1073741510
        )
    )

    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER_DEFAULT=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    
    echo -------------------------------------------------------------------------------
    echo:| TIME
    echo -------------------------------------------------------------------------------
    echo End   %0
    echo ===============================================================================
    
    start priv\audio\end_of_series.mp3
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'start priv\audio\end_of_series.mp3' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )
)
