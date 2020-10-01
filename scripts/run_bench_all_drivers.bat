@echo off

rem ------------------------------------------------------------------------------
rem
rem run_bench_all_drivers.bat: Oracle benchmark for all database drivers.
rem
rem ------------------------------------------------------------------------------

setlocal EnableDelayedExpansion

echo ================================================================================
echo Start %0
echo --------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - all drivers.
echo --------------------------------------------------------------------------------
echo RUN_CX_ORACLE_PYTHON              : %ORA_BENCH_RUN_CX_ORACLE_PYTHON%
echo RUN_JDBC_KOTLIN                   : %ORA_BENCH_RUN_JDBC_KOTLIN%
echo RUN_GODROR_GO                     : %ORA_BENCH_RUN_GODROR_GO%
echo RUN_JDBC_JAVA                     : %ORA_BENCH_RUN_JDBC_JAVA%
echo RUN_ODPI_C                        : %ORA_BENCH_RUN_ODPI_C%
echo RUN_ORANIF_ELIXIR                 : %ORA_BENCH_RUN_ORANIF_ELIXIR%
echo RUN_ORANIF_ERLANG                 : %ORA_BENCH_RUN_ORANIF_ERLANG%
echo --------------------------------------------------------------------------------
echo:| TIME
echo ================================================================================

if ["%ORA_BENCH_RUN_CX_ORACLE_PYTHON%"] EQU ["true"] (
    call src_python\scripts\run_bench_cx_oracle.bat
    if %ERRORLEVEL% NEQ 0 (
        echo Processing of the script was aborted, error code=%ERRORLEVEL%
        exit %ERRORLEVEL%
    )
)

if ["%ORA_BENCH_RUN_GODROR_GO%"] EQU ["true"] (
    call src_go\scripts\run_bench_godror.bat
    if %ERRORLEVEL% NEQ 0 (
        echo Processing of the script was aborted, error code=%ERRORLEVEL%
        exit %ERRORLEVEL%
    )
)
    
if ["%ORA_BENCH_RUN_JDBC_KOTLIN%"] EQU ["true"] (
    call src_kotlin\scripts\run_bench_jdbc.bat
    if %ERRORLEVEL% NEQ 0 (
        echo Processing of the script was aborted, error code=%ERRORLEVEL%
        exit %ERRORLEVEL%
    )
)

if ["%ORA_BENCH_RUN_JDBC_JAVA%"] EQU ["true"] (
    call src_java\scripts\run_bench_jdbc.bat
    if %ERRORLEVEL% NEQ 0 (
        echo Processing of the script was aborted, error code=%ERRORLEVEL%
        exit %ERRORLEVEL%
    )
)

if ["%ORA_BENCH_RUN_ODPI_C%"] EQU ["true"] (
    call src_c\scripts\run_bench_odpi.bat
    if %ERRORLEVEL% NEQ 0 (
        echo Processing of the script was aborted, error code=%ERRORLEVEL%
        exit %ERRORLEVEL%
    )
)
    
if ["%ORA_BENCH_RUN_ORANIF_ELIXIR%"] EQU ["true"] (
    call src_elixir\scripts\run_bench_oranif.bat
    if %ERRORLEVEL% NEQ 0 (
        echo Processing of the script was aborted, error code=%ERRORLEVEL%
        exit %ERRORLEVEL%
    )
)

if ["%ORA_BENCH_RUN_ORANIF_ERLANG%"] EQU ["true"] (
    call src_erlang\scripts\run_bench_oranif.bat
    if %ERRORLEVEL% NEQ 0 (
        echo Processing of the script was aborted, error code=%ERRORLEVEL%
        exit %ERRORLEVEL%
    )
)

call scripts\run_finalise_benchmark.bat
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)

echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================
