#!/bin/bash

# ------------------------------------------------------------------------------
#
# run_show_environment.sh: Show environment variables and software versions.
#
# ------------------------------------------------------------------------------

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - show environment variables and software versions."
echo "--------------------------------------------------------------------------------"
echo "GOPATH                     : $GOPATH"
echo "GOROOT                     : $GOROOT"
echo "GRADLE_HOME                : $GRADLE_HOME"
echo "LD_LIBRARY_PATH            : $LD_LIBRARY_PATH"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

EXITCODE="0"

echo "===============================================================================> Version autoconf:"
if ! autoconf -V; then
    echo "ERRORLEVEL : $?"
    exit $?
fi
    
echo "===============================================================================> Version automake:"
if ! automake --version; then
    echo "ERRORLEVEL : $?"
    exit $?
fi
    
echo "===============================================================================> Version Elixir:"
if ! elixir -v; then
    echo "ERRORLEVEL : $?"
    exit $?
fi
    
echo "===============================================================================> Version gcc:"
if ! gcc --version; then
    echo "ERRORLEVEL : $?"
    exit $?
fi
    
echo "===============================================================================> Version Git:"
if ! git --version; then
    echo "ERRORLEVEL : $?"
    exit $?
fi
    
echo "===============================================================================> Version Go:"
if ! go version; then
    echo "ERRORLEVEL : $?"
    exit $?
fi
    
if ! go env; then
    echo "ERRORLEVEL : $?"
    exit $?
fi
    
echo "===============================================================================> Version Gradle:"
if ! gradle --version; then
    echo "ERRORLEVEL : $?"
    exit $?
fi
    
echo "===============================================================================> Version Java:"
if ! java -version; then
    echo "ERRORLEVEL : $?"
    exit $?
fi
    
echo "===============================================================================> Version Mix:"
if ! mix --version; then
    echo "ERRORLEVEL : $?"
    exit $?
fi
    
echo "===============================================================================> Version Python3:"
if ! python3 --version; then
    echo "ERRORLEVEL : $?"
    exit $?
fi
    
echo "===============================================================================> Version Rebar3:"
if ! rebar3 version; then
    echo "ERRORLEVEL : $?"
    exit $?
fi
    
echo "===============================================================================> Version Ubuntu:"
if ! lsb_release -a; then
    echo "ERRORLEVEL : $?"
    exit $?
fi
    
EXITCODE=$?

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"

exit $EXITCODE
