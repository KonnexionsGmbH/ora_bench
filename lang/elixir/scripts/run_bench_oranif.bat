@echo off

rem --------------------------------------------------------------------------------
rem
rem run_bench_oranif.bat: Oracle Benchmark based on Elixir.
rem
rem --------------------------------------------------------------------------------

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

if ["%ORA_BENCH_FILE_CONFIGURATION_NAME%"] EQU [""] (
    set ORA_BENCH_FILE_CONFIGURATION_NAME=priv\properties\ora_bench.properties
)

if ["%ORA_BENCH_VCVARSALL_PATH%"] EQU [""] (
    set ORA_BENCH_VCVARSALL_PATH="C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\"
)

call %ORA_BENCH_VCVARSALL_PATH%vcvarsall.bat x64

echo ===============================================================================
echo Start %0
echo -------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - oranif and Elixir.
echo -------------------------------------------------------------------------------
echo MULTIPLE_RUN               : %ORA_BENCH_MULTIPLE_RUN%
echo -------------------------------------------------------------------------------
echo BENCHMARK_DATABASE         : %ORA_BENCH_BENCHMARK_DATABASE%
echo CONNECTION_HOST            : %ORA_BENCH_CONNECTION_HOST%
echo CONNECTION_PORT            : %ORA_BENCH_CONNECTION_PORT%
echo CONNECTION_SERVICE         : %ORA_BENCH_CONNECTION_SERVICE%
echo -------------------------------------------------------------------------------
echo BENCHMARK_BATCH_SIZE       : %ORA_BENCH_BENCHMARK_BATCH_SIZE%
echo BENCHMARK_CORE_MULTIPLIER  : %ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%
echo BENCHMARK_TRANSACTION_SIZE : %ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%
echo -------------------------------------------------------------------------------
echo FILE_CONFIGURATION_NAME    : %ORA_BENCH_FILE_CONFIGURATION_NAME%
echo -------------------------------------------------------------------------------
echo:| TIME
echo ===============================================================================

if NOT ["%ORA_BENCH_MULTIPLE_RUN%"] == ["true"] (
    call lang\java\scripts\run_gradle
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call lang\java\scripts\run_gradle' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )
)

java -jar priv/libs/ora_bench_java.jar setup_elixir
if %ERRORLEVEL% neq 0 (
    echo Processing of the script: %0 - step: 'java -jar priv/libs/ora_bench_java.jar setup_elixir' was aborted, error code=%ERRORLEVEL%
    exit -1073741510
)

cd lang\elixir

if NOT ["%ORA_BENCH_MULTIPLE_RUN%"] == ["true"] (
    if EXIST deps\    rd /Q/S deps 
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'rd /Q/S deps' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    if EXIST mix.lock del /s mix.lock 
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'del /s mix.lock' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    call mix local.hex --force
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call mix local.hex --force' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    call mix local.rebar --force
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call mix local.rebar --force' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    call mix deps.clean --all
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call mix deps.clean --all' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    call mix deps.get
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call mix deps.get' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    call mix deps.compile
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call mix deps.compile' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )
)
    
call mix run -e "OraBench.CLI.main(["oranif"])"
if %ERRORLEVEL% neq 0 (
    echo Processing of the script: %0 - step: call mix run -e "OraBench.CLI.main(["oranif"])" was aborted, error code=%ERRORLEVEL%
    exit -1073741510
)

cd ..\..

endlocal

echo -------------------------------------------------------------------------------
echo:| TIME
echo -------------------------------------------------------------------------------
echo End   %0
echo ===============================================================================
