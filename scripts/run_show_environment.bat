@echo off

rem --------------------------------------------------------------------------------
rem
rem run_show_environment.bat: Show environment variables and software versions.
rem
rem --------------------------------------------------------------------------------

echo ===============================================================================
echo Start %0
echo -------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - show environment variables and software versions.
echo -------------------------------------------------------------------------------
echo GOROOT                     : %GOROOT%
echo LD_LIBRARY_PATH            : %LD_LIBRARY_PATH%
echo -------------------------------------------------------------------------------
echo:| TIME
echo ===============================================================================

echo =============================================================================== Version Elixir:
call elixir -v
if ERRORLEVEL 1 (
    echo Processing of the script: %0 - step:  'call elixir -v' was aborted, error code=%ERRORLEVEL%
    exit -1073741510
)

echo =============================================================================== Version Erlang:
rebar3 version
if ERRORLEVEL 1 (
    echo Processing of the script: %0 - step:  'rebar3 version' was aborted, error code=%ERRORLEVEL%
    exit -1073741510
)

echo =============================================================================== Version Go:
go version
if ERRORLEVEL 1 (
    echo Processing of the script: %0 - step: 'go version' was aborted, error code=%ERRORLEVEL%
    exit -1073741510
)

echo =============================================================================== Version Java:
java -version
if ERRORLEVEL 1 (
    echo Processing of the script: %0 - step: 'java -version' was aborted, error code=%ERRORLEVEL%
    exit -1073741510
)

remecho "=============================================================================> Version Julia: "
remjulia -version
remif ERRORLEVEL 1 (
rem    echo Processing of the script: %0 - step: 'julia -version' was aborted, error code=%ERRORLEVEL%
rem    exit -1073741510
rem)

echo =============================================================================== Version Kotlin:
call kotlin -version
if ERRORLEVEL 1 (
    echo Processing of the script: %0 - step: 'call kotlin -version' was aborted, error code=%ERRORLEVEL%
    exit -1073741510
)

echo "=============================================================================> Version Nim: "
nim --version
if ERRORLEVEL 1 (
    echo Processing of the script: %0 - step: 'nim --version' was aborted, error code=%ERRORLEVEL%
    exit -1073741510
)

echo =============================================================================== Version Python 3:
python --version
if ERRORLEVEL 1 (
    echo Processing of the script: %0 - step: 'python --version' was aborted, error code=%ERRORLEVEL%
    exit -1073741510
)

echo =============================================================================== Version Rust:
rustc --version
if ERRORLEVEL 1 (
    echo Processing of the script: %0 - step: 'rustc --version' was aborted, error code=%ERRORLEVEL%
    exit -1073741510
)

echo -------------------------------------------------------------------------------
echo:| TIME
echo -------------------------------------------------------------------------------
echo End   %0
echo ===============================================================================
