@echo off

rem ------------------------------------------------------------------------------
rem
rem run_show_environment.bat: Show environment variables and software versions.
rem
rem ------------------------------------------------------------------------------

echo ================================================================================
echo Start %0
echo --------------------------------------------------------------------------------
echo ora_bench - Oracle benchmark - show environment variables and software versions.
echo --------------------------------------------------------------------------------
echo GOROOT                            : %GOROOT%
echo LD_LIBRARY_PATH                   : %LD_LIBRARY_PATH%
echo --------------------------------------------------------------------------------
echo:| TIME
echo ================================================================================

echo =============================================================================== Version Elixir:
call elixir -v
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script: %0 - step:  'call elixir -v' was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)
    
echo =============================================================================== Version Git:
git --version
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script: %0 - step: 'git --version' was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)
    
echo =============================================================================== Version Go:
go version
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script: %0 - step: 'go version' was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)

echo =============================================================================== Version Gradle:
call gradle -version
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script: %0 - step: 'call gradle -version' was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)

echo =============================================================================== Version Java:
java -version
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script: %0 - step: 'java -version' was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)
    
echo =============================================================================== Version Kotlin:
call kotlin -version
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script: %0 - step: 'call kotlin -version' was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)
    
echo =============================================================================== Version Mix:
call mix --version
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script: %0 - step: 'call mix --version' was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)
    
echo =============================================================================== Version Oracle Instant client:
sqlplus -V
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script: %0 - step: 'sqlplus -V' was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)
    
echo =============================================================================== Version Python 3:
python --version
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script: %0 - step: 'python --version' was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)
    
echo =============================================================================== Version Rebar3:
call rebar3 version
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script: %0 - step: 'call rebar3 version' was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)
    
echo =============================================================================== Version Windows:
systeminfo | findstr Build
if %ERRORLEVEL% NEQ 0 (
    echo Processing of the script: %0 - step: 'systeminfo | findstr Build'  was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)

echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================
