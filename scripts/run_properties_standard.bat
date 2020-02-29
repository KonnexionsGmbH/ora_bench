@echo off

rem ------------------------------------------------------------------------------
rem
rem run_properties_standard.bat: Run with standard properties.
rem
rem ------------------------------------------------------------------------------

setlocal EnableDelayedExpansion

set ORA_BENCH_MULTIPLE_RUN=true

if [%ORA_BENCH_BENCHMARK_JAMDB%] EQU [""] (
    set RUN_GLOBAL_JAMDB=true
    set RUN_GLOBAL_NON_JAMDB=true
)
if [%ORA_BENCH_BENCHMARK_JAMDB%] EQU ["false"] (
    set RUN_GLOBAL_JAMDB=false
    set RUN_GLOBAL_NON_JAMDB=true
)
if [%ORA_BENCH_BENCHMARK_JAMDB%] EQU ["true"] (
    set RUN_GLOBAL_JAMDB=true
    set RUN_GLOBAL_NON_JAMDB=false
)

echo ================================================================================
echo Start %0
echo --------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - database setup and Oracle benchmark - standard.
echo --------------------------------------------------------------------------------
echo MULTIPLE_RUN               : %ORA_BENCH_MULTIPLE_RUN%
echo --------------------------------------------------------------------------------
echo ORA_BENCH_BENCHMARK_JAMDB  : %ORA_BENCH_BENCHMARK_JAMDB%
echo RUN_GLOBAL_JAMDB           : %RUN_GLOBAL_JAMDB%
echo RUN_GLOBAL_NON_JAMDB       : %RUN_GLOBAL_NON_JAMDB%
echo --------------------------------------------------------------------------------
echo:| TIME
echo ================================================================================

call scripts\run_collect_and_compile.bat
if %ERRORLEVEL% NEQ 0 (
    echo ERRORLEVEL : %ERRORLEVEL%
    GOTO EndOfScript
)

call scripts\run_db_setup.bat
if %ERRORLEVEL% NEQ 0 (
    echo ERRORLEVEL : %ERRORLEVEL%
    GOTO EndOfScript
)

call scripts\run_bench_all_drivers.bat
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
