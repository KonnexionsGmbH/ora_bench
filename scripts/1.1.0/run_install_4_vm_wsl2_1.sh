#!/bin/bash

set -e

# ----------------------------------------------------------------------------------
#
# run_install_4_vm_wsl2_1.sh: Install a ora_bench_dev environment for Ubuntu 20.04 - Step 1.
#
# ----------------------------------------------------------------------------------

sudo rm -rf /tmp/*

export HOST_ENVIRONMENT_DEFAULT=vm

export VERSION_ORA_BENCH_DEV=1.1.0

export VERSION_CMAKE=3.21.3
export VERSION_DBEAVER=21.2.2
export VERSION_ECLIPSE_1=2021-09
export VERSION_ECLIPSE_2=R
export VERSION_ELIXIR=1.12.3-otp-24
export VERSION_ERLANG=24.1.2
export VERSION_GCC=10
export VERSION_GO=1.17.2
export VERSION_GRADLE=7.2
export VERSION_HTOP=3.1.0
export VERSION_JAVA=openjdk-17
export VERSION_JULIA=1.6.3
export VERSION_KOTLIN=1.5.31
export VERSION_ORACLE_INSTANT_CLIENT_1=21
export VERSION_ORACLE_INSTANT_CLIENT_2=3
export VERSION_PYTHON3=3.10.0
export VERSION_REBAR3=3.16.1
export VERSION_RUST=1.55.0
export VERSION_TMUX=3.2a

if [ -z "$1" ]; then
    echo "=============================================================================="
    echo "vm   - Virtual Machine"
    echo "wsl2 - Windows Subsystem for Linux Version 2"
    echo "------------------------------------------------------------------------------"
    read -rp "Enter the underlying host environment type [default: ${HOST_ENVIRONMENT_DEFAULT}] " HOST_ENVIRONMENT
    export HOST_ENVIRONMENT=${HOST_ENVIRONMENT}
    
    if [ -z "${HOST_ENVIRONMENT}" ]; then
    export HOST_ENVIRONMENT=${HOST_ENVIRONMENT_DEFAULT}
    fi
else
    export HOST_ENVIRONMENT=$1
fi

if [ "${HOST_ENVIRONMENT}" = "vm" ]; then
    cp -r ../../../config_data/config_dbeaver/dbeaver.desktop ~/.local/share/applications/dbeaver.desktop
    cp -r ../../../config_data/config_eclipse/eclipse.desktop ~/.local/share/applications/eclipse.desktop
fi

mkdir -p ~/kxn_install

cp -r config_dbeaver ~/kxn_install

cp -r config_python3 ~/kxn_install

cd ~/

# Setting Environment Variables ----------------------------------------------------
export DEBIAN_FRONTEND=noninteractive
export LOCALE=en_US.UTF-8

PATH_ADD_ON=
PATH_ORIG=${PATH_ORIG}

if [ -z "${PATH_ORIG}" ]; then
    PATH_ORIG=\"${PATH}\"
else
    PATH_ORIG=\"${PATH_ORIG}\"
fi

export TIMEZONE=Europe/Zurich

echo '' >> ~/.bashrc
echo '# ----------------------------------------------------------------------------' >> ~/.bashrc
echo '# Environment ora_bench_dev for Ubuntu 20.04 - Start' >> ~/.bashrc
echo '# ----------------------------------------------------------------------------' >> ~/.bashrc
echo " "
echo "Script $0 is now running"

export LOG_FILE=run_install_4_vm_wsl2_1.log

echo ""
echo "You can find the run log in the file ${LOG_FILE}"
echo ""

exec &> >(tee -i ${LOG_FILE}) 2>&1
sleep .1

echo "=============================================================================="
echo "Start $0"
echo "------------------------------------------------------------------------------"
echo "Install a ora_bench_dev environment for Ubuntu 20.04 - Step 1."
echo "------------------------------------------------------------------------------"
echo "HOST_ENVIRONMENT                  : ${HOST_ENVIRONMENT}"
echo "USER                              : ${USER}"
echo "------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "=============================================================================="
echo "Supplement necessary system software"
echo "------------------------------------------------------------------------------"
sudo apt-get clean -qy

sudo apt-get update -qy
sudo apt-get install -qy gnupg \
                         software-properties-common

sudo apt-key adv --fetch-keys http://repos.codelite.org/CodeLite.asc
sudo apt-add-repository 'deb http://repos.codelite.org/wx3.0.5/ubuntu/ focal universe'

sudo apt-get update -qy
sudo apt-get upgrade -qy

sudo apt-get install -qy alien \
                         autoconf \
                         automake \
                         build-essential \
                         byacc \
                         coreutils \
                         curl \
                         default-jdk \
                         dos2unix \
                         fop \
                         freeglut3-dev \
                         g++-${VERSION_GCC} \
                         gcc-${VERSION_GCC} \
                         git \
                         gnupg2 \
                         jq \
                         lcov \
                         libaio1 \
                         libbz2-dev \
                         libffi-dev \
                         libglu1-mesa-dev \
                         liblzma-dev \
                         libncurses-dev \
                         libncurses5-dev \
                         libncursesw5-dev \
                         libreadline-dev \
                         libsqlite3-dev \
                         libssl-dev \
                         libwxbase3.0-0-unofficial \
                         libwxbase3.0-dev \
                         libwxgtk3.0-0-unofficial \
                         libwxgtk3.0-dev \
                         libxml2-dev \
                         libxml2-utils \
                         libxmlsec1-dev \
                         llvm \
                         locales \
                         lsb-release \
                         mesa-common-dev \
                         pkg-config \
                         procps \
                         tk-dev \
                         tzdata \
                         unixodbc-dev \
                         unzip \
                         vim \
                         wget \
                         wget2 \
                         wx-common \
                         wx3.0-headers \
                         xsltproc  \
                         xz-utils \
                         zlib1g-dev
                        
echo "------------------------------------------------------------------------------"
echo "Step: Setting Locale & Timezone"
echo "------------------------------------------------------------------------------"
sudo ln -fs /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
sudo dpkg-reconfigure --frontend noninteractive tzdata
sudo locale-gen "${LOCALE}"
sudo update-locale "LANG=de_CH.UTF-8 UTF-8"
sudo locale-gen --purge "de_CH.UTF-8"
sudo dpkg-reconfigure --frontend noninteractive locales

echo "------------------------------------------------------------------------------"
echo "Step: Setting up the environment: 1. Setting the environment variables"
echo "------------------------------------------------------------------------------"

# from asdf ------------------------------------------------------------------------
PATH_ADD_ON=~/.asdf/bin:~/.asdf/shims:${PATH_ADD_ON}
# from DBeaver ---------------------------------------------------------------------
export HOME_DBEAVER=/opt/dbeaver
PATH_ADD_ON=${HOME_DBEAVER}:${PATH_ADD_ON}
# from Eclipse ---------------------------------------------------------------------
export HOME_ECLIPSE=/opt/eclipse
PATH_ADD_ON=${HOME_ECLIPSE}:${PATH_ADD_ON}
# from ODBC ------------------------------------------------------------------------
PATH_ADD_ON=/opt/mssql-tools/bin:${PATH_ADD_ON}
# from Oracle Instant Client -------------------------------------------------------
export ORACLE_HOME=/usr/lib/oracle/${VERSION_ORACLE_INSTANT_CLIENT_1}/client64
eval echo 'export ORACLE_HOME=/usr/lib/oracle/${VERSION_ORACLE_INSTANT_CLIENT_1}/client64' >> ~/.bashrc
export LD_LIBRARY_PATH=${ORACLE_HOME}/lib:${LD_LIBRARY_PATH}
eval echo 'export LD_LIBRARY_PATH=${ORACLE_HOME}/lib:${LD_LIBRARY_PATH}' >> ~/.bashrc
PATH_ADD_ON=${ORACLE_HOME}:${PATH_ADD_ON}

# from Locale & Timezone -----------------------------------------------------------
echo '' >> ~/.bashrc
eval echo 'export DEBIAN_FRONTEND=${DEBIAN_FRONTEND}' >> ~/.bashrc
eval echo 'export HOST_ENVIRONMENT=${HOST_ENVIRONMENT}' >> ~/.bashrc
eval echo 'export LANG=${LOCALE}' >> ~/.bashrc
eval echo 'export LANGUAGE=${LOCALE}' >> ~/.bashrc
eval echo 'export LC_ALL=${LOCALE}' >> ~/.bashrc
eval echo 'export LOCALE=${LOCALE}' >> ~/.bashrc

echo '' >> ~/.bashrc
eval echo 'export VERSION_ORA_BENCH_DEV=${VERSION_ORA_BENCH_DEV}' >> ~/.bashrc

echo '' >> ~/.bashrc
eval echo 'export VERSION_CMAKE=${VERSION_CMAKE}' >> ~/.bashrc
eval echo 'export VERSION_DBEAVER=${VERSION_DBEAVER}' >> ~/.bashrc
eval echo 'export VERSION_DOS2UNIX=${VERSION_DOS2UNIX}' >> ~/.bashrc
eval echo 'export VERSION_ECLIPSE_1=${VERSION_ECLIPSE_1}' >> ~/.bashrc
eval echo 'export VERSION_ECLIPSE_2=${VERSION_ECLIPSE_2}' >> ~/.bashrc
eval echo 'export VERSION_ELIXIR=${VERSION_ELIXIR}' >> ~/.bashrc
eval echo 'export VERSION_ERLANG=${VERSION_ERLANG}' >> ~/.bashrc
eval echo 'export VERSION_GCC=${VERSION_GCC}' >> ~/.bashrc
eval echo 'export VERSION_GO=${VERSION_GO}' >> ~/.bashrc
eval echo 'export VERSION_GRADLE=${VERSION_GRADLE}' >> ~/.bashrc
eval echo 'export VERSION_HTOP=${VERSION_HTOP}' >> ~/.bashrc
eval echo 'export VERSION_JAVA=${VERSION_JAVA}' >> ~/.bashrc
eval echo 'export VERSION_JULIA=${VERSION_JULIA}' >> ~/.bashrc
eval echo 'export VERSION_KOTLIN=${VERSION_KOTLIN}' >> ~/.bashrc
eval echo 'export VERSION_ORACLE_INSTANT_CLIENT_1=${VERSION_ORACLE_INSTANT_CLIENT_1}' >> ~/.bashrc
eval echo 'export VERSION_ORACLE_INSTANT_CLIENT_2=${VERSION_ORACLE_INSTANT_CLIENT_2}' >> ~/.bashrc
eval echo 'export VERSION_PYTHON3=${VERSION_PYTHON3}' >> ~/.bashrc
eval echo 'export VERSION_REBAR3=${VERSION_REBAR3}' >> ~/.bashrc
eval echo 'export VERSION_RUST=${VERSION_RUST}' >> ~/.bashrc
eval echo 'export VERSION_TMUX=${VERSION_TMUX}' >> ~/.bashrc

echo "------------------------------------------------------------------------------"
echo "Step: Setting up the environment: 2. Initializing the interactive shell session"
echo "------------------------------------------------------------------------------"
echo '' >> ~/.bashrc
echo 'alias python=python3' >> ~/.bashrc
echo 'alias vi=vim' >> ~/.bashrc
# PATH variable --------------------------------------------------------------------
echo '' >> ~/.bashrc
# from DBeaver ---------------------------------------------------------------------
eval echo 'export HOME_DBEAVER=${HOME_DBEAVER}' >> ~/.bashrc
# from Eclipse ---------------------------------------------------------------------
eval echo 'export HOME_ECLIPSE=${HOME_ECLIPSE}' >> ~/.bashrc

eval echo 'export PATH=${PATH_ORIG}:${PATH_ADD_ON}' >> ~/.bashrc
eval echo 'export PATH_ORIG=${PATH_ORIG}' >> ~/.bashrc

# from asdf ------------------------------------------------------------------------
echo '' >> ~/.bashrc
eval echo '. ~/.asdf/asdf.sh' >> ~/.bashrc
eval echo '. ~/.asdf/completions/asdf.bash' >> ~/.bashrc
# from Docker Desktop --------------------------------------------------------------
if [ "${HOST_ENVIRONMENT}" = "vm" ]; then
    echo '' >> ~/.bashrc
    echo 'if [ `id -gn` != "docker" ]; then ( newgrp docker ) fi' >> ~/.bashrc
fi

echo '' >> ~/.bashrc
echo '# ----------------------------------------------------------------------------' >> ~/.bashrc
echo '# Environment ora_bench_dev for Ubuntu 20.04 - End' >> ~/.bashrc
echo '# ----------------------------------------------------------------------------' >> ~/.bashrc

# Initializing the interactive shell session ---------------------------------------
source ~/.bashrc

echo "------------------------------------------------------------------------------"
echo "Step: Install asdf - part 1"
echo "------------------------------------------------------------------------------"
sudo rm -rf ~/.asdf
git clone https://github.com/asdf-vm/asdf.git ~/.asdf
echo "=============================================================================="

if [ "${HOST_ENVIRONMENT}" = "vm" ]; then
    echo "------------------------------------------------------------------------------"
    echo "Step: Install Docker Desktop"
    echo "------------------------------------------------------------------------------"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" --yes
    sudo apt-key fingerprint 0EBFCD88
    sudo apt-get install -qy docker-ce \
                             docker-ce-cli \
                             containerd.io
    sudo chmod 666 /var/run/docker.sock
    if ! [ $(getent group docker | grep -q "\b$USER\b") ]; then
        sudo usermod -aG docker $USER
    fi
    echo " "
    echo "=============================================================================> Version  Docker Desktop: "
    echo " "
    echo "Current version of Docker Desktop: $(docker version)"
    echo " "
    echo "=============================================================================="
fi

echo "------------------------------------------------------------------------------"
echo "Step: Install G++ & GCC - Version ${VERSION_GCC}"
echo "------------------------------------------------------------------------------"
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${VERSION_GCC} 100 --slave /usr/bin/g++ g++ /usr/bin/g++-${VERSION_GCC} --slave /usr/bin/gcov gcov /usr/bin/gcov-${VERSION_GCC}
echo "=============================================================================> Version  G++ & GCC: "
echo " "
echo "Current version of GCC: $(gcc --version)"
echo "Current version of G++: $(g++ --version)"
echo " "
echo "=============================================================================="

echo "------------------------------------------------------------------------------"
echo "Step: Install htop - Version ${VERSION_HTOP}"
echo "------------------------------------------------------------------------------"
wget --no-check-certificate -nv https://github.com/htop-dev/htop/archive/${VERSION_HTOP}.tar.gz
sudo tar -zxf ${VERSION_HTOP}.tar.gz
sudo rm -rf htop
sudo mv htop-${VERSION_HTOP} htop
cd htop
sudo ./autogen.sh
sudo ./configure --prefix=/usr
sudo make --quiet
sudo make --quiet install
cd ..
sudo rm -rf htop
sudo rm -f ${VERSION_HTOP}.tar.gz
echo " "
echo "=============================================================================> Version  htop: "
echo " "
echo "Current version of htop: $(htop --version)"
echo " "
echo "=============================================================================="

echo "=============================================================================="
echo "Step: Install ODBC"
echo "------------------------------------------------------------------------------"
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list > my_prod.list
sudo mv my_prod.list /etc/apt/sources.list.d/mssql-release.list
sudo apt-get update
sudo ACCEPT_EULA=Y apt-get install -y msodbcsql17
sudo ACCEPT_EULA=Y apt-get install -y mssql-tools
sudo apt-get install -y unixodbc-dev
echo " "
echo "=============================================================================> Version  ODBC: "
echo " "
echo "Current version of ODBC: $(odbcinst -j)"
echo " "
echo "=============================================================================="

echo "=============================================================================="
echo "Step: Install Oracle Instant Client - Version ${VERSION_ORACLE_INSTANT_CLIENT_1}.${VERSION_ORACLE_INSTANT_CLIENT_2}.0.0.0"
echo "------------------------------------------------------------------------------"
(
  cd /
  sudo rm -rf oracle-instantclient*
  sudo wget --no-check-certificate -nv https://download.oracle.com/otn_software/linux/instantclient/${VERSION_ORACLE_INSTANT_CLIENT_1}${VERSION_ORACLE_INSTANT_CLIENT_2}000/oracle-instantclient-basic-${VERSION_ORACLE_INSTANT_CLIENT_1}.${VERSION_ORACLE_INSTANT_CLIENT_2}.0.0.0-1.x86_64.rpm
  sudo wget --no-check-certificate -nv https://download.oracle.com/otn_software/linux/instantclient/${VERSION_ORACLE_INSTANT_CLIENT_1}${VERSION_ORACLE_INSTANT_CLIENT_2}000/oracle-instantclient-sqlplus-${VERSION_ORACLE_INSTANT_CLIENT_1}.${VERSION_ORACLE_INSTANT_CLIENT_2}.0.0.0-1.x86_64.rpm
  sudo alien -i *.rpm
  sudo rm -rf *.x86_64.rpm
)
echo " "
echo "=============================================================================> Version  Oracle Instant Client: "
echo " "
echo "Current version of Oracle Instant Client: $(sqlplus -V)"
echo " "
echo "=============================================================================="

echo " "
echo "------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "------------------------------------------------------------------------------"
echo "End   $0"
echo "=============================================================================="

exit 0
