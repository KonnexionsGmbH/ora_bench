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

if ["%ORA_BENCH_JAVA_CLASSPATH%"] EQU [""] (
    set ORA_BENCH_JAVA_CLASSPATH=".;priv\java_jar\*"
    set PATH="%PATH%;\u01\app\oracle\product\12.2\db_1\jdbc\lib"
)

echo ================================================================================
echo Start %0
echo --------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - setup benchmark run.
echo --------------------------------------------------------------------------------
echo MULTIPLE_RUN               : %ORA_BENCH_MULTIPLE_RUN%
echo --------------------------------------------------------------------------------
echo FILE_CONFIGURATION_NAME    : %ORA_BENCH_FILE_CONFIGURATION_NAME%
echo --------------------------------------------------------------------------------
echo JAVA_CLASSPATH             : %ORA_BENCH_JAVA_CLASSPATH%
echo PATH                       : %PATH%
echo --------------------------------------------------------------------------------
echo:| TIME
echo ================================================================================

call scripts\run_show_environment.bat
if %ERRORLEVEL% NEQ 0 (
    echo ERRORLEVEL : %ERRORLEVEL%
    GOTO EndOfScript
)

call src_java\scripts\run_gradle
if %ERRORLEVEL% NEQ 0 (
    echo ERRORLEVEL : %ERRORLEVEL%
    GOTO EndOfScript
)

java -cp "%ORA_BENCH_JAVA_CLASSPATH%" ch.konnexions.orabench.OraBench setup
if %ERRORLEVEL% NEQ 0 (
    echo ERRORLEVEL : %ERRORLEVEL%
)

:EndOfScript
echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================

exit /B %ERRORLEVEL%
