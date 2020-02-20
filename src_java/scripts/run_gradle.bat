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

cd src_java

call gradlew assemble
copy /Y build\libs\ora_bench.jar ..\priv\java_jar

call gradlew javadoc
rmdir /s /q ..\priv\java_doc
mkdir ..\priv\java_doc
xcopy /Q /S build\docs\javadoc\*.* ..\priv\java_doc

call gradlew clean

cd ..

echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================

exit /B %ERRORLEVEL%
