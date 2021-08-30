@echo off

rem ------------------------------------------------------------------------------
rem
rem run_gradle.bat: clean and assemble the Java part of the project.
rem
rem ------------------------------------------------------------------------------

echo ================================================================================
echo Start %0
echo --------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - Gradle: clean and assemble the Java part of the project.
echo --------------------------------------------------------------------------------
echo:| TIME
echo ================================================================================

cd lang\java

call gradle init --warning-mode all
if %ERRORLEVEL% neq 0 (
    echo Processing of the script: %0 - step: 'call gradle init --warning-mode all' was aborted, error code=%ERRORLEVEL%
    exit -1073741510
)

call gradle clean --warning-mode all
if %ERRORLEVEL% neq 0 (
    echo Processing of the script: %0 - step: 'call gradle clean --warning-mode all' was aborted, error code=%ERRORLEVEL%
    exit -1073741510
)

call gradle copyJarToLib --warning-mode all
if %ERRORLEVEL% neq 0 (
    echo Processing of the script: %0 - step: 'call gradle copyJarToLib --warning-mode all' was aborted, error code=%ERRORLEVEL%
    exit -1073741510
)

set ORA_BENCH_FILE_CONFIGURATION_NAME_ORIGINAL=%ORA_BENCH_FILE_CONFIGURATION_NAME%
set ORA_BENCH_FILE_CONFIGURATION_NAME=..\priv\properties\ora_bench.properties
call gradle test --warning-mode all
set ERRORLEVEL_ORIGINAL=%ERRORLEVEL%
set ORA_BENCH_FILE_CONFIGURATION_NAME=%ORA_BENCH_FILE_CONFIGURATION_NAME_ORIGINAL%
cd ..\..
set ERRORLEVEL=%ERRORLEVEL_ORIGINAL%
if %ERRORLEVEL% neq 0 (
    echo Processing of the script: %0 - step: 'call gradle test --warning-mode all' was aborted, error code=%ERRORLEVEL%
    exit -1073741510
)

echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================
