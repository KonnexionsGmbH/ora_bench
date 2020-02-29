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
echo PATH                       : %PATH%
echo --------------------------------------------------------------------------------
echo:| TIME
echo ================================================================================

echo ===============================================================================> Version autoconf:
autoconf -V
if %ERRORLEVEL% NEQ 0 (
    echo ERRORLEVEL : %ERRORLEVEL%
    GOTO EndOfScript
)
    
echo ===============================================================================> Version automake:
automake --version
if %ERRORLEVEL% NEQ 0 (
    echo ERRORLEVEL : %ERRORLEVEL%
    GOTO EndOfScript
)
    
echo ===============================================================================> Version Elixir:
elixir -v
if %ERRORLEVEL% NEQ 0 (
    echo ERRORLEVEL : %ERRORLEVEL%
    GOTO EndOfScript
)
    
echo ===============================================================================> Version gcc:
gcc --version
if %ERRORLEVEL% NEQ 0 (
    echo ERRORLEVEL : %ERRORLEVEL%
    GOTO EndOfScript
)
    
echo ===============================================================================> Version Git:
git --version
if %ERRORLEVEL% NEQ 0 (
    echo ERRORLEVEL : %ERRORLEVEL%
    GOTO EndOfScript
)
    
echo ===============================================================================> Version Go:
go version
if %ERRORLEVEL% NEQ 0 (
    echo ERRORLEVEL : %ERRORLEVEL%
    GOTO EndOfScript
)

go env
if %ERRORLEVEL% NEQ 0 (
    echo ERRORLEVEL : %ERRORLEVEL%
    GOTO EndOfScript
)
    
echo ===============================================================================> Version Gradle:
gradle --version
if %ERRORLEVEL% NEQ 0 (
    echo ERRORLEVEL : %ERRORLEVEL%
    GOTO EndOfScript
)
    
echo ===============================================================================> Version Java:
java -version
if %ERRORLEVEL% NEQ 0 (
    echo ERRORLEVEL : %ERRORLEVEL%
    GOTO EndOfScript
)
    
echo ===============================================================================> Version Mix:
mix --version
if %ERRORLEVEL% NEQ 0 (
    echo ERRORLEVEL : %ERRORLEVEL%
    GOTO EndOfScript
)
    
echo ===============================================================================> Version Python3:
python3 --version
if %ERRORLEVEL% NEQ 0 (
    echo ERRORLEVEL : %ERRORLEVEL%
    GOTO EndOfScript
)
    
echo ===============================================================================> Version Rebar3:
rebar3 version
if %ERRORLEVEL% NEQ 0 (
    echo ERRORLEVEL : %ERRORLEVEL%
    GOTO EndOfScript
)
    
echo ===============================================================================> Version Ubuntu:
lsb_release -a 
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
