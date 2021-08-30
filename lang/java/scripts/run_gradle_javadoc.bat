@echo off

rem ------------------------------------------------------------------------------
rem
rem run_gradle_javadoc.bat: create the Java documentation.
rem
rem ------------------------------------------------------------------------------

echo ================================================================================
echo Start %0
echo --------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - Gradle: create the Java documentation.
echo --------------------------------------------------------------------------------
echo:| TIME
echo ================================================================================

cd lang\java

call gradle javadoc --warning-mode all
if %ERRORLEVEL% neq 0 (
    echo Processing of the script: %0 - step: 'call gradle javadoc --warning-mode all' was aborted, error code=%ERRORLEVEL%
    exit -1073741510
)

rd /Q /S ..\priv\docs_java
md ..\priv\docs_java
xcopy /Q /S build\docs\* ..\priv\docs_java

cd ..\..
set ERRORLEVEL=%ERRORLEVEL_ORIGINAL%
if %ERRORLEVEL% neq 0 (
    echo Processing of the script: %0 - step: 'set ERRORLEVEL=%ERRORLEVEL_ORIGINAL%' was aborted, error code=%ERRORLEVEL%
    exit -1073741510
)

echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================
