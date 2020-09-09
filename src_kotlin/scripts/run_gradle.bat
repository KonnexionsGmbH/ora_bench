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

call gradlew jar
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)

if not exist "..\priv\kotlin_jar\" mkdir ..\priv\kotlin_jar
move build\libs\ora_bench.jar ..\priv\kotlin_jar

call gradlew dokkaHtml
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)

echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================
