@echo off

rem ------------------------------------------------------------------------------
rem
rem run_bench_setup.bat: Oracle Benchmark Run Setup.
rem
rem ------------------------------------------------------------------------------

set ORA_BENCH_MULTIPLE_RUN=

if ["%ORA_BENCH_FILE_CONFIGURATION_NAME%"] EQU [""] (
    set ORA_BENCH_FILE_CONFIGURATION_NAME=priv\properties\ora_bench.properties
)

set ORA_BENCH_JAVA_CLASSPATH=.;priv\java_jar\*

echo ================================================================================
echo Start %0
echo --------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - setup benchmark run.
echo --------------------------------------------------------------------------------
echo FILE_CONFIGURATION_NAME : %ORA_BENCH_FILE_CONFIGURATION_NAME%
echo JAVA_CLASSPATH          : %ORA_BENCH_JAVA_CLASSPATH%
echo --------------------------------------------------------------------------------
echo:| TIME
echo ================================================================================

set PATH=%PATH%;\u01\app\oracle\product\12.2\db_1\jdbc\lib

javac -g -deprecation -Werror -cp "%ORA_BENCH_JAVA_CLASSPATH%" -sourcepath src_java ^
      src_java/ch/konnexions/orabench/OraBench.java ^
      src_java/ch/konnexions/orabench/threads/Insert.java ^
      src_java/ch/konnexions/orabench/threads/package-info.java ^
      src_java/ch/konnexions/orabench/threads/Select.java ^
      src_java/ch/konnexions/orabench/utils/Config.java ^
      src_java/ch/konnexions/orabench/utils/Database.java ^
      src_java/ch/konnexions/orabench/utils/Logger.java ^
      src_java/ch/konnexions/orabench/utils/Result.java ^
      src_java/ch/konnexions/orabench/utils/Setup.java
if %ERRORLEVEL% NEQ 0 (
    echo ERRORLEVEL : %ERRORLEVEL%
    GOTO EndOfScript
)

jar cf priv\java_jar\ora_bench.jar -C .\src_java ch
if %ERRORLEVEL% NEQ 0 (
    echo ERRORLEVEL : %ERRORLEVEL%
    GOTO EndOfScript
)

java -cp "%ORA_BENCH_JAVA_CLASSPATH%" ch.konnexions.orabench.OraBench setup
if %ERRORLEVEL% NEQ 0 (
    echo ERRORLEVEL : %ERRORLEVEL%
)

:EndOfScript
echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================

exit /B %ERRORLEVEL%
