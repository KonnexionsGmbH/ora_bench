@echo off

rem --------------------------------------------------------------------------------
rem
rem run_finalise_benchmark.bat: Finalise Oracle benchmark run.
rem
rem --------------------------------------------------------------------------------

setlocal EnableDelayedExpansion

set ORA_BENCH_FILE_CONFIGURATION_NAME_DEFAULT=priv/properties/ora_bench.properties

if ["%ORA_BENCH_FILE_CONFIGURATION_NAME%"] EQU [""] (
    set ORA_BENCH_FILE_CONFIGURATION_NAME=%ORA_BENCH_FILE_CONFIGURATION_NAME_DEFAULT%
)

echo ===============================================================================
echo Start %0
echo -------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - finalise benchmark run.
echo -------------------------------------------------------------------------------
echo:| TIME
echo ===============================================================================

java -jar priv/libs/ora_bench_java.jar finalise
if %ERRORLEVEL% neq 0 (
    echo Processing of the script: %0 - step: 'java -jar priv/libs/ora_bench_java.jar finalise' was aborted, error code=%ERRORLEVEL%
    exit -1073741510
)

echo -------------------------------------------------------------------------------
echo:| TIME
echo -------------------------------------------------------------------------------
echo End   %0
echo ===============================================================================
