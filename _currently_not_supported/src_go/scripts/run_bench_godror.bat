@echo off

rem ------------------------------------------------------------------------------
rem
rem run_bench_godror.bat: Oracle Benchmark based on Go.
rem
rem ------------------------------------------------------------------------------

if ["%ORA_BENCH_BENCHMARK_DATABASE%"] EQU [""] (
    set ORA_BENCH_BENCHMARK_DATABASE=db_19_3_ee
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

if ["%ORA_BENCH_FILE_CONFIGURATION_NAME%"] EQU [""] (
    set ORA_BENCH_FILE_CONFIGURATION_NAME=priv/properties/ora_bench.properties
)

echo ================================================================================
echo Start %0
echo --------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - godror and Go.
echo --------------------------------------------------------------------------------
echo MULTIPLE_RUN               : %ORA_BENCH_MULTIPLE_RUN%
echo --------------------------------------------------------------------------------
echo BENCHMARK_DATABASE         : %ORA_BENCH_BENCHMARK_DATABASE%
echo CONNECTION_HOST            : %ORA_BENCH_CONNECTION_HOST%
echo CONNECTION_PORT            : %ORA_BENCH_CONNECTION_PORT%
echo CONNECTION_SERVICE         : %ORA_BENCH_CONNECTION_SERVICE%
echo --------------------------------------------------------------------------------
echo BENCHMARK_BATCH_SIZE       : %ORA_BENCH_BENCHMARK_BATCH_SIZE%
echo BENCHMARK_CORE_MULTIPLIER  : %ORA_BENCH_BENCHMARK_CORE_MULTIPLIER%
echo BENCHMARK_TRANSACTION_SIZE : %ORA_BENCH_BENCHMARK_TRANSACTION_SIZE%
echo --------------------------------------------------------------------------------
echo FILE_CONFIGURATION_NAME    : %ORA_BENCH_FILE_CONFIGURATION_NAME%
echo --------------------------------------------------------------------------------
echo GOROOT                     : %GOROOT%
echo --------------------------------------------------------------------------------
echo:| TIME
echo ================================================================================

if NOT ["%ORA_BENCH_MULTIPLE_RUN%"] == ["true"] (
    go get github.com/godror/godror
    if %ERRORLEVEL% NEQ 0 (
        echo Processing of the script: %0 - step: 'go get github.com/godror/godror' was aborted, error code=%ERRORLEVEL%
        exit %ERRORLEVEL%
    )

    call src_java\scripts\run_gradle
    if %ERRORLEVEL% NEQ 0 (
        echo Processing of the script: %0 - step: 'call src_java\scripts\run_gradle' was aborted, error code=%ERRORLEVEL%
        exit %ERRORLEVEL%
    )
)

java -jar priv/libs/ora_bench_java.jar setup_default
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script: %0 - step: 'java -jar priv/libs/ora_bench_java.jar setup_default' was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)

go mod tidy
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script: %0 - step: 'go mod tidy' was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)

go get github.com/godror/godror
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script: %0 - step: 'go get github.com/godror/godror' was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)

go get golang.org/x/xerrors
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script: %0 - step: 'go get golang.org/x/xerrors' was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)

go mod tidy
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)

go get github.com/godror/godror
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)

go get golang.org/x/xerrors
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)

go run src_go\orabench.go priv\properties\ora_bench.properties
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script: %0 - step: 'go run src_go\orabench.go priv\properties\ora_bench.properties' was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)

echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================
