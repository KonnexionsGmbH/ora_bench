@echo off

rem ------------------------------------------------------------------------------
rem
rem run_bench_database_series.bat: Oracle benchmark for a specific database version.
rem
rem ------------------------------------------------------------------------------

set ORA_BENCH_MULTIPLE_RUN=true

if ["%ORA_BENCH_RUN_CX_ORACLE_PYTHON%"] EQU [""] (
    set ORA_BENCH_RUN_CX_ORACLE_PYTHON=true
)
if ["%ORA_BENCH_RUN_JAMDB_ORACLE_ELIXIR%"] EQU [""] (
    set ORA_BENCH_RUN_JAMDB_ORACLE_ELIXIR=true
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

set ORA_BENCH_CONNECT_IDENTIFIER=//%ORA_BENCH_CONNECTION_HOST%:%ORA_BENCH_CONNECTION_PORT%/%ORA_BENCH_CONNECTION_SERVICE%

echo ================================================================================
echo Start %0
echo --------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - specific database.
echo --------------------------------------------------------------------------------
echo BENCHMARK_DATABASE       %ORA_BENCH_BENCHMARK_DATABASE%
echo CONNECTION_HOST         : %ORA_BENCH_CONNECTION_HOST%
echo CONNECTION_PORT         : %ORA_BENCH_CONNECTION_PORT%
echo CONNECTION_SERVICE      : %ORA_BENCH_CONNECTION_SERVICE%
echo FILE_CONFIGURATION_NAME : %ORA_BENCH_FILE_CONFIGURATION_NAME%
echo --------------------------------------------------------------------------------
echo RUN_CX_ORACLE_PYTHON    : %ORA_BENCH_RUN_CX_ORACLE_PYTHON%
echo RUN_JAMDB_ORACLE_ELIXIR : %ORA_BENCH_RUN_JAMDB_ORACLE_ELIXIR%
echo RUN_JDBC_JAVA           : %ORA_BENCH_RUN_JDBC_JAVA%
echo RUN_ODPI_C              : %ORA_BENCH_RUN_ODPI_C%
echo RUN_ORANIF_ELIXIR       : %ORA_BENCH_RUN_ORANIF_ELIXIR%
echo RUN_ORANIF_ERLANG       : %ORA_BENCH_RUN_ORANIF_ERLANG%
echo --------------------------------------------------------------------------------
echo CONNECT_IDENTIFIER      : %ORA_BENCH_CONNECT_IDENTIFIER%
echo --------------------------------------------------------------------------------
echo:| TIME
echo ================================================================================

if ["%ORA_BENCH_RUN_ODPI_C%"] == ["true"] (
    echo Setup C - Start ============================================================ 
    nmake -f src_c\Makefile.win32 clean
    nmake -f src_c\Makefile.win32
    echo Setup C - End   ============================================================ 
)

if ["%ORA_BENCH_RUN_JAMDB_ORACLE_ELIXIR%"] == ["true"] (
    echo Setup Elixir - Start ======================================================= 
    cd src_elixir
    call mix deps.get
    call mix deps.compile
    cd ..
    echo Setup Elixir - End   ======================================================= 
)

if ["%ORA_BENCH_RUN_ORANIF_ELIXIR%"] == ["true"] (
    echo Setup Elixir - Start ======================================================= 
    cd src_elixir
    call mix deps.get
    call mix deps.compile
    cd ..
    echo Setup Elixir - End   ======================================================= 
)

if ["%ORA_BENCH_RUN_ORANIF_ERLANG%"] == ["true"] (
    echo Setup Erlang - Start ======================================================= 
    cd src_erlang
    call rebar3 escriptize
    cd ..
    echo Setup Erlang - End   ======================================================= 
)    

priv\Gammadyne\timer.exe
echo Docker stop/rm ora_bench_db
docker stop ora_bench_db
docker rm -f ora_bench_db
echo Docker create ora_bench_db(%ORA_BENCH_BENCHMARK_DATABASE%)
docker create -e ORACLE_PWD=oracle --name ora_bench_db -p 1521:1521/tcp --shm-size 1G konnexionsgmbh/%ORA_BENCH_BENCHMARK_DATABASE%
echo Docker started ora_bench_db(%ORA_BENCH_BENCHMARK_DATABASE%)...
docker start ora_bench_db
for /f "delims=" %%A in ('priv\Gammadyne\timer.exe /s') do set "CONSUMED=%%A"
echo DOCKER ready in %CONSUMED%

:check_health_status:
mkdir tmp >nul 2>&1
docker inspect -f {{.State.Health.Status}} ora_bench_db > tmp\docker_health_status.txt
set /P DOCKER_HEALTH_STATUS=<tmp\docker_health_status.txt
if NOT ["%DOCKER_HEALTH_STATUS%"] == ["healthy"] (
    docker ps --filter "name=ora_bench_db"
    ping -n 60 127.0.0.1 >nul
    goto :check_health_status
)

priv\oracle\instantclient-windows.x64\instantclient_19_5\sqlplus.exe sys/%ORA_BENCH_PASSWORD_SYS%@%ORA_BENCH_CONNECT_IDENTIFIER% AS SYSDBA @scripts/run_bench_database.sql
if %ERRORLEVEL% NEQ 0 (
    GOTO EndOfScript
)

rem #01
set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
call scripts\run_bench_all_drivers.bat
if %ERRORLEVEL% NEQ 0 (
    GOTO EndOfScript
)

rem #02
set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
call scripts\run_bench_all_drivers.bat
if %ERRORLEVEL% NEQ 0 (
    GOTO EndOfScript
)

rem #03
set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
call scripts\run_bench_all_drivers.bat
if %ERRORLEVEL% NEQ 0 (
    GOTO EndOfScript
)

rem #04
set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
call scripts\run_bench_all_drivers.bat
if %ERRORLEVEL% NEQ 0 (
    GOTO EndOfScript
)

rem #05
set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
call scripts\run_bench_all_drivers.bat
if %ERRORLEVEL% NEQ 0 (
    GOTO EndOfScript
)

rem #06
set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
call scripts\run_bench_all_drivers.bat
if %ERRORLEVEL% NEQ 0 (
    GOTO EndOfScript
)

rem #07
set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
call scripts\run_bench_all_drivers.bat
if %ERRORLEVEL% NEQ 0 (
    GOTO EndOfScript
)

rem #08
set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
call scripts\run_bench_all_drivers.bat
if %ERRORLEVEL% NEQ 0 (
    GOTO EndOfScript
)

:EndOfScript
echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================

exit /B %ERRORLEVEL%
