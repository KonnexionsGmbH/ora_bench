@echo off

rem ------------------------------------------------------------------------------
rem
rem run_bench_database_series.bat: Oracle benchmark for a speci)c database version.
rem
rem ------------------------------------------------------------------------------

if ["%ORA_BENCH_RUN_CX_ORACLE_PYTHON%"] EQU [""] (
    set ORA_BENCH_RUN_CX_ORACLE_PYTHON=true
)
if ["%ORA_BENCH_RUN_JDBC_JAVA%"] EQU [""] (
    set ORA_BENCH_RUN_JDBC_JAVA=true
)
if ["%ORA_BENCH_RUN_ORANIF_ERLANG%"] EQU [""] (
    set ORA_BENCH_RUN_ORANIF_ERLANG=true
)

set ORA_BENCH_CONNECT_IDENTIFIER=//%ORA_BENCH_CONNECTION_HOST%:%ORA_BENCH_CONNECTION_PORT%/%ORA_BENCH_CONNECTION_SERVICE%

echo ================================================================================
echo Start %0
echo --------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - speci)c database.
echo --------------------------------------------------------------------------------
echo BENCHMARK_DATABASE   : %ORA_BENCH_BENCHMARK_DATABASE%
echo CONNECTION_SERVICE   : %ORA_BENCH_CONNECTION_SERVICE%
echo --------------------------------------------------------------------------------
echo RUN_CX_ORACLE_PYTHON : %ORA_BENCH_RUN_CX_ORACLE_PYTHON%
echo RUN_JDBC_JAVA        : %ORA_BENCH_RUN_JDBC_JAVA%
echo RUN_ORANIF_ERLANG    : %ORA_BENCH_RUN_ORANIF_ERLANG%
echo --------------------------------------------------------------------------------
echo CONNECT_IDENTIFIER   : %ORA_BENCH_CONNECT_IDENTIFIER%
echo --------------------------------------------------------------------------------
echo:| TIME
echo ================================================================================

docker stop ora_bench_db
docker rm -f ora_bench_db
docker create -e ORACLE_PWD=oracle --name ora_bench_db -p 1521:1521/tcp --shm-size 1G konnexionsgmbh/%ORA_BENCH_BENCHMARK_DATABASE%
docker start ora_bench_db
while [ "`docker inspect -f {{.State.Health.Status}} ora_bench_db`" != "healthy" ]; do docker ps --)lter "name=ora_bench_db"; sleep 60; done

priv/oracle/instantclient-linux.x64/instantclient_19_5/sqlplus sys/$ORA_BENCH_PASSWORD_SYS@%ORA_BENCH_CONNECT_IDENTIFIER% AS SYSDBA @scripts/run_bench_database.sql

if ["%ORA_BENCH_RUN_CX_ORACLE_PYTHON%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    { /bin/bash scripts/run_bench_cx_oracle_python.sh; }
)
if ["%ORA_BENCH_RUN_CX_ORACLE_PYTHON%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    { /bin/bash scripts/run_bench_cx_oracle_python.sh; }
)

if ["%ORA_BENCH_RUN_JDBC_JAVA%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    { /bin/bash scripts/run_bench_jdbc_java.sh; }
)
if ["%ORA_BENCH_RUN_JDBC_JAVA%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    { /bin/bash scripts/run_bench_jdbc_java.sh; }
)

if ["%ORA_BENCH_RUN_ORANIF_ERLANG%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    { /bin/bash scripts/run_bench_oranif_erlang.sh; }
)
if ["%ORA_BENCH_RUN_ORANIF_ERLANG%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    { /bin/bash scripts/run_bench_oranif_erlang.sh; }
)

if ["%ORA_BENCH_RUN_CX_ORACLE_PYTHON%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    { /bin/bash scripts/run_bench_cx_oracle_python.sh; }
)
if ["%ORA_BENCH_RUN_CX_ORACLE_PYTHON%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    { /bin/bash scripts/run_bench_cx_oracle_python.sh; }
)

if ["%ORA_BENCH_RUN_JDBC_JAVA%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER==%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    { /bin/bash scripts/run_bench_jdbc_java.sh; }
)
if ["%ORA_BENCH_RUN_JDBC_JAVA%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    { /bin/bash scripts/run_bench_jdbc_java.sh; }
)

if ["%ORA_BENCH_RUN_ORANIF_ERLANG%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    { /bin/bash scripts/run_bench_oranif_erlang.sh; }
)
if ["%ORA_BENCH_RUN_ORANIF_ERLANG%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=%ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%_DEFAULT
    { /bin/bash scripts/run_bench_oranif_erlang.sh; }
)

if ["%ORA_BENCH_RUN_CX_ORACLE_PYTHON%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    { /bin/bash scripts/run_bench_cx_oracle_python.sh; }
)
if ["%ORA_BENCH_RUN_CX_ORACLE_PYTHON%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
   { /bin/bash scripts/run_bench_cx_oracle_python.sh; }
)

if ["%ORA_BENCH_RUN_JDBC_JAVA%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    { /bin/bash scripts/run_bench_jdbc_java.sh; }
)
if ["%ORA_BENCH_RUN_JDBC_JAVA%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    { /bin/bash scripts/run_bench_jdbc_java.sh; }
)

if ["%ORA_BENCH_RUN_ORANIF_ERLANG%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    { /bin/bash scripts/run_bench_oranif_erlang.sh; }
)
if ["%ORA_BENCH_RUN_ORANIF_ERLANG%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=%ORA_BENCH_BENCHMARK_BATCH_SIZE%_DEFAULT
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    { /bin/bash scripts/run_bench_oranif_erlang.sh; }
)

if ["%ORA_BENCH_RUN_CX_ORACLE_PYTHON%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    { /bin/bash scripts/run_bench_cx_oracle_python.sh; }
)
if ["%ORA_BENCH_RUN_CX_ORACLE_PYTHON%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    { /bin/bash scripts/run_bench_cx_oracle_python.sh; }
)

if ["%ORA_BENCH_RUN_JDBC_JAVA%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    { /bin/bash scripts/run_bench_jdbc_java.sh; }
)
if ["%ORA_BENCH_RUN_JDBC_JAVA%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    { /bin/bash scripts/run_bench_jdbc_java.sh; }
)

if ["%ORA_BENCH_RUN_ORANIF_ERLANG%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=%ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%_DEFAULT
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    { /bin/bash scripts/run_bench_oranif_erlang.sh; }
)
if ["%ORA_BENCH_RUN_ORANIF_ERLANG%" = "true"] EQU [""] (
    set ORA_BENCH_BENCHMARK_BATCH_SIZE=0
    set ORA_BENCH_BENCHMARK_CORE_MULTIPLIER=1
    set ORA_BENCH_BENCHMARK_TRANSACTION_SIZE=0
    { /bin/bash scripts/run_bench_oranif_erlang.sh; }
)

echo
echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================

exit /B %ERRORLEVEL%
