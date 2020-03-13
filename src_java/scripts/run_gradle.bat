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
echo MULTIPLE_RUN               : %ORA_BENCH_MULTIPLE_RUN%
echo --------------------------------------------------------------------------------
echo:| TIME
echo ================================================================================

(
    cd src_java
    
    call gradlew clean
    if %ERRORLEVEL% NEQ 0 (
        exit /B %ERRORLEVEL%
    )
    
    call gradlew assemble
    if %ERRORLEVEL% NEQ 0 (
        exit /B %ERRORLEVEL%
    )
    
    copy /Y build\libs\ora_bench.jar ..\priv\java_jar
    
    call gradlew javadoc
    if %ERRORLEVEL% NEQ 0 (
        exit /B %ERRORLEVEL%
    )
)
if %ERRORLEVEL% NEQ 0 (
    exit /B %ERRORLEVEL%
)

echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================

exit /B %ERRORLEVEL%
