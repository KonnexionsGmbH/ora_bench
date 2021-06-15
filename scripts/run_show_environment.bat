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
    echo ===                                                                          ===
    echo === Elixir missing                                                           ===
    echo ===                                                                          ===
    echo ================================================================================
    echo Processing of the script was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)
    
echo =============================================================================== Version Git:
git --version
if %ERRORLEVEL% NEQ 0 (
    echo ===                                                                          ===
    echo === Git missing                                                              ===
    echo ===                                                                          ===
    echo ================================================================================
    echo Processing of the script was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)
    
echo =============================================================================== Version Go:
go version
if %ERRORLEVEL% NEQ 0 (
    echo ===                                                                          ===
    echo === Go missing                                                               ===
    echo ===                                                                          ===
    echo ================================================================================
    echo Processing of the script was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)

go env
if %ERRORLEVEL% NEQ 0 (
    echo ===                                                                          ===
    echo === Go (env) missing                                                         ===
    echo ===                                                                          ===
    echo ================================================================================
    echo Processing of the script was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)
    
echo =============================================================================== Version Gradle:
call gradle -version
if %ERRORLEVEL% NEQ 0 (
    echo ===                                                                          ===
    echo === Gradle missing                                                           ===
    echo ===                                                                          ===
    echo ================================================================================
    echo Processing of the script was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)

echo =============================================================================== Version Java:
java -version
if %ERRORLEVEL% NEQ 0 (
    echo ===                                                                          ===
    echo === Java missing                                                             ===
    echo ===                                                                          ===
    echo ================================================================================
    echo Processing of the script was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)
    
echo =============================================================================== Version Kotlin:
call kotlin -version
if %ERRORLEVEL% NEQ 0 (
    echo ===                                                                          ===
    echo === Kotlin missing                                                           ===
    echo ===                                                                          ===
    echo ================================================================================
    echo Processing of the script was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)
    
echo =============================================================================== Version Mix:
call mix --version
if %ERRORLEVEL% NEQ 0 (
    echo ===                                                                          ===
    echo === mix missing                                                              ===
    echo ===                                                                          ===
    echo ================================================================================
    echo Processing of the script was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)
    
echo =============================================================================== Version Oracle Instant client:
sqlplus -V
if %ERRORLEVEL% NEQ 0 (
    echo ===                                                                          ===
    echo === sqlplus missing                                                          ===
    echo ===                                                                          ===
    echo ================================================================================
    echo Processing of the script was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)
    
echo =============================================================================== Version Python 3:
python --version
if %ERRORLEVEL% NEQ 0 (
    echo ===                                                                          ===
    echo === Python missing                                                           ===
    echo ===                                                                          ===
    echo ================================================================================
    echo Processing of the script was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)
    
echo =============================================================================== Version Rebar3:
call rebar3 version
if %ERRORLEVEL% NEQ 0 (
    echo ===                                                                          ===
    echo === rebar3 missing                                                           ===
    echo ===                                                                          ===
    echo ================================================================================
    echo Processing of the script was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)
    
echo =============================================================================== Version Windows:
systeminfo | findstr Build 
if %ERRORLEVEL% NEQ 0 (
    echo ===                                                                          ===
    echo === OS missing                                                               ===
    echo ===                                                                          ===
    echo ================================================================================
    echo Processing of the script was aborted, error code=%ERRORLEVEL%
    exit %ERRORLEVEL%
)

echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================
