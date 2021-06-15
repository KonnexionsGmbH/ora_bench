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
    echo "===                                                                          ==="
    echo "=== autoconf missing                                                         ==="
    echo "===                                                                          ==="
    echo "================================================================================"
    exit 255
fi
    
echo "===============================================================================> Version automake:"
if ! automake --version; then
    echo "===                                                                          ==="
    echo "=== automake missing                                                         ==="
    echo "===                                                                          ==="
    echo "================================================================================"
    exit 255
fi
    
echo "===============================================================================> Version Elixir:"
if ! elixir -v; then
    echo "===                                                                          ==="
    echo "=== Elixir missing                                                           ==="
    echo "===                                                                          ==="
    echo "================================================================================"
    exit 255
fi
    
echo "===============================================================================> Version gcc:"
if ! gcc --version; then
    echo "===                                                                          ==="
    echo "=== gcc missing                                                              ==="
    echo "===                                                                          ==="
    echo "================================================================================"
    exit 255
fi
    
echo "===============================================================================> Version Git:"
if ! git --version; then
    echo "===                                                                          ==="
    echo "=== Git missing                                                              ==="
    echo "===                                                                          ==="
    echo "================================================================================"
    exit 255
fi
    
echo "===============================================================================> Version Go:"
if ! go version; then
    echo "===                                                                          ==="
    echo "=== Go missing                                                               ==="
    echo "===                                                                          ==="
    echo "================================================================================"
    exit 255
fi
    
if ! go env; then
    echo "===                                                                          ==="
    echo "=== Go (env) missing                                                         ==="
    echo "===                                                                          ==="
    echo "================================================================================"
    exit 255
fi
    
echo "===============================================================================> Version Gradle:"
if ! gradle --version; then
    echo "===                                                                          ==="
    echo "=== Gradle missing                                                           ==="
    echo "===                                                                          ==="
    echo "================================================================================"
    exit 255
fi

echo "===============================================================================> Version Java:"
if ! java -version; then
    echo "===                                                                          ==="
    echo "=== Java missing                                                             ==="
    echo "===                                                                          ==="
    echo "================================================================================"
    exit 255
fi
    
echo "===============================================================================> Version Kotlin:"
if ! kotlin -version; then
    echo "===                                                                          ==="
    echo "=== Kotlin missing                                                           ==="
    echo "===                                                                          ==="
    echo "================================================================================"
    exit 255
fi
    
echo "===============================================================================> Version Mix:"
if ! mix --version; then
    echo "===                                                                          ==="
    echo "=== mix missing                                                              ==="
    echo "===                                                                          ==="
    echo "================================================================================"
    exit 255
fi
    
echo "===============================================================================> Version Oracle Instant client:"
if ! sqlplus -V; then
    echo "===                                                                          ==="
    echo "=== sqlplus missing                                                          ==="
    echo "===                                                                          ==="
    echo "================================================================================"
    exit 255
fi
    
echo "===============================================================================> Version Python 3:"
if ! python --version; then
    echo "===                                                                          ==="
    echo "=== Python missing                                                           ==="
    echo "===                                                                          ==="
    echo "================================================================================"
    exit 255
fi
    
echo "===============================================================================> Version Rebar3:"
if ! rebar3 version; then
    echo "===                                                                          ==="
    echo "=== rebar3 missing                                                           ==="
    echo "===                                                                          ==="
    echo "================================================================================"
    exit 255
fi
    
echo "===============================================================================> Version Ubuntu:"
if ! lsb_release -a; then
    echo "===                                                                          ==="
    echo "=== OS missing                                                               ==="
    echo "===                                                                          ==="
    echo "================================================================================"
    exit 255
fi
    
echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"
