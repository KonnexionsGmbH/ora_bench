@echo off

rem ------------------------------------------------------------------------------
rem
rem run_ora_bench_release.bat: Release run for Windows 10.
rem
rem ------------------------------------------------------------------------------

setlocal EnableDelayedExpansion

set ERRORLEVEL=

set ORA_BENCH_BENCHMARK_COMMENT="Release"
set ORA_BENCH_CONNECTION_HOST=localhost
set ORA_BENCH_CONNECTION_PORT=1521

set ORA_BENCH_ORACLE_DATABASE_ANY=false
set ORA_BENCH_ORACLE_DATABASE_18C=false
set ORA_BENCH_ORACLE_DATABASE_19C=false
set ORA_BENCH_ORACLE_DATABASE_21C=true
set ORA_BENCH_ORACLE_DATABASE_EXISTING=false

set ORA_BENCH_FILE_CONFIGURATION_NAME=priv\properties\ora_bench.properties
set ORA_BENCH_PASSWORD_SYS=oracle

set ORA_BENCH_RUN_CX_ORACLE_PYTHON=true
set ORA_BENCH_RUN_GODROR_GO=true
set ORA_BENCH_RUN_JDBC_JAVA=true
set ORA_BENCH_RUN_JDBC_JULIA=false
set ORA_BENCH_RUN_JDBC_KOTLIN=true
set ORA_BENCH_RUN_ODPI_C=false
set ORA_BENCH_RUN_ORACLE_JULIA=false
set ORA_BENCH_RUN_ORANIF_ELIXIR=true
set ORA_BENCH_RUN_ORANIF_ERLANG=true

if ["%ORA_BENCH_ORACLE_DATABASE_EXISTING%"] EQU ["true"] (
    set ORA_BENCH_ORACLE_DATABASE_ANY=true
)
if ["%ORA_BENCH_ORACLE_DATABASE_18C%"] EQU ["true"] (
    set ORA_BENCH_ORACLE_DATABASE_ANY=true
)
if ["%ORA_BENCH_ORACLE_DATABASE_19C%"] EQU ["true"] (
    set ORA_BENCH_ORACLE_DATABASE_ANY=true
)
if ["%ORA_BENCH_ORACLE_DATABASE_21C%"] EQU ["true"] (
    set ORA_BENCH_ORACLE_DATABASE_ANY=true
)

echo.
echo Script %0 is now running
echo.
echo You can find the run log in the file run_ora_bench_release.log
echo.
echo Please wait ...
echo.

