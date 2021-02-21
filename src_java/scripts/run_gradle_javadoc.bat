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

cd src_java

call gradle javadoc --warning-mode all
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)

rd /Q /S ..\priv\docs_java
md ..\priv\docs_java
xcopy /Q /S build\docs\* ..\priv\docs_java

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
