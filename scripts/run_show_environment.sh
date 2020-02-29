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
echo "PATH                       : $PATH"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

EXITCODE="0"

echo "===============================================================================> Version autoconf:"
echo $(autoconf -V)
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi
    
echo "===============================================================================> Version automake:"
echo $(automake --version)
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi
    
echo "===============================================================================> Version Elixir:"
echo $(elixir -v)
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi
    
echo "===============================================================================> Version gcc:"
echo $(gcc --version)
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi
    
echo "===============================================================================> Version Git:"
echo $(git --version)
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi
    
echo "===============================================================================> Version Go:"
echo $(go version)
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi
    
echo $(go env)
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi
    
echo "===============================================================================> Version Gradle:"
echo $(gradle --version)
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi
    
echo "===============================================================================> Version Java:"
echo $(java -version)
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi
    
echo "===============================================================================> Version Mix:"
echo $(mix --version)
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi
    
echo "===============================================================================> Version Python3:"
echo $(python3 --version)
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi
    
echo "===============================================================================> Version Rebar3:"
echo $(rebar3 version)
if [ $? -ne 0 ]; then
    echo "ERRORLEVEL : $?"
    exit $?
fi
    
echo "===============================================================================> Version Ubuntu:"
echo $(lsb_release -a) 
if [ $? -ne 0 ]; then
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
