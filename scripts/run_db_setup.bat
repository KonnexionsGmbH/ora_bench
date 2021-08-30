@echo off

rem ------------------------------------------------------------------------------
rem
rem run_db_setup.bat: Database setup.
rem
rem ------------------------------------------------------------------------------

setlocal EnableDelayedExpansion

if ["%ORA_BENCH_BENCHMARK_DATABASE%"] EQU [""] (
    set ORA_BENCH_BENCHMARK_DATABASE=db_21_3_ee
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
if ["%ORA_BENCH_PASSWORD_SYS%"] EQU [""] (
    set ORA_BENCH_PASSWORD_SYS=oracle
)

echo ================================================================================
echo Start %0
echo --------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - database setup.
echo --------------------------------------------------------------------------------
echo BENCHMARK_DATABASE                : %ORA_BENCH_BENCHMARK_DATABASE%
echo CONNECTION_HOST                   : %ORA_BENCH_CONNECTION_HOST%
echo CONNECTION_PORT                   : %ORA_BENCH_CONNECTION_PORT%
echo CONNECTION_SERVICE                : %ORA_BENCH_CONNECTION_SERVICE%
echo --------------------------------------------------------------------------------
echo:| TIME
echo ================================================================================

priv\Gammadyne\timer.exe
echo Docker stop/rm ora_bench_db ....................................................
docker ps    | findstr "ora_bench_db" && docker stop ora_bench_db
docker ps -a | findstr "ora_bench_db" && docker rm ora_bench_db

echo Docker setup network ...........................................................
docker network prune --force
mkdir tmp >nul 2>&1
docker network ls | findstr "ora_bench_net" > tmp\_ora_bench_net
set /p _ora_bench_net=<tmp\_ora_bench_net
if [%_ora_bench_net%] NEQ ["ora_bench_net"] (docker network create ora_bench_net)
docker network ls

echo Docker create ora_bench_db(%ORA_BENCH_BENCHMARK_DATABASE%) .....................
docker create -e        ORACLE_PWD=oracle ^
              --name    ora_bench_db ^
              --network ora_bench_net ^
              -p        1521:1521/tcp ^
              konnexionsgmbh/%ORA_BENCH_BENCHMARK_DATABASE%

echo Docker started ora_bench_db(%ORA_BENCH_BENCHMARK_DATABASE%) ....................
docker start ora_bench_db
if %ERRORLEVEL% neq 0 (
    echo Processing of the script: %0 - step: 'docker start ora_bench_db' was aborted, error code=%ERRORLEVEL%
    exit -1073741510
)
for /f "delims=" %%A in ('priv\Gammadyne\timer.exe /s') do set "CONSUMED=%%A"
echo DOCKER ready in %CONSUMED% .....................................................

:check_health_status:
mkdir tmp >nul 2>&1
docker inspect -f {{.State.Health.Status}} ora_bench_db > tmp\docker_health_status.txt
set /P DOCKER_HEALTH_STATUS=<tmp\docker_health_status.txt
if NOT ["%DOCKER_HEALTH_STATUS%"] == ["healthy"] (
    docker ps --filter "name=ora_bench_db"
    ping -n 60 127.0.0.1 >nul
    goto :check_health_status
)
if %ERRORLEVEL% neq 0 (
    echo Processing of the script: %0 - step: 'docker inspect -f {{.State.Health.Status}} ora_bench_db > tmp\docker_health_status.txt' was aborted, error code=%ERRORLEVEL%
    exit -1073741510
)

sqlplus.exe sys/%ORA_BENCH_PASSWORD_SYS%@//%ORA_BENCH_CONNECTION_HOST%:%ORA_BENCH_CONNECTION_PORT%/%ORA_BENCH_CONNECTION_SERVICE% AS SYSDBA @scripts/run_db_setup.sql
if %ERRORLEVEL% neq 0 (
    echo Processing of the script: %0 - step: 'sqlplus.exe sys/%ORA_BENCH_PASSWORD_SYS%@//%ORA_BENCH_CONNECTION_HOST%:%ORA_BENCH_CONNECTION_PORT%/%ORA_BENCH_CONNECTION_SERVICE% AS SYSDBA @scripts/run_db_setup.sql' was aborted, error code=%ERRORLEVEL%
    exit -1073741510
)

echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================
