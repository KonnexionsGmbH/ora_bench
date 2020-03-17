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
echo GOPATH                     : %GOPATH%
echo GOROOT                     : %GOROOT%
echo GRADLE_HOME                : %GRADLE_HOME%
echo LD_LIBRARY_PATH            : %LD_LIBRARY_PATH%
echo --------------------------------------------------------------------------------
echo:| TIME
echo ================================================================================

echo "===============================================================================> Version Elixir:"
call elixir -v
if %ERRORLEVEL% NEQ 0 (
    exit /B %ERRORLEVEL%
)
    
echo "===============================================================================> Version Git:"
git --version
if %ERRORLEVEL% NEQ 0 (
    exit /B %ERRORLEVEL%
)
    
echo "===============================================================================> Version Go:"
go version
if %ERRORLEVEL% NEQ 0 (
    exit /B %ERRORLEVEL%
)

go env
if %ERRORLEVEL% NEQ 0 (
    exit /B %ERRORLEVEL%
)
    
echo "===============================================================================> Version Gradle:"
call gradle --version
if %ERRORLEVEL% NEQ 0 (
    exit /B %ERRORLEVEL%
)
    
echo "===============================================================================> Version Java:"
java -version
if %ERRORLEVEL% NEQ 0 (
    exit /B %ERRORLEVEL%
)
    
echo "===============================================================================> Version Mix:"
call mix --version
if %ERRORLEVEL% NEQ 0 (
    exit /B %ERRORLEVEL%
)
    
echo "===============================================================================> Version Python3:"
python --version
if %ERRORLEVEL% NEQ 0 (
    exit /B %ERRORLEVEL%
)
    
echo "===============================================================================> Version Rebar3:"
call rebar3 version
if %ERRORLEVEL% NEQ 0 (
    exit /B %ERRORLEVEL%
)
    
echo "===============================================================================> Version Windows:"
systeminfo | findstr Build 
if %ERRORLEVEL% NEQ 0 (
    exit /B %ERRORLEVEL%
)

echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================

exit /B %ERRORLEVEL%
