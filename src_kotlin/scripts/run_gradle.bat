@echo off

rem ------------------------------------------------------------------------------
rem
rem run_gradle.bat: clean and assemble the Kotlin part of the project.
rem
rem ------------------------------------------------------------------------------

echo ================================================================================
echo Start %0
echo --------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - Gradle: clean and assemble the Kotlin part of the project.
echo --------------------------------------------------------------------------------
echo MULTIPLE_RUN               : %ORA_BENCH_MULTIPLE_RUN%
echo --------------------------------------------------------------------------------
echo:| TIME
echo ================================================================================

cd src_kotlin

call gradlew clean
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)

call gradlew copyJarToLib
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)

call gradlew dokkaHtml
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)

set ORA_BENCH_FILE_CONFIGURATION_NAME_ORIGINAL=%ORA_BENCH_FILE_CONFIGURATION_NAME%
set ORA_BENCH_FILE_CONFIGURATION_NAME=..\priv\properties\ora_bench.properties
call gradlew test
set ERRORLEVEL_ORIGINAL=%ERRORLEVEL%
set ORA_BENCH_FILE_CONFIGURATION_NAME=%ORA_BENCH_FILE_CONFIGURATION_NAME_ORIGINAL%
cd ..
set ERRORLEVEL=%ERRORLEVEL_ORIGINAL%
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)

echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================
