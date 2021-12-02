@echo off

rem --------------------------------------------------------------------------------
rem
rem run_bench_oracle.bat: Oracle Benchmark based on Rust.
rem
rem --------------------------------------------------------------------------------

if ["%ORA_BENCH_BENCHMARK_DATABASE%"] EQU [""] (
    set ORA_BENCH_BENCHMARK_DATABASE=db_21_3_xe
)
if ["%ORA_BENCH_CONNECTION_HOST%"] EQU [""] (
    set javaORA_BENCH_CONNECTION_HOST=localhost
)
if ["%ORA_BENCH_CONNECTION_PORT%"] EQU [""] (
    set ORA_BENCH_CONNECTION_PORT=1521
)
if ["%ORA_BENCH_CONNECTION_SERVICE%"] EQU [""] (
    set ORA_BENCH_CONNECTION_SERVICE=orclpdb1
)

set ORA_BENCH_FILE_CONFIGURATION_NAME=priv\properties\ora_bench.properties

set ORA_BENCH_RUST_LOG_LEVEL=debug
set ORA_BENCH_RUST_LOG_LEVEL=info

echo ===============================================================================
echo Start %0
echo -------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - Rust-oracle and Rust.
echo -------------------------------------------------------------------------------
echo MULTIPLE_RUN               : %ORA_BENCH_MULTIPLE_RUN%
echo -------------------------------------------------------------------------------
echo BENCHMARK_DATABASE         : %ORA_BENCH_BENCHMARK_DATABASE%
echo CONNECTION_HOST            : %ORA_BENCH_CONNECTION_HOST%
echo CONNECTION_PORT            : %ORA_BENCH_CONNECTION_PORT%
echo CONNECTION_SERVICE         : %ORA_BENCH_CONNECTION_SERVICE%
echo -------------------------------------------------------------------------------
echo BENCHMARK_BATCH_SIZE       : %ORA_BENCH_BENCHMARK_BATCH_SIZE%
echo BENCHMARK_CORE_MULTIPLIER  : %ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%
echo BENCHMARK_TRANSACTION_SIZE : %ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%
echo -------------------------------------------------------------------------------
echo FILE_CONFIGURATION_NAME    : %ORA_BENCH_FILE_CONFIGURATION_NAME%
echo RUST_LOG_LEVEL             : %ORA_BENCH_RUST_LOG_LEVEL%
echo -------------------------------------------------------------------------------
echo:| TIME
echo ===============================================================================

if NOT ["%ORA_BENCH_MULTIPLE_RUN%"] == ["true"] (
    make -C lang\rust
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'make' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    call lang\java\scripts\run_gradle
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'call lang\java\scripts\run_gradle' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )

    java -jar priv/libs/ora_bench_java.jar setup_default
    if %ERRORLEVEL% neq 0 (
        echo Processing of the script: %0 - step: 'java -jar priv/libs/ora_bench_java.jar setup_default' was aborted, error code=%ERRORLEVEL%
        exit -1073741510
    )
)

cargo run --manifest-path lang\rust\Cargo.toml --release %ORA_BENCH_FILE_CONFIGURATION_NAME%
if %ERRORLEVEL% neq 0 (
    echo Processing of the script: %0 - step: 'cargo run' was aborted, error code=%ERRORLEVEL%
    exit -1073741510
)

echo -------------------------------------------------------------------------------
echo:| TIME
echo -------------------------------------------------------------------------------
echo End   %0
echo ===============================================================================
