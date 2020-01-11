@echo off

rem ------------------------------------------------------------------------------
rem
rem run_bench_database_series.bat: Oracle benchmark for a specific database version.
rem
rem ------------------------------------------------------------------------------

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
if ["%ORA_BENCH_RUN_JAMDB_ERLANG%"] EQU [""] (
    set ORA_BENCH_RUN_JAMDB_ERLANG=true
)

set ORA_BENCH_CONNECT_IDENTIFIER=//%ORA_BENCH_CONNECTION_HOST%:%ORA_BENCH_CONNECTION_PORT%/%ORA_BENCH_CONNECTION_SERVICE%

echo ================================================================================
echo Start %0
echo --------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - specific database.
echo --------------------------------------------------------------------------------
echo BENCHMARK_DATABASE      : %ORA_BENCH_BENCHMARK_DATABASE%
echo CONNECTION_SERVICE      : %ORA_BENCH_CONNECTION_SERVICE%
echo --------------------------------------------------------------------------------
echo RUN_CX_ORACLE_PYTHON    : %ORA_BENCH_RUN_CX_ORACLE_PYTHON%
echo RUN_JAMDB_ORACLE_ELIXIR : %ORA_BENCH_RUN_JAMDB_ORACLE_ELIXIR%
echo RUN_JDBC_JAVA           : %ORA_BENCH_RUN_JDBC_JAVA%
echo RUN_ODPI_C              : %ORA_BENCH_RUN_ODPI_C%
echo RUN_ORANIF_ELIXIR       : %ORA_BENCH_RUN_ORANIF_ELIXIR%
echo RUN_ORANIF_ERLANG       : %ORA_BENCH_RUN_ORANIF_ERLANG%
echo RUN_JAMDB_ERLANG        : %ORA_BENCH_RUN_JAMDB_ERLANG%
echo --------------------------------------------------------------------------------
echo CONNECT_IDENTIFIER      : %ORA_BENCH_CONNECT_IDENTIFIER%
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
if %ERRORLEVEL% NEQ 0 (
    GOTO EndOfScript
)

