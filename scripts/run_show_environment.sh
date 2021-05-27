#!/bin/bash

# ------------------------------------------------------------------------------
#
# run_show_environment.sh: Show environment variables and software versions.
#
# ------------------------------------------------------------------------------

set -e

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - show environment variables and software versions."
echo "--------------------------------------------------------------------------------"
echo "GOROOT                            : $GOROOT"
echo "LD_LIBRARY_PATH                   : $LD_LIBRARY_PATH"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

echo "===============================================================================> Version autoconf:"
if ! autoconf -V; then
    exit 255
fi
    
echo "===============================================================================> Version automake:"
if ! automake --version; then
    exit 255
fi
    
echo "===============================================================================> Version Elixir:"
if ! elixir -v; then
    exit 255
fi
    
echo "===============================================================================> Version gcc:"
if ! gcc --version; then
    exit 255
fi
    
echo "===============================================================================> Version Git:"
if ! git --version; then
    exit 255
fi
    
echo "===============================================================================> Version Go:"
if ! go version; then
    exit 255
fi
    
if ! go env; then
    exit 255
fi
    
echo "===============================================================================> Version Gradle:"
if ! gradle --version; then
    exit 255
fi

echo "===============================================================================> Version Java:"
if ! java -version; then
    exit 255
fi
    
echo "===============================================================================> Version Kotlin:"
if ! kotlin -version; then
    exit 255
fi
    
echo "===============================================================================> Version Mix:"
if ! mix --version; then
    exit 255
fi
    
echo "===============================================================================> Version Oracle Instant client:"
if ! sqlplus -V; then
    exit 255
fi
    
echo "===============================================================================> Version Python3:"
if ! python3 --version; then
    exit 255
fi
    
echo "===============================================================================> Version Rebar3:"
if ! rebar3 version; then
    exit 255
fi
    
echo "===============================================================================> Version Ubuntu:"
if ! lsb_release -a; then
    exit 255
fi
    
echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"
