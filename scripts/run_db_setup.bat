@echo off

rem ------------------------------------------------------------------------------
rem
rem run_db_setup.bat: Database setup.
rem
rem ------------------------------------------------------------------------------

setlocal EnableDelayedExpansion

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
if ["%ORA_BENCH_PASSWORD_SYS%"] EQU [""] (
    set ORA_BENCH_PASSWORD_SYS=oracle
)

echo ================================================================================
echo Start %0
echo --------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - database setup.
echo --------------------------------------------------------------------------------
echo BENCHMARK_DATABASE         : %ORA_BENCH_BENCHMARK_DATABASE%
echo CONNECTION_HOST            : %ORA_BENCH_CONNECTION_HOST%
echo CONNECTION_PORT            : %ORA_BENCH_CONNECTION_PORT%
echo CONNECTION_SERVICE         : %ORA_BENCH_CONNECTION_SERVICE%
echo --------------------------------------------------------------------------------
echo:| TIME
echo ================================================================================

priv\Gammadyne\timer.exe
echo Docker stop/rm ora_bench_db ....................................................
docker ps    | grep "ora_bench_db" && docker stop ora_bench_db
docker ps -a | grep "ora_bench_db" && docker rm ora_bench_db

echo Docker setup network ...........................................................
docker network prune --force
docker network ls | grep "ora_bench_net" > tmp\_ora_bench_net
set /p _ora_bench_net=<tmp\_ora_bench_net
if [%_ora_bench_net%] EQU [""] (docker network create ora_bench_net)
docker network ls

echo Docker create ora_bench_db(%ORA_BENCH_BENCHMARK_DATABASE%) .....................
docker create -e         ORACLE_PWD=oracle ^
              --name     ora_bench_db ^
              --network  ora_bench_net ^
              -p         1521:1521/tcp ^
              --shm-size 1G ^
              konnexionsgmbh/%ORA_BENCH_BENCHMARK_DATABASE%

echo Docker started ora_bench_db(%ORA_BENCH_BENCHMARK_DATABASE%) ....................
docker start ora_bench_db
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
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
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)

sqlplus.exe sys/%ORA_BENCH_PASSWORD_SYS%@//%ORA_BENCH_CONNECTION_HOST%:%ORA_BENCH_CONNECTION_PORT%/%ORA_BENCH_CONNECTION_SERVICE% AS SYSDBA @scripts/run_db_setup.sql
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)

echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================
