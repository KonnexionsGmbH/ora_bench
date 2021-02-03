#!/bin/bash

set -e

# ------------------------------------------------------------------------------
#
# run_install_4_ubuntu_20.04_check.sh: Check the environment for Ubuntu 20.04.
#
# ------------------------------------------------------------------------------


echo ""
echo "Script $0 is now running"

export LOG_FILE=run_install_4_ubuntu_20.04_check.log

echo ""
echo "You can find the run log in the file ${LOG_FILE}"
echo ""

exec &> >(tee -i ${LOG_FILE}) 2>&1
sleep .1

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "Check the environment for Ubuntu 20.04."
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"
echo "Supplement necessary system software"
echo "--------------------------------------------------------------------------------"

echo "=====================================================================> Current Date: "
date
# Show Environment Variables ---------------------------------------------------
echo "=====================================================================> Environment variable GOROOT: "
echo ${GOROOT}
echo "=====================================================================> Environment variable GRADLE_HOME: "
echo ${GRADLE_HOME}
echo "=====================================================================> Environment variable LANG: "
echo ${LANG}
echo "=====================================================================> Environment variable LANGUAGE: "
echo ${LANGUAGE}
echo "=====================================================================> Environment variable LC_ALL: "
echo ${LC_ALL}
echo "=====================================================================> Environment variable LD_LIBRARY_PATH: "
echo ${LD_LIBRARY_PATH}
echo "=====================================================================> Environment variable ORACLE_HOME: "
echo ${ORACLE_HOME}
echo "=====================================================================> Environment variable PATH: "
echo ${PATH}
# Show component versions ------------------------------------------------------
echo "=====================================================================> Core Components"
echo "=====================================================================> Version  Docker: "
docker version
echo "=====================================================================> Version  Docker Compose: "
docker-compose version
echo "=====================================================================> Version  Eclipse: "
echo "${VERSION_ECLIPSE_1}-${VERSION_ECLIPSE_2}"
echo "=====================================================================> Version  Elixir & Erlang: "
elixir -v
mix --version
echo "=====================================================================> Version  GCC: "
gcc --version
echo "=====================================================================> Version  Git: "
git --version
echo "=====================================================================> Version  Go: "
go version
go env
echo "=====================================================================> Version  Gradle: "
gradle --version
echo "=====================================================================> Version  Java: "
java -version
echo "=====================================================================> Version  Kotlin: "
kotlin -version
echo "=====================================================================> Version  LCOV: "
lcov --version
echo "=====================================================================> Version  nginx: "
nginx -v
echo "=====================================================================> Version  Node.js: "
node --version
echo "=====================================================================> Version  OpenSSL: "
openssl version -a
echo "=====================================================================> Version  Oracle Instant Client: "
sqlplus -V
echo "=====================================================================> Version  Python3: "
python3 --version
echo "=====================================================================> Version  rebar3: "
rebar3 version
echo "=====================================================================> Version  Rust: "
rustc --version
echo "=====================================================================> Version  Ubuntu: "
lsb_release -a
echo "=====================================================================> Version  Vim: "
vim --version
echo "=====================================================================> Version  Yarn: "
yarn --version
echo "=====================================================================> Miscellaneous"
echo "=====================================================================> Version  Alien: "
alien --version
echo "=====================================================================> Version  CMake: "
cmake --version
echo "=====================================================================> Version  cURL: "
curl --version
echo "=====================================================================> Version  dos2unix: "
dos2unix --version
echo "=====================================================================> Version  GNU Autoconf: "
autoconf -V
echo "=====================================================================> Version  GNU Automake: "
automake --version
echo "=====================================================================> Version  GNU make: "
make --version
echo "=====================================================================> Version  htop: "
htop --version
echo "=====================================================================> Version  npm: "
npm --version
echo "=====================================================================> Version  Procps-ng: "
ps --version
pip --version
echo "=====================================================================> Version  tmux: "
tmux -V
echo "=====================================================================> Version  wget: "
wget --version 

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"

exit