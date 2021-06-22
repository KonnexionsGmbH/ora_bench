#!/bin/bash

set -e

# ------------------------------------------------------------------------------
#
# run_application_setup.sh: Setup the db_seeder application.
#
# ------------------------------------------------------------------------------

export HOME_DB_SEEDER=/db_seeder

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "Setup the DDErl application."
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

if [ ! -d "${HOME_DB_SEEDER}" ]; then
    echo "Create the db_seeder repository"
    echo "---------------------------------------------------------"
    git clone https://github.com/KonnexionsGmbH/db_seeder.git
    cd "${HOME_DB_SEEDER}"

    echo "Prepare the db_seeder repository"
    echo "---------------------------------------------------------"
#    cd "${HOME_DB_SEEDER}"
    chmod +x *.sh
    chmod +x lib/*.jar
    chmod +x scripts/*.sh
    gradle copyJarToLib
else
    cd "${HOME_DB_SEEDER}"
fi

echo "Run run_db_seeder_docker_compose"
echo "---------------------------------------------------------"
if ! ( ./scripts/run_db_seeder_docker_compose.sh ); then
    exit 255
fi

echo " "
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"

exit
