@echo off

rem --------------------------------------------------------------------------------
rem
rem run_all_drivers.bat: Oracle benchmark for all database drivers.
rem
rem --------------------------------------------------------------------------------

setlocal EnableDelayedExpansion

echo ===============================================================================
echo Start %0
echo -------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - all drivers.
echo -------------------------------------------------------------------------------
echo RUN_CX_ORACLE_PYTHON              : %ORA_BENCH_RUN_CX_ORACLE_PYTHON%
echo RUN_GODROR_GO                     : %ORA_BENCH_RUN_GODROR_GO%
echo RUN_JDBC_JAVA                     : %ORA_BENCH_RUN_JDBC_JAVA%
echo RUN_JDBC_JULIA                    : %ORA_BENCH_RUN_JDBC_JULIA%
echo RUN_JDBC_KOTLIN                   : %ORA_BENCH_RUN_JDBC_KOTLIN%
echo RUN_NIMODPI_NIM                   : %ORA_BENCH_RUN_NIMODPI_NIM%
echo RUN_ODPI_C                        : %ORA_BENCH_RUN_ODPI_C%
echo RUN_ORACLE_JULIA                  : %ORA_BENCH_RUN_ORACLE_JULIA%
echo RUN_ORACLE_RUST                   : %ORA_BENCH_RUN_ORACLE_RUST%
echo RUN_ORANIF_ELIXIR                 : %ORA_BENCH_RUN_ORANIF_ELIXIR%
echo RUN_ORANIF_ERLANG                 : %ORA_BENCH_RUN_ORANIF_ERLANG%
echo -------------------------------------------------------------------------------
echo BENCHMARK_BATCH_SIZE              : %ORA_BENCH_BENCHMARK_BATCH_SIZE%
echo BENCHMARK_CORE_MULTIPLIER         : %ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%
echo BENCHMARK_TRANSACTION_SIZE        : %ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%
echo -------------------------------------------------------------------------------
echo:| TIME
echo ===============================================================================

if ["%ORA_BENCH_RUN_ODPI_C%"] EQU ["true"] (
    call lang\c\scripts\run_bench_odpi.bat
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call lang\c\scripts\run_bench_odpi.bat' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )
)

if ["%ORA_BENCH_RUN_ORANIF_ELIXIR%"] EQU ["true"] (
    call lang\elixir\scripts\run_bench_oranif.bat
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call lang\elixir\scripts\run_bench_oranif.bat' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )
)

if ["%ORA_BENCH_RUN_ORANIF_ERLANG%"] EQU ["true"] (
    call lang\erlang\scripts\run_bench_oranif.bat
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call lang\erlang\scripts\run_bench_oranif.bat' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )
)

if ["%ORA_BENCH_RUN_GODROR_GO%"] EQU ["true"] (
    call lang\go\scripts\run_bench_godror.bat
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call lang\go\scripts\run_bench_godror.bat' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )
)

if ["%ORA_BENCH_RUN_JDBC_JAVA%"] EQU ["true"] (
    call lang\java\scripts\run_bench_jdbc.bat
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call lang\java\scripts\run_bench_jdbc.bat' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )
)

if ["%ORA_BENCH_RUN_JDBC_JULIA%"] EQU ["true"] (
    call lang\julia\scripts\run_bench_jdbc.bat
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call lang\julia\scripts\run_bench_jdbc.bat' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )
)

if ["%ORA_BENCH_RUN_ORACLE_JULIA%"] EQU ["true"] (
    call lang\julia\scripts\run_bench_oracle.bat
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call lang\julia\scripts\run_bench_oracle.bat' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )
)

if ["%ORA_BENCH_RUN_JDBC_KOTLIN%"] EQU ["true"] (
    call lang\kotlin\scripts\run_bench_jdbc.bat
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call lang\kotlin\scripts\run_bench_jdbc.bat' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )
)

if ["%ORA_BENCH_RUN_NIMODPI_NIM%"] EQU ["true"] (
    call lang\nim\scripts\run_bench_nimodpi.bat
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call lang\nim\scripts\run_bench_nimodpi.bat' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )
)

if ["%ORA_BENCH_RUN_CX_ORACLE_PYTHON%"] EQU ["true"] (
    call lang\python\scripts\run_bench_cx_oracle.bat
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call lang\python\scripts\run_bench_cx_oracle.bat' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )
)

if ["%ORA_BENCH_RUN_ORACLE_RUST%"] EQU ["true"] (
    call lang\rust\scripts\run_bench_oracle.bat
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call lang\rust\scripts\run_bench_oracle.bat' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )
)

if ["%ORA_BENCH_CHOICE_DRIVER%"] NEQ ["none"] (
    call scripts\run_finalise_benchmark.bat
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call scripts\run_finalise_benchmark.bat' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )
)    

echo -------------------------------------------------------------------------------
echo:| TIME
echo -------------------------------------------------------------------------------
echo End   %0
echo ===============================================================================
