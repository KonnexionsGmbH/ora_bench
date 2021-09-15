@echo off

rem --------------------------------------------------------------------------------
rem
rem collect_and_compile.bat: Collect libraries and compile. 
rem
rem --------------------------------------------------------------------------------

setlocal EnableDelayedExpansion

echo 000
echo ===============================================================================
echo Start %0
echo -------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - collect libraries and compile.
echo -------------------------------------------------------------------------------
echo BENCHMARK_VCVARSALL        : %ORA_BENCH_BENCHMARK_VCVARSALL%
echo BULKFILE_EXISTING          : %ORA_BENCH_BULKFILE_EXISTING%
echo -------------------------------------------------------------------------------
echo RUN_CX_ORACLE_PYTHON       : %ORA_BENCH_RUN_CX_ORACLE_PYTHON%
echo RUN_GODROR_GO              : %ORA_BENCH_RUN_GODROR_GO%
echo RUN_JDBC_JAVA              : %ORA_BENCH_RUN_JDBC_JAVA%
echo RUN_JDBC_KOTLIN            : %ORA_BENCH_RUN_JDBC_KOTLIN%
echo RUN_ODPI_C                 : %ORA_BENCH_RUN_ODPI_C%
echo RUN_ORACLE_JL_JULIA        : %ORA_BENCH_RUN_ORACLE_JL_JULIA%
echo RUN_ORANIF_ELIXIR          : %ORA_BENCH_RUN_ORANIF_ELIXIR%
echo RUN_ORANIF_ERLANG          : %ORA_BENCH_RUN_ORANIF_ERLANG%
echo -------------------------------------------------------------------------------
echo GOROOT                     : %GOROOT%
echo GRADLE_HOME                : %GRADLE_HOME%
echo LD_LIBRARY_PATH            : %LD_LIBRARY_PATH%
echo -------------------------------------------------------------------------------
echo:| TIME
echo ===============================================================================

echo --------------------------------------------------------------------------------
echo Set environment variables for C / C++ compilation.
echo --------------------------------------------------------------------------------
if exist "%ORA_BENCH_BENCHMARK_VCVARSALL%" (
    call "%ORA_BENCH_BENCHMARK_VCVARSALL%" x64
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'vcvarsall.bat' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )
)

if NOT ["%ORA_BENCH_BULKFILE_EXISTING%"] == ["true"] (
    call scripts\run_create_bulk_file.bat
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call scripts\run_create_bulk_file.bat' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )
)

if ["%ORA_BENCH_RUN_ODPI_C%"] == ["true"] (
    echo Setup C++ [gcc] - Start ========================================================
    java -jar priv/libs/ora_bench_java.jar setup_c
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'java -jar priv/libs/ora_bench_java.jar setup_c' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    nmake -f lang\c\Makefile.win32 clean
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'nmake -f lang\c\Makefile.win32 clean' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    nmake -f lang\c\Makefile.win32
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'nmake -f lang\c\Makefile.win32' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    echo Setup C++ [gcc] - End   ========================================================
)

if ["%ORA_BENCH_RUN_GODROR_GO%"] == ["true"] (
    echo Setup Go - Start ===============================================================
    go get github.com/godror/godror
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'go get github.com/godror/godror' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    echo Setup Go - End   ===============================================================
)

if ["%ORA_BENCH_RUN_JDBC_KOTLIN%"] == ["true"] (
    echo Setup Kotlin - Start ===========================================================
    call lang\kotlin\scripts\run_gradle.bat
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call lang\kotlin\scripts\run_gradle.bat' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    echo Setup Kotlin - End   ===========================================================
)

echo -------------------------------------------------------------------------------
echo:| TIME
echo -------------------------------------------------------------------------------
echo End   %0
echo ===============================================================================
