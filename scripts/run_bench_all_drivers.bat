@echo off

rem ------------------------------------------------------------------------------
rem
rem run_bench_all_drivers.bat: Oracle benchmark for all database drivers.
rem
rem ------------------------------------------------------------------------------

setlocal EnableDelayedExpansion

set ORA_BENCH_MULTIPLE_RUN=true

if ["%ORA_BENCH_RUN_CX_ORACLE_PYTHON%"] EQU [""] (
    set ORA_BENCH_RUN_CX_ORACLE_PYTHON=true
)
if ["%ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG%"] EQU [""] (
    set ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG=true
)
if ["%ORA_BENCH_RUN_JDBC_JAVA%"] EQU [""] (
    set ORA_BENCH_RUN_JDBC_JAVA=true
)
if ["%ORA_BENCH_RUN_ODPI_C%"] EQU [""] (
    set ORA_BENCH_RUN_ODPI_C=true
)
if ["%ORA_BENCH_RUN_ORANIF_ELIXIR%"] EQU [""] (
    set ORA_BENCH_RUN_ORANIF_ELIXIR=true
)
if ["%ORA_BENCH_RUN_ORANIF_ERLANG%"] EQU [""] (
    set ORA_BENCH_RUN_ORANIF_ERLANG=true
)

if ["%RUN_GLOBAL_JAMDB%"] EQU [""] (
    set RUN_GLOBAL_JAMDB=true
)
if ["%RUN_GLOBAL_NON_JAMDB%"] EQU [""] (
    set RUN_GLOBAL_NON_JAMDB=true
)

echo ================================================================================
echo Start %0
echo --------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - all drivers.
echo --------------------------------------------------------------------------------
echo ORA_BENCH_BENCHMARK_JAMDB  : %ORA_BENCH_BENCHMARK_JAMDB%
echo RUN_GLOBAL_JAMDB           : %RUN_GLOBAL_JAMDB%
echo RUN_GLOBAL_NON_JAMDB       : %RUN_GLOBAL_NON_JAMDB%
echo --------------------------------------------------------------------------------
echo RUN_CX_ORACLE_PYTHON       : %ORA_BENCH_RUN_CX_ORACLE_PYTHON%
echo RUN_JAMDB_ORACLE_ERLANG    : %ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG%
echo RUN_JDBC_JAVA              : %ORA_BENCH_RUN_JDBC_JAVA%
echo RUN_ODPI_C                 : %ORA_BENCH_RUN_ODPI_C%
echo RUN_ORANIF_ELIXIR          : %ORA_BENCH_RUN_ORANIF_ELIXIR%
echo RUN_ORANIF_ERLANG          : %ORA_BENCH_RUN_ORANIF_ERLANG%
echo --------------------------------------------------------------------------------
echo:| TIME
echo ================================================================================

call scripts\run_create_bulk_file.bat
if %ERRORLEVEL% NEQ 0 (
    echo ERRORLEVEL : %ERRORLEVEL%
    GOTO EndOfScript
)

if ["%RUN_GLOBAL_NON_JAMDB%"] EQU ["true"] (
    if ["%ORA_BENCH_RUN_CX_ORACLE_PYTHON%"] EQU ["true"] (
        call src_python\scripts\run_bench_cx_oracle.bat
        if %ERRORLEVEL% NEQ 0 (
            echo ERRORLEVEL : %ERRORLEVEL%
            GOTO EndOfScript
        )
    )
)

if ["%RUN_GLOBAL_JAMDB%"] EQU ["true"] (
    if ["%ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG%"] EQU ["true"] (
        call src_erlang\scripts\run_bench_jamdb_oracle.bat
        if %ERRORLEVEL% NEQ 0 (
            echo ERRORLEVEL : %ERRORLEVEL%
            GOTO EndOfScript
        )
    )
)

if ["%RUN_GLOBAL_NON_JAMDB%"] EQU ["true"] (
    if ["%ORA_BENCH_RUN_JDBC_JAVA%"] EQU ["true"] (
        call src_java\scripts\run_bench_jdbc.bat
        if %ERRORLEVEL% NEQ 0 (
            echo ERRORLEVEL : %ERRORLEVEL%
            GOTO EndOfScript
        )
    )
    
    if ["%ORA_BENCH_RUN_ODPI_C%"] EQU ["true"] (
        call src_c\scripts\run_bench_odpi.bat
        if %ERRORLEVEL% NEQ 0 (
            echo ERRORLEVEL : %ERRORLEVEL%
            GOTO EndOfScript
        )
    )
    
    if ["%ORA_BENCH_RUN_ORANIF_ELIXIR%"] EQU ["true"] (
        call src_elixir\scripts\run_bench_oranif.bat
        if %ERRORLEVEL% NEQ 0 (
            echo ERRORLEVEL : %ERRORLEVEL%
            GOTO EndOfScript
        )
    )
    
    if ["%ORA_BENCH_RUN_ORANIF_ERLANG%"] EQU ["true"] (
        call src_erlang\scripts\run_bench_oranif.bat
        if %ERRORLEVEL% NEQ 0 (
            echo ERRORLEVEL : %ERRORLEVEL%
            GOTO EndOfScript
        )
    )
)

call scripts\run_finalise_benchmark.bat
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
