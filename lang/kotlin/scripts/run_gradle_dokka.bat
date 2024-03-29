@echo off

rem --------------------------------------------------------------------------------
rem
rem run_gradle_dokka.bat: create the Kotlin documentation.
rem
rem --------------------------------------------------------------------------------

echo ===============================================================================
echo Start %0
echo -------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - Gradle: create the Kotlin documentation.
echo -------------------------------------------------------------------------------
echo:| TIME
echo ===============================================================================

cd lang\kotlin

call gradle dokkaHtml --warning-mode all
if %ERRORLEVEL% neq 0 (
    echo Processing of the script: %0 - step: 'call gradle dokkaHtml --warning-mode all' was aborted, error code=%ERRORLEVEL%
    exit -1073741510
)

rd /Q /S ..\priv\docs_kotlin
md ..\priv\docs_kotlin
xcopy /Q /S build\dokka\* ..\priv\docs_kotlin

cd ..\..

echo -------------------------------------------------------------------------------
echo:| TIME
echo -------------------------------------------------------------------------------
echo End   %0
echo ===============================================================================
