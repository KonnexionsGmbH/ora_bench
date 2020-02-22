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
echo:| TIME
echo ================================================================================

cd src_kotlin

call gradlew assemble
copy /Y build\libs\ora_bench.jar ..\priv\kotlin_jar

rem call gradlew javadoc
rem rmdir /s /q ..\priv\java_doc
rem mkdir ..\priv\java_doc
rem xcopy /Q /S build\docs\javadoc\*.* ..\priv\java_doc

rem call gradlew clean

cd ..

echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================

exit /B %ERRORLEVEL%
