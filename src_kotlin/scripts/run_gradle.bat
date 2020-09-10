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

if not exist "..\priv\kotlin_jar\NUL" mkdir ..\priv\kotlin_jar
move /Y build\libs\ora_bench.jar ..\priv\libs\ora_bench_kotlin.jar

call gradlew dokkaHtml
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)

rd /Q /S ..\priv\docs_kotlin
md ..\priv\docs_kotlin
xcopy /Q /S build\dokka\* ..\priv\docs_kotlin

cd ..

echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================
