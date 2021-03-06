@echo off

rem ------------------------------------------------------------------------------
rem
rem run_properties_standard.bat: Run with standard properties.
rem
rem ------------------------------------------------------------------------------

setlocal EnableDelayedExpansion

if ["%ORA_BENCH_CHOICE_DRIVER%"] EQU [""] (
    set ORA_BENCH_CHOICE_DRIVER=complete
)
if ["%ORA_BENCH_CHOICE_DB%"] EQU [""] (
    set ORA_BENCH_CHOICE_DB=complete
)

set ORA_BENCH_RUN_CX_ORACLE_PYTHON=false
set ORA_BENCH_RUN_GODROR_GO=false
set ORA_BENCH_RUN_JDBC_JAVA=false
set ORA_BENCH_RUN_JDBC_KOTLIN=false
set ORA_BENCH_RUN_ODPI_C=false
set ORA_BENCH_RUN_ORANIF_ELIXIR=false
set ORA_BENCH_RUN_ORANIF_ERLANG=false

if ["%ORA_BENCH_CHOICE_DRIVER%"] EQU ["complete"] (
    set ORA_BENCH_RUN_CX_ORACLE_PYTHON=true
    set ORA_BENCH_RUN_GODROR_GO=true
    set ORA_BENCH_RUN_JDBC_JAVA=true
    set ORA_BENCH_RUN_JDBC_KOTLIN=true
    set ORA_BENCH_RUN_ODPI_C=false
    set ORA_BENCH_RUN_ORANIF_ELIXIR=true
    set ORA_BENCH_RUN_ORANIF_ERLANG=true
)

if ["%ORA_BENCH_CHOICE_DRIVER%"] EQU ["c"] (
    set ORA_BENCH_RUN_ODPI_C=true
)

if ["%ORA_BENCH_CHOICE_DRIVER%"] EQU ["elixir"] (
    set ORA_BENCH_RUN_ORANIF_ELIXIR=true
)

if ["%ORA_BENCH_CHOICE_DRIVER%"] EQU ["erlang"] (
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

if ["%ORA_BENCH_CHOICE_DB%"] EQU ["18"] (
    set ORA_BENCH_BENCHMARK_DATABASE=db_18_4_xe
)
if ["%ORA_BENCH_CHOICE_DB%"] EQU ["19"] (
    set ORA_BENCH_BENCHMARK_DATABASE=db_19_3_ee
)

if ["%ORA_BENCH_CONNECTION_HOST%"] EQU [""] (
    set javaORA_BENCH_CONNECTION_HOST=localhost
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

echo ================================================================================
echo Start %0
echo --------------------------------------------------------------------------------
echo MULTIPLE_RUN                      : %ORA_BENCH_MULTIPLE_RUN%
echo --------------------------------------------------------------------------------
echo CHOICE_DRIVER                     : %ORA_BENCH_CHOICE_DRIVER%
echo BENCHMARK_DATABASE                : %ORA_BENCH_BENCHMARK_DATABASE%
echo --------------------------------------------------------------------------------
echo RUN_CX_ORACLE_PYTHON              : %ORA_BENCH_RUN_CX_ORACLE_PYTHON%
echo RUN_GODROR_GO                     : %ORA_BENCH_RUN_GODROR_GO%
echo RUN_JDBC_JAVA                     : %ORA_BENCH_RUN_JDBC_JAVA%
echo RUN_JDBC_KOTLIN                   : %ORA_BENCH_RUN_JDBC_KOTLIN%
echo RUN_ODPI_C                        : %ORA_BENCH_RUN_ODPI_C%
echo RUN_ORANIF_ELIXIR                 : %ORA_BENCH_RUN_ORANIF_ELIXIR%
echo RUN_ORANIF_ERLANG                 : %ORA_BENCH_RUN_ORANIF_ERLANG%
echo --------------------------------------------------------------------------------
echo RUN_DB_18_4_XE                    : %ORA_BENCH_RUN_DB_18_4_XE%
echo RUN_DB_19_3_EE                    : %ORA_BENCH_RUN_DB_19_3_EE%
echo --------------------------------------------------------------------------------
echo BENCHMARK_BATCH_SIZE              : %ORA_BENCH_BENCHMARK_BATCH_SIZE%
echo BENCHMARK_COMMENT                 : %ORA_BENCH_BENCHMARK_COMMENT%
echo BULKFILE_EXISTING                 : %ORA_BENCH_BULKFILE_EXISTING%
echo BENCHMARK_TRANSACTION_SIZE        : %ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%
echo CONNECTION_HOST                   : %ORA_BENCH_CONNECTION_HOST%
echo CONNECTION_PORT                   : %ORA_BENCH_CONNECTION_PORT%
echo FILE_CONFIGURATION_NAME           : %ORA_BENCH_FILE_CONFIGURATION_NAME%
echo --------------------------------------------------------------------------------
echo:| TIME
echo ================================================================================

call scripts\run_collect_and_compile.bat
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script: %0 - step: 'call scripts\run_collect_and_compile.bat' was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)

call scripts\run_db_setup.bat
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script: %0 - step: 'call scripts\run_db_setup.bat' was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)

call scripts\run_bench_all_drivers.bat
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script: %0 - step: 'call scripts\run_bench_all_drivers.bat' was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)

echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================