if ["%ORA_BENCH_RUN_CX_ORACLE_PYTHON%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    call src_python\scripts\run_bench_cx_oracle.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)
if ["%ORA_BENCH_RUN_CX_ORACLE_PYTHON%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    call src_python\scripts\run_bench_cx_oracle.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)

if ["%ORA_BENCH_RUN_JAMDB_ORACLE_ELIXIR%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    call src_elixir\scripts\run_bench_jamdb_oracle.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)
if ["%ORA_BENCH_RUN_JAMDB_ORACLE_ELIXIR%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    call src_elixir\scripts\run_bench_jamdb_oracle.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)

if ["%ORA_BENCH_RUN_JDBC_JAVA%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    call src_java\scripts\run_bench_jdbc.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)
if ["%ORA_BENCH_RUN_JDBC_JAVA%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    call src_java\scripts\run_bench_jdbc.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)

if ["%ORA_BENCH_RUN_ODPI_C%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    call src_c\scripts\run_bench_odpi.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)
if ["%ORA_BENCH_RUN_ODPI_C%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    call src_c\scripts\run_bench_odpi.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)

if ["%ORA_BENCH_RUN_ORANIF_ELIXIR%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    call src_elixir\scripts\run_bench_oranif.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)
if ["%ORA_BENCH_RUN_ORANIF_ELIXIR%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    call src_elixir\scripts\run_bench_oranif.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)

if ["%ORA_BENCH_RUN_ORANIF_ERLANG%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    call src_erlang\scripts\run_bench_oranif.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)
if ["%ORA_BENCH_RUN_ORANIF_ERLANG%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    call src_erlang\scripts\run_bench_oranif.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)

if ["%ORA_BENCH_RUN_ORANIF_JAMDB%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    call src_erlang\scripts\run_bench_jamdb.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)
if ["%ORA_BENCH_RUN_ORANIF_JAMDB%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    call src_erlang\scripts\run_bench_jamdb.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)

if ["%ORA_BENCH_RUN_CX_ORACLE_PYTHON%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    call src_python\scripts\run_bench_cx_oracle.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)
if ["%ORA_BENCH_RUN_CX_ORACLE_PYTHON%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    call src_python\scripts\run_bench_cx_oracle.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)

if ["%ORA_BENCH_RUN_JAMDB_ORACLE_ELIXIR%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    call src_elixir\scripts\run_bench_jamdb_oracle.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)
if ["%ORA_BENCH_RUN_JAMDB_ORACLE_ELIXIR%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    call src_elixir\scripts\run_bench_jamdb_oracle.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)

if ["%ORA_BENCH_RUN_JDBC_JAVA%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER==%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    call src_java\scripts\run_bench_jdbc.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)
if ["%ORA_BENCH_RUN_JDBC_JAVA%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    call src_java\scripts\run_bench_jdbc.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)

if ["%ORA_BENCH_RUN_ODPI_C%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER==%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    call src_c\scripts\run_bench_odpi.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)
if ["%ORA_BENCH_RUN_ODPI_C%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    call src_c\scripts\run_bench_odpi.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)

if ["%ORA_BENCH_RUN_ORANIF_ELIXIR%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    call src_elixir\scripts\run_bench_oranif.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)
if ["%ORA_BENCH_RUN_ORANIF_ELIXIR%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    call src_elixir\scripts\run_bench_oranif.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)

if ["%ORA_BENCH_RUN_ORANIF_ERLANG%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    call src_erlang\scripts\run_bench_oranif.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)
if ["%ORA_BENCH_RUN_ORANIF_ERLANG%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    call src_erlang\scripts\run_bench_oranif.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)

if ["%ORA_BENCH_RUN_JAMDB_ERLANG%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    call src_erlang\scripts\run_bench_jamdb.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)
if ["%ORA_BENCH_RUN_JAMDB_ERLANG%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    call src_erlang\scripts\run_bench_jamdb.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)

if ["%ORA_BENCH_RUN_CX_ORACLE_PYTHON%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    call src_python\scripts\run_bench_cx_oracle.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)
if ["%ORA_BENCH_RUN_CX_ORACLE_PYTHON%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    call src_python\scripts\run_bench_cx_oracle.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)

if ["%ORA_BENCH_RUN_JAMDB_ORACLE_ELIXIR%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    call src_elixir\scripts\run_bench_jamdb_oracle.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)
if ["%ORA_BENCH_RUN_JAMDB_ORACLE_ELIXIR%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    call src_elixir\scripts\run_bench_jamdb_oracle.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)

if ["%ORA_BENCH_RUN_JDBC_JAVA%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    call src_java\scripts\run_bench_jdbc.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)
if ["%ORA_BENCH_RUN_JDBC_JAVA%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    call src_java\scripts\run_bench_jdbc.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)

if ["%ORA_BENCH_RUN_ODPI_C%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    call src_c\scripts\run_bench_odpi.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)
if ["%ORA_BENCH_RUN_ODPI_C%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    call src_c\scripts\run_bench_odpi.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)

if ["%ORA_BENCH_RUN_ORANIF_ELIXIR%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    call src_elixir\scripts\run_bench_oranif.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)
if ["%ORA_BENCH_RUN_ORANIF_ELIXIR%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    call src_elixir\scripts\run_bench_oranif.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)

if ["%ORA_BENCH_RUN_ORANIF_ERLANG%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    call src_erlang\scripts\run_bench_oranif.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)
if ["%ORA_BENCH_RUN_ORANIF_ERLANG%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    call src_erlang\scripts\run_bench_oranif.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)

if ["%ORA_BENCH_RUN_JAMDB_ERLANG%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    call src_erlang\scripts\run_bench_jamdb.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)
if ["%ORA_BENCH_RUN_JAMDB_ERLANG%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    call src_erlang\scripts\run_bench_jamdb.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)

if ["%ORA_BENCH_RUN_CX_ORACLE_PYTHON%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    call src_python\scripts\run_bench_cx_oracle.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)
if ["%ORA_BENCH_RUN_CX_ORACLE_PYTHON%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    call src_python\scripts\run_bench_cx_oracle.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)

if ["%ORA_BENCH_RUN_JAMDB_ORACLE_ELIXIR%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    call src_elixir\scripts\run_bench_jamdb_oracle.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)
if ["%ORA_BENCH_RUN_JAMDB_ORACLE_ELIXIR%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    call src_elixir\scripts\run_bench_jamdb_oracle.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)

if ["%ORA_BENCH_RUN_JDBC_JAVA%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    call src_java\scripts\run_bench_jdbc.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)
if ["%ORA_BENCH_RUN_JDBC_JAVA%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    call src_java\scripts\run_bench_jdbc.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)

if ["%ORA_BENCH_RUN_ODPI_C%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    call src_c\scripts\run_bench_odpi.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)
if ["%ORA_BENCH_RUN_ODPI_C%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    call src_c\scripts\run_bench_odpi.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)

if ["%ORA_BENCH_RUN_ORANIF_ELIXIR%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    call src_elixir\scripts\run_bench_oranif.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)
if ["%ORA_BENCH_RUN_ORANIF_ELIXIR%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    call src_elixir\scripts\run_bench_oranif.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)

if ["%ORA_BENCH_RUN_ORANIF_ERLANG%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    call src_erlang\scripts\run_bench_oranif.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)
if ["%ORA_BENCH_RUN_ORANIF_ERLANG%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    call src_erlang\scripts\run_bench_oranif.bat
)

if ["%ORA_BENCH_RUN_JAMDB_ERLANG%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    call src_erlang\scripts\run_bench_jamdb.bat
    if %ERRORLEVEL% NEQ 0 (
        GOTO EndOfScript
    )
)
if ["%ORA_BENCH_RUN_JAMDB_ERLANG%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    call src_erlang\scripts\run_bench_jamdb.bat
)

:EndOfScript
echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================

exit /B %ERRORLEVEL%
