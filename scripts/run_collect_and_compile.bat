@echo off

rem ------------------------------------------------------------------------------
rem
rem collect_and_compile.bat: Collect libraries and compile. 
rem
rem ------------------------------------------------------------------------------

setlocal EnableDelayedExpansion

if ["%GOPATH%"] EQU [""] (
    set GOPATH=%cd%\src_go
)

echo ================================================================================
echo Start %0
echo --------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - collect libraries and compile.
echo --------------------------------------------------------------------------------
echo BULKFILE_EXISTING                 : %ORA_BENCH_BULKFILE_EXISTING%
echo --------------------------------------------------------------------------------
echo RUN_CX_ORACLE_PYTHON              : %ORA_BENCH_RUN_CX_ORACLE_PYTHON%
echo RUN_JDBC_KOTLIN                   : %ORA_BENCH_RUN_JDBC_KOTLIN%
echo RUN_GODROR_GO                     : %ORA_BENCH_RUN_GODROR_GO%
echo RUN_JDBC_JAVA                     : %ORA_BENCH_RUN_JDBC_JAVA%
echo RUN_ODPI_C                        : %ORA_BENCH_RUN_ODPI_C%
echo RUN_ORANIF_ELIXIR                 : %ORA_BENCH_RUN_ORANIF_ELIXIR%
echo RUN_ORANIF_ERLANG                 : %ORA_BENCH_RUN_ORANIF_ERLANG%
echo --------------------------------------------------------------------------------
echo GOPATH                            : %GOPATH%
echo GOROOT                            : %GOROOT%
echo GRADLE_HOME                       : %GRADLE_HOME%
echo LD_LIBRARY_PATH                   : %LD_LIBRARY_PATH%
echo --------------------------------------------------------------------------------
echo:| TIME
echo ================================================================================

if NOT ["%ORA_BENCH_BULKFILE_EXISTING%"] == ["true"] (
    call scripts\run_create_bulk_file.bat
    if %ERRORLEVEL% NEQ 0 call script\run_abort
        echo Processing of the script was aborted, error code=%ERRORLEVEL%
        exit %ERRORLEVEL%
    )
)

if ["%ORA_BENCH_RUN_ODPI_C%"] == ["true"] (
    echo Setup C - Start ============================================================
    java -jar priv/libs/ora_bench_java.jar setup_c
    if %ERRORLEVEL% NEQ 0 (
        echo Processing of the script was aborted, error code=%ERRORLEVEL%
        exit %ERRORLEVEL%
    )

    nmake -f src_c\Makefile.win32 clean
    if %ERRORLEVEL% NEQ 0 (
        echo Processing of the script was aborted, error code=%ERRORLEVEL%
        exit %ERRORLEVEL%
    )

    nmake -f src_c\Makefile.win32
    if %ERRORLEVEL% NEQ 0 (
        echo Processing of the script was aborted, error code=%ERRORLEVEL%
        exit %ERRORLEVEL%
    )

    echo Setup C - End   ============================================================
)

if ["%ORA_BENCH_RUN_GODROR_GO%"] == ["true"] (
    echo Setup Go - Start ===========================================================
    go get github.com/godror/godror
    if %ERRORLEVEL% NEQ 0 (
        echo Processing of the script was aborted, error code=%ERRORLEVEL%
        exit %ERRORLEVEL%
    )

    echo Setup Go - End   ===========================================================
)

if ["%ORA_BENCH_RUN_JDBC_KOTLIN%"] == ["true"] (
    echo Setup Kotlin - Start =======================================================
    call src_kotlin\scripts\run_gradle.bat
    if %ERRORLEVEL% NEQ 0 (
        echo Processing of the script was aborted, error code=%ERRORLEVEL%
        exit %ERRORLEVEL%
    )

    echo Setup Kotlin - End   =======================================================
)

echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================
