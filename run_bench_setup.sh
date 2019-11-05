#!/bin/bash

# ------------------------------------------------------------------------------
#
# run_bench_setup.sh: Database Setup.
#
# ------------------------------------------------------------------------------

EXITCODE="0"

# ==============================================================================

CONNECT_IDENTIFIER=//$ORABENCH_CONNECTION_HOST:$ORABENCH_CONNECTION_PORT/$ORABENCH_CONNECTION_SERVICE

printf "Enter SYS password: \n"; read PASSWORD_SYS; stty echo; printf "\n"

PATH=$PATH:/u01/app/oracle/product/12.2/db_1/jdbc/lib

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - database setup."
echo "--------------------------------------------------------------------------------"
echo "CONNECT_IDENTIFIER : $CONNECT_IDENTIFIER"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME          : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

sqlplus sys/$PASSWORD_SYS@$CONNECT_IDENTIFIER AS SYSDBA @run_bench_setup.sql

make -f java_src/Makefile clean

make -f java_src/Makefile

java -cp "priv/java_jar/*" ch.konnexions.orabench.OraBench createBulkFile

EXITCODE=$?

EXITCODE=$?

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME          : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"

exit $EXITCODE
