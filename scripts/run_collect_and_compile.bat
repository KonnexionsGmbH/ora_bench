@echo off

rem ------------------------------------------------------------------------------
rem
rem collect_and_compile.bat: Collect libraries and compile. 
rem
rem ------------------------------------------------------------------------------

setlocal EnableDelayedExpansion

if ["%ORA_BENCH_RUN_CX_ORACLE_PYTHON%"] EQU [""] (
    set ORA_BENCH_RUN_CX_ORACLE_PYTHON=true
)
if ["%ORA_BENCH_RUN_GODROR_GO%"] EQU [""] (
    set ORA_BENCH_RUN_GODROR_GO=true
)
if ["%ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG%"] EQU [""] (
    set ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG=true
)
if ["%ORA_BENCH_RUN_JDBC_JAVA%"] EQU [""] (
    set ORA_BENCH_RUN_JDBC_JAVA=true
)
if ["%ORA_BENCH_RUN_ODPI_C%"] EQU [""] (
    set ORA_BENCH_RUN_ODPI_C=true
)
if ["%ORA_BENCH_RUN_ORANIF_ELIXIR%"] EQU [""] (
    set ORA_BENCH_RUN_ORANIF_ELIXIR=true
)
if ["%ORA_BENCH_RUN_ORANIF_ERLANG%"] EQU [""] (
    set ORA_BENCH_RUN_ORANIF_ERLANG=true
)

if ["%ORA_BENCH_CONNECTION_PORT%"] EQU [""] (
    set ORA_BENCH_FILE_CONFIGURATION_NAME=priv\properties\ora_bench.properties
)

if ["%ORA_BENCH_JAVA_CLASSPATH%"] EQU [""] (
    set ORA_BENCH_JAVA_CLASSPATH=".;priv\java_jar\*"
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
echo BULKFILE_EXISTING          : %ORA_BENCH_BULKFILE_EXISTING%
echo --------------------------------------------------------------------------------
echo RUN_GLOBAL_JAMDB           : %RUN_GLOBAL_JAMDB%
echo RUN_GLOBAL_NON_JAMDB       : %RUN_GLOBAL_NON_JAMDB%
echo --------------------------------------------------------------------------------
echo RUN_CX_ORACLE_PYTHON       : %ORA_BENCH_RUN_CX_ORACLE_PYTHON%
echo RUN_GODROR_GO              : %ORA_BENCH_RUN_GODROR_GO%
echo RUN_JAMDB_ORACLE_ERLANG    : %ORA_BENCH_RUN_JAMDB_ORACLE_ERLANG%
echo RUN_JDBC_JAVA              : %ORA_BENCH_RUN_JDBC_JAVA%
echo RUN_ODPI_C                 : %ORA_BENCH_RUN_ODPI_C%
echo RUN_ORANIF_ELIXIR          : %ORA_BENCH_RUN_ORANIF_ELIXIR%
echo RUN_ORANIF_ERLANG          : %ORA_BENCH_RUN_ORANIF_ERLANG%
echo --------------------------------------------------------------------------------
echo FILE_CONFIGURATION_NAME    : %ORA_BENCH_FILE_CONFIGURATION_NAME%
echo --------------------------------------------------------------------------------
echo GOPATH                     : %GOPATH%
echo GOROOT                     : %GOROOT%
echo GRADLE_HOME                : %GRADLE_HOME%
echo JAVA_CLASSPATH             : %ORA_BENCH_JAVA_CLASSPATH%
echo LD_LIBRARY_PATH            : %LD_LIBRARY_PATH%
echo --------------------------------------------------------------------------------
echo:| TIME
echo ================================================================================

if NOT ["%ORA_BENCH_BULKFILE_EXISTING%"] == ["true"] (
    call scripts\run_create_bulk_file.bat
    if %ERRORLEVEL% NEQ 0 (
        exit /B %ERRORLEVEL%
    )
)

if ["%RUN_GLOBAL_NON_JAMDB%"] EQU ["true"] (
    if ["%ORA_BENCH_RUN_ODPI_C%"] == ["true"] (
        echo Setup C - Start ============================================================ 
        java -cp "priv/java_jar/*" ch.konnexions.orabench.OraBench setup_c
        if %ERRORLEVEL% NEQ 0 (
            exit /B %ERRORLEVEL%
        )

        nmake -f src_c\Makefile.win32 clean
        if %ERRORLEVEL% NEQ 0 (
            exit /B %ERRORLEVEL%
        )
        
        nmake -f src_c\Makefile.win32
        if %ERRORLEVEL% NEQ 0 (
            exit /B %ERRORLEVEL%
        )
        echo Setup C - End   ============================================================ 
    )

    if ["%ORA_BENCH_RUN_ORANIF_ELIXIR%"] == ["true"] (
        echo Setup Elixir - Start ======================================================= 
        java -cp "priv/java_jar/*" ch.konnexions.orabench.OraBench setup_elixir
        if %ERRORLEVEL% NEQ 0 (
            exit /B %ERRORLEVEL%
        )
    
        cd src_elixir
        call mix local.hex --force
        if %ERRORLEVEL% NEQ 0 (
            exit /B %ERRORLEVEL%
        )
        
        call mix deps.clean --all
        if %ERRORLEVEL% NEQ 0 (
            exit /B %ERRORLEVEL%
        )
        
        call mix deps.get
        if %ERRORLEVEL% NEQ 0 (
            exit /B %ERRORLEVEL%
        )
        
        call mix deps.compile
        if %ERRORLEVEL% NEQ 0 (
            exit /B %ERRORLEVEL%
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
    java -cp "priv/java_jar/*" ch.konnexions.orabench.OraBench setup_erlang
    if %ERRORLEVEL% NEQ 0 (
        exit /B %ERRORLEVEL%
    )

    cd src_erlang
    call rebar3 escriptize
    if %ERRORLEVEL% NEQ 0 (
        exit /B %ERRORLEVEL%
    )
    cd ..
    echo Setup Erlang - End   ======================================================= 
)    

if ["%RUN_GLOBAL_NON_JAMDB%"] EQU ["true"] (
    if ["%ORA_BENCH_RUN_GODROR_GO%"] == ["true"] (
        echo Setup Go - Start =========================================================== 
        go get github.com/godror/godror
        if %ERRORLEVEL% NEQ 0 (
            exit /B %ERRORLEVEL%
        )
        echo Setup Go - End   =========================================================== 
    )    
    
    if ["%ORA_BENCH_RUN_CX_ORACLE_PYTHON%"] == ["true"] (
        echo Setup Python - Start ======================================================= 
        java -cp "priv/java_jar/*" ch.konnexions.orabench.OraBench setup_python
        if %ERRORLEVEL% NEQ 0 (
            exit /B %ERRORLEVEL%
        )
        echo Setup Python - End   ======================================================= 
    )    
)

echo --------------------------------------------------------------------------------
echo:| TIME
echo --------------------------------------------------------------------------------
echo End   %0
echo ================================================================================

exit /B %ERRORLEVEL%
