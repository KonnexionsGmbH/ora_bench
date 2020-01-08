@echo off

rem ------------------------------------------------------------------------------
rem
rem run_bench_database.bat: Oracle benchmark for a specific database version.
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
if ["%ORA_BENCH_PASSWORD_SYS%"] EQU [""] (
    set ORA_BENCH_PASSWORD_SYS=oracle
)

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
echo BENCHMARK_DATABASE         : %ORA_BENCH_BENCHMARK_DATABASE%
echo CONNECTION_HOST            : %ORA_BENCH_CONNECTION_HOST%
echo CONNECTION_PORT            : %ORA_BENCH_CONNECTION_PORT%
echo CONNECTION_SERVICE         : %ORA_BENCH_CONNECTION_SERVICE%
echo FILE_CONFIGURATION_NAME    : %ORA_BENCH_FILE_CONFIGURATION_NAME%
echo --------------------------------------------------------------------------------
echo BENCHMARK_BATCH_SIZE       : %ORA_BENCH_BENCHMARK_BATCH_SIZE%
echo BENCHMARK_CORE_MULTIPLIER  : %ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%
echo BENCHMARK_TRANSACTION_SIZE : %ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%
echo --------------------------------------------------------------------------------
echo RUN_CX_ORACLE_PYTHON       : %ORA_BENCH_RUN_CX_ORACLE_PYTHON%
echo RUN_JAMDB_ORACLE_ELIXIR    : %ORA_BENCH_RUN_JAMDB_ORACLE_ELIXIR%
echo RUN_JDBC_JAVA              : %ORA_BENCH_RUN_JDBC_JAVA%
echo RUN_ODPI_C                 : %ORA_BENCH_RUN_ODPI_C%
echo RUN_ORANIF_ELIXIR          : %ORA_BENCH_RUN_ORANIF_ELIXIR%
echo RUN_ORANIF_ERLANG          : %ORA_BENCH_RUN_ORANIF_ERLANG%
echo --------------------------------------------------------------------------------
echo CONNECT_IDENTIFIER         : %ORA_BENCH_CONNECT_IDENTIFIER%
echo --------------------------------------------------------------------------------
echo:| TIME
echo ================================================================================

docker stop ora_bench_db
docker rm -f ora_bench_db
docker create -e ORACLE_PWD=oracle --name ora_bench_db -p 1521:1521/tcp --shm-size 1G konnexionsgmbh/%ORA_BENCH_BENCHMARK_DATABASE%
docker start ora_bench_db

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

if ["%ORA_BENCH_RUN_CX_ORACLE_PYTHON%"] EQU ["true"] (
    call scripts\run_bench_cx_oracle_python.bat
)

if ["%ORA_BENCH_RUN_JAMDB_ORACLE_ELIXIR%"] EQU ["true"] (
    call scripts\run_bench_jamdb_oracle_elixir.bat
)

if ["%ORA_BENCH_RUN_JDBC_JAVA%"] EQU ["true"] (
    call scripts\run_bench_jdbc_java.bat
)

if ["%ORA_BENCH_RUN_ODPI_C%"] EQU ["true"] (
    call scripts\run_bench_odpi_c.bat
)

if ["%ORA_BENCH_RUN_ORANIF_ELIXIR%"] EQU ["true"] (
    call scripts\run_bench_oranif_elixir.bat
)

if ["%ORA_BENCH_RUN_ORANIF_ERLANG%"] EQU ["true"] (
    call scripts\run_bench_oranif_erlang.bat
)

echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================

exit /B %ERRORLEVEL%
