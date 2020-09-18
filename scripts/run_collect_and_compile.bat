@echo off

rem ------------------------------------------------------------------------------
rem
rem collect_and_compile.bat: Collect libraries and compile. 
rem
rem ------------------------------------------------------------------------------

setlocal EnableDelayedExpansion

if ["%GOPATH%"] EQU [""] (
    set GOPATH=%cd%\src_go
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
echo ora_bench - Oracle benchmark - collect libraries and compile.
echo --------------------------------------------------------------------------------
echo BULKFILE_EXISTING                 : %ORA_BENCH_BULKFILE_EXISTING%
echo --------------------------------------------------------------------------------
echo RUN_GLOBAL_JAMDB                  : %RUN_GLOBAL_JAMDB%
echo RUN_GLOBAL_NON_JAMDB              : %RUN_GLOBAL_NON_JAMDB%
echo --------------------------------------------------------------------------------
echo RUN_CX_ORACLE_PYTHON              : %ORA_BENCH_RUN_CX_ORACLE_PYTHON%
echo RUN_JDBC_KOTLIN                   : %ORA_BENCH_RUN_JDBC_KOTLIN%
echo RUN_GODROR_GO                     : %ORA_BENCH_RUN_GODROR_GO%
echo RUN_JAMDB_ORACLE_ERLANG           : %ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG%
echo RUN_JDBC_JAVA                     : %ORA_BENCH_RUN_JDBC_JAVA%
echo RUN_ODPI_C                        : %ORA_BENCH_RUN_ODPI_C%
echo RUN_ORANIF_ELIXIR                 : %ORA_BENCH_RUN_ORANIF_ELIXIR%
echo RUN_ORANIF_ERLANG                 : %ORA_BENCH_RUN_ORANIF_ERLANG%
echo --------------------------------------------------------------------------------
echo GOPATH                            : %GOPATH%
echo GOROOT                            : %GOROOT%
echo GRADLE_HOME                       : %GRADLE_HOME%
echo LD_LIBRARY_PATH                   : %LD_LIBRARY_PATH%
echo --------------------------------------------------------------------------------
echo:| TIME
echo ================================================================================

if NOT ["%ORA_BENCH_BULKFILE_EXISTING%"] == ["true"] (
    call scripts\run_create_bulk_file.bat
    if %ERRORLEVEL% NEQ 0 call script\run_abort
        echo Processing of the script was aborted, error code=%ERRORLEVEL%
        exit %ERRORLEVEL%
    )
)

if ["%RUN_GLOBAL_NON_JAMDB%"] EQU ["true"] (
    if ["%ORA_BENCH_RUN_ODPI_C%"] == ["true"] (
        echo Setup C - Start ============================================================ 
        java -jar priv/libs/ora_bench_java.jar setup_c
        if %ERRORLEVEL% NEQ 0 (
            echo Processing of the script was aborted, error code=%ERRORLEVEL%
            exit %ERRORLEVEL%
        )

        nmake -f src_c\Makefile.win32 clean
        if %ERRORLEVEL% NEQ 0 (
            echo Processing of the script was aborted, error code=%ERRORLEVEL%
            exit %ERRORLEVEL%
        )
        
        nmake -f src_c\Makefile.win32
        if %ERRORLEVEL% NEQ 0 (
            echo Processing of the script was aborted, error code=%ERRORLEVEL%
            exit %ERRORLEVEL%
        )
    
        echo Setup C - End   ============================================================ 
    )

    if ["%ORA_BENCH_RUN_ORANIF_ELIXIR%"] == ["true"] (
        echo Setup Elixir - Start ======================================================= 
        java -jar priv/libs/ora_bench_java.jar setup_elixir
        if %ERRORLEVEL% NEQ 0 (
            echo Processing of the script was aborted, error code=%ERRORLEVEL%
            exit %ERRORLEVEL%
        )
    
        cd src_elixir

        if exist deps\ rd /Q/S deps 
        if exist mix.lock del /s mix.lock 

        call mix local.hex --force
        if %ERRORLEVEL% NEQ 0 (
            echo Processing of the script was aborted, error code=%ERRORLEVEL%
            exit %ERRORLEVEL%
        )
        
        call mix deps.clean --all
        if %ERRORLEVEL% NEQ 0 (
            echo Processing of the script was aborted, error code=%ERRORLEVEL%
            exit %ERRORLEVEL%
        )
        
        call mix deps.get
        if %ERRORLEVEL% NEQ 0 (
            echo Processing of the script was aborted, error code=%ERRORLEVEL%
            exit %ERRORLEVEL%
        )
        
        call mix deps.compile
        if %ERRORLEVEL% NEQ 0 (
            echo Processing of the script was aborted, error code=%ERRORLEVEL%
            exit %ERRORLEVEL%
        )
        cd ..
        echo Setup Elixir - End   ======================================================= 
    )
)

set ORA_BENCH_RUN_ERLANG=false
if ["%ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG%"] == ["true"] (
    set ORA_BENCH_RUN_ERLANG=true
)

if ["%ORA_BENCH_RUN_ORANIF_ERLANG%"] == ["true"] (
    set ORA_BENCH_RUN_ERLANG=true
)

if ["%ORA_BENCH_RUN_ERLANG%"] == ["true"] (
    echo Setup Erlang - Start ======================================================= 
    java -jar priv/libs/ora_bench_java.jar setup_erlang
    if %ERRORLEVEL% NEQ 0 (
        echo Processing of the script was aborted, error code=%ERRORLEVEL%
        exit %ERRORLEVEL%
    )

    cd src_erlang

    if exist _build\ rd /Q/S _build 

    call rebar3 escriptize
    if %ERRORLEVEL% NEQ 0 (
        echo Processing of the script was aborted, error code=%ERRORLEVEL%
        exit %ERRORLEVEL%
    )
    
    cd ..
    echo Setup Erlang - End   ======================================================= 
)    

if ["%RUN_GLOBAL_NON_JAMDB%"] EQU ["true"] (
    if ["%ORA_BENCH_RUN_GODROR_GO%"] == ["true"] (
        echo Setup Go - Start =========================================================== 
        go get github.com/godror/godror
        if %ERRORLEVEL% NEQ 0 (
            echo Processing of the script was aborted, error code=%ERRORLEVEL%
            exit %ERRORLEVEL%
        )

        echo Setup Go - End   =========================================================== 
    )    
    
    if ["%ORA_BENCH_RUN_JDBC_KOTLIN%"] == ["true"] (
        echo Setup Kotlin - Start ======================================================= 
        call src_kotlin\scripts\run_gradle.bat
        if %ERRORLEVEL% NEQ 0 (
            echo Processing of the script was aborted, error code=%ERRORLEVEL%
            exit %ERRORLEVEL%
        )

        echo Setup Kotlin - End   ======================================================= 
    )    
    
    if ["%ORA_BENCH_RUN_CX_ORACLE_PYTHON%"] == ["true"] (
        echo Setup Python - Start ======================================================= 
        java -jar priv/libs/ora_bench_java.jar setup_python
        if %ERRORLEVEL% NEQ 0 (
            echo Processing of the script was aborted, error code=%ERRORLEVEL%
            exit %ERRORLEVEL%
        )

        echo Setup Python - End   ======================================================= 
    )    
)

echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================
