@echo off

rem ------------------------------------------------------------------------------
rem
rem run_create_bulk_file.bat: Oracle Benchmark Run Setup.
rem
rem ------------------------------------------------------------------------------

setlocal EnableDelayedExpansion

if ["%ORA_BENCH_FILE_CONFIGURATION_NAME%"] EQU [""] (
    set ORA_BENCH_FILE_CONFIGURATION_NAME=priv\properties\ora_bench.properties
)

echo ================================================================================
echo Start %0
echo --------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - setup benchmark run.
echo --------------------------------------------------------------------------------
echo CHOICE_DRIVER                     : %ORA_BENCH_CHOICE_DRIVER%
echo --------------------------------------------------------------------------------
echo FILE_CONFIGURATION_NAME           : %ORA_BENCH_FILE_CONFIGURATION_NAME%
echo --------------------------------------------------------------------------------
echo:| TIME
echo ================================================================================

if ["%ORA_BENCH_CHOICE_DRIVER%"] EQU ["complete"] (
    call scripts\run_show_environment.bat
    if %ERRORLEVEL% NEQ 0 (
        echo Processing of the script was aborted, error code=%ERRORLEVEL%
        exit %ERRORLEVEL%
    )
)

call src_java\scripts\run_gradle
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)

java -jar priv/libs/ora_bench_java.jar setup
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)

echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================