> run_ora_bench_release.log 2>&1 (

    echo ================================================================================
    echo Start %0
    echo --------------------------------------------------------------------------------
    echo OraBench - Release run for Windows 10.
    echo --------------------------------------------------------------------------------
    echo:| TIME
    echo ================================================================================
    echo ORACLE_DATABASE_EXISTING : %ORA_BENCH_ORACLE_DATABASE_EXISTING%
    echo ORACLE_DATABASE_18C      : %ORA_BENCH_ORACLE_DATABASE_18C%
    echo ORACLE_DATABASE_19C      : %ORA_BENCH_ORACLE_DATABASE_19C%
    echo ORACLE_DATABASE_21C      : %ORA_BENCH_ORACLE_DATABASE_21C%
    echo --------------------------------------------------------------------------------
    echo RUN_CX_ORACLE_PYTHON     : %ORA_BENCH_RUN_CX_ORACLE_PYTHON%
    echo RUN_GODROR_GO            : %ORA_BENCH_RUN_GODROR_GO%
    echo RUN_JDBC_JAVA            : %ORA_BENCH_RUN_JDBC_JAVA%
    echo RUN_JDBC_JULIA           : %ORA_BENCH_RUN_JDBC_JULIA%
    echo RUN_JDBC_KOTLIN          : %ORA_BENCH_RUN_JDBC_KOTLIN%
    echo RUN_ODPI_C               : %ORA_BENCH_RUN_ODPI_C%
    echo RUN_ORACLE_JULIA         : %ORA_BENCH_RUN_ORACLE_JULIA%
    echo RUN_ORANIF_ELIXIR        : %ORA_BENCH_RUN_ORANIF_ELIXIR%
    echo RUN_ORANIF_ERLANG        : %ORA_BENCH_RUN_ORANIF_ERLANG%
    echo ================================================================================

    if ["%ORA_BENCH_ORACLE_DATABASE_ANY%"] EQU ["true"] (

        if exist ora_bench.log del /f /q ora_bench.log
        if exist priv\ora_bench_result.csv del /f /q priv\ora_bench_result.csv
        if exist priv\ora_bench_result.tsv del /f /q priv\ora_bench_result.tsv
    
        echo --------------------------------------------------------------------------------
        echo Collect libraries and compile.
        echo --------------------------------------------------------------------------------
        call scripts\run_collect_and_compile.bat
        if %ERRORLEVEL% neq 0 (
            echo Processing of the script: %0 - step: 'call scripts\run_collect_and_compile.bat' was aborted, error code=%ERRORLEVEL%
            exit -1073741510
        )
    
        echo --------------------------------------------------------------------------------
        echo Create bulk file.
        echo --------------------------------------------------------------------------------
        call scripts\run_create_bulk_file.bat
        if %ERRORLEVEL% neq 0 (
            echo Processing of the script: %0 - step: 'call scripts\run_create_bulk_file.bat' was aborted, error code=%ERRORLEVEL%
            exit -1073741510
        )
        
        if ["%ORA_BENCH_ORACLE_DATABASE_EXISTING%"] EQU ["true"] (
            echo --------------------------------------------------------------------------------
            echo Oracle Database already existing.
            echo --------------------------------------------------------------------------------
            docker ps -a
            docker start ora_bench_db
    
            set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
            set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=0
            set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0

            call scripts\run_all_drivers.bat
            if %ERRORLEVEL% neq 0 (
                echo Processing of the script: %0 - step: 'call scripts\run_all_drivers.bat' was aborted, error code=%ERRORLEVEL%
                exit -1073741510
            )
    
            set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
            set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
            set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0

            call scripts\run_all_drivers.bat
            if %ERRORLEVEL% neq 0 (
                echo Processing of the script: %0 - step: 'call scripts\run_all_drivers.bat' was aborted, error code=%ERRORLEVEL%
                exit -1073741510
            )
    
            set ORA_BENCH_BENCHMARK_BATCH_SIZE=512
            set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=0
            set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=512

            call scripts\run_all_drivers.bat
            if %ERRORLEVEL% neq 0 (
                echo Processing of the script: %0 - step: 'call scripts\run_all_drivers.bat' was aborted, error code=%ERRORLEVEL%
                exit -1073741510
            )
    
            set ORA_BENCH_BENCHMARK_BATCH_SIZE=512
            set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
            set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=512

            call scripts\run_all_drivers.bat
            if %ERRORLEVEL% neq 0 (
                echo Processing of the script: %0 - step: 'call scripts\run_all_drivers.bat' was aborted, error code=%ERRORLEVEL%
                exit -1073741510
            )
        )
    
        if ["%ORA_BENCH_ORACLE_DATABASE_18C%"] EQU ["true"] (
            echo --------------------------------------------------------------------------------
            echo Oracle Database Express Edition 18c.
            echo --------------------------------------------------------------------------------
            set ORA_BENCH_BENCHMARK_DATABASE=db_18_4_xe
            set ORA_BENCH_CONNECTION_SERVICE=xe
        )
    
        if ["%ORA_BENCH_ORACLE_DATABASE_19C%"] EQU ["true"] (
            echo --------------------------------------------------------------------------------
            echo Oracle Database 19c.
            echo --------------------------------------------------------------------------------
            set ORA_BENCH_BENCHMARK_DATABASE=db_19_3_ee
            set ORA_BENCH_CONNECTION_SERVICE=orclpdb1
        )
    
        if ["%ORA_BENCH_ORACLE_DATABASE_21C%"] EQU ["true"] (
            echo --------------------------------------------------------------------------------
            echo Oracle Database 21c.
            echo --------------------------------------------------------------------------------
            set ORA_BENCH_BENCHMARK_DATABASE=db_21_3_ee
            set ORA_BENCH_CONNECTION_SERVICE=orclpdb1
        
            call scripts\run_db_setup.bat
            if %ERRORLEVEL% neq 0 (
                echo Processing of the script: %0 - step: 'call scripts\run_db_setup.bat' was aborted, error code=%ERRORLEVEL%
                exit -1073741510
            )
    
            set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
            set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=0
            set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0

            call scripts\run_all_drivers.bat
            if %ERRORLEVEL% neq 0 (
                echo Processing of the script: %0 - step: 'call scripts\run_all_drivers.bat' was aborted, error code=%ERRORLEVEL%
                exit -1073741510
            )
    
            set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
            set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
            set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0

            call scripts\run_all_drivers.bat
            if %ERRORLEVEL% neq 0 (
                echo Processing of the script: %0 - step: 'call scripts\run_all_drivers.bat' was aborted, error code=%ERRORLEVEL%
                exit -1073741510
            )
    
            set ORA_BENCH_BENCHMARK_BATCH_SIZE=512
            set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=0
            set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=512

            call scripts\run_all_drivers.bat
            if %ERRORLEVEL% neq 0 (
                echo Processing of the script: %0 - step: 'call scripts\run_all_drivers.bat' was aborted, error code=%ERRORLEVEL%
                exit -1073741510
            )
    
            set ORA_BENCH_BENCHMARK_BATCH_SIZE=512
            set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
            set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=512

            call scripts\run_all_drivers.bat
            if %ERRORLEVEL% neq 0 (
                echo Processing of the script: %0 - step: 'call scripts\run_all_drivers.bat' was aborted, error code=%ERRORLEVEL%
                exit -1073741510
            )
        )
    )
   
    start priv\audio\end_of_series.mp3
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'start priv\audio\end_of_series.mp3' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    echo --------------------------------------------------------------------------------
    echo:| TIME
    echo --------------------------------------------------------------------------------
    echo End   %0
    echo ================================================================================
)
