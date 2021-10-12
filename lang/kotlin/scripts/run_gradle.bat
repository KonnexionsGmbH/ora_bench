@echo off

rem --------------------------------------------------------------------------------
rem
rem run_gradle.bat: clean and assemble the Kotlin part of the project.
rem
rem --------------------------------------------------------------------------------

echo ===============================================================================
echo Start %0
echo -------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - Gradle: clean and assemble the Kotlin part of the project.
echo -------------------------------------------------------------------------------
echo:| TIME
echo ===============================================================================

cd lang\kotlin

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

call gradle jar --warning-mode all
if %ERRORLEVEL% neq 0 (
    echo Processing of the script: %0 - step: 'call gradle jar --warning-mode all' was aborted, error code=%ERRORLEVEL%
    exit -1073741510
)

copy /Y build\libs\ora_bench.jar ..\..\priv\libs\ora_bench_kotlin.jar

cd ..\..

echo -------------------------------------------------------------------------------
echo:| TIME
echo -------------------------------------------------------------------------------
echo End   %0
echo ===============================================================================
