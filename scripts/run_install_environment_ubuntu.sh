#!/bin/bash

set -e

# ------------------------------------------------------------------------------
#
# run_install_environment_ubuntu.sh: Install an environment for Ubuntu 20.04.
#
# ------------------------------------------------------------------------------

export LOCALE=en_US.UTF-8
export TIMEZONE=Europe/Zurich

export ORA_BENCH_VERSION_DOCKER="5:19.03.12~3-0~ubuntu-focal"
export ORA_BENCH_VERSION_DOCKER_COMPOSE=1.27.1
export ORA_BENCH_VERSION_ERLANG_SOLUTIONS=2.0
export ORA_BENCH_VERSION_GO=1.15.2
export ORA_BENCH_VERSION_GRADLE=6.6.1
export ORA_BENCH_VERSION_JAVA=15
export ORA_BENCH_VERSION_ORACLE_INSTANT_CLIENT_1=19
export ORA_BENCH_VERSION_ORACLE_INSTANT_CLIENT_2=8

export ORA_BENCH_HOST_ENVIRONMENT_DEFAULT=vm

if [ -z "$1" ]; then
    echo "========================================================="
    echo "vm   - Virtual Machine"
    echo "wsl2 - Windows Subsystem for Linux Version 2"
    echo "---------------------------------------------------------"
    read -rp "Enter the underlying host environment type [default: ${ORA_BENCH_HOST_ENVIRONMENT_DEFAULT}] " ORA_BENCH_HOST_ENVIRONMENT
    export ORA_BENCH_HOST_ENVIRONMENT=${ORA_BENCH_HOST_ENVIRONMENT}

    if [ -z "${ORA_BENCH_HOST_ENVIRONMENT}" ]; then
        export ORA_BENCH_HOST_ENVIRONMENT=${ORA_BENCH_HOST_ENVIRONMENT_DEFAULT}
    fi
else
    export ORA_BENCH_HOST_ENVIRONMENT=$1
fi

if [ -z "$2" ]; then
    read -rp "Kotlin version to be uninstalled [currently installed: $(kotlin -version 2>/dev/null || echo "none")] " ORA_BENCH_VERSION_KOTLIN
    export ORA_BENCH_VERSION_KOTLIN=${ORA_BENCH_VERSION_KOTLIN}
fi

echo ""
echo "Script $0 is now running"

export LOG_FILE=run_install_environment_ubuntu.log

echo ""
echo "You can find the run log in the file $LOG_FILE"
echo ""

exec &> >(tee -i $LOG_FILE) 2>&1
sleep .1

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "ora_bench - Oracle benchmark - install an environment for Ubuntu 20.04."
echo "--------------------------------------------------------------------------------"
echo "HOST_ENVIRONMENT                  : ${ORA_BENCH_HOST_ENVIRONMENT}"
echo "UNINSTALL_VERSION_KOTLIN          : ${ORA_BENCH_VERSION_KOTLIN}"
echo "USER                              : $USER"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"
echo "Common setup"
echo "--------------------------------------------------------------------------------"

sudo apt-get update
sudo apt-get install -qy
sudo apt-get dist-upgrade -qy
sudo apt-get install -qy alien \
                         apt-utils \
                         autoconf \
                         autotools-dev \
                         build-essential \
                         cmake \
                         curl \
                         dos2unix \
                         elixir \
                         iputils-ping \
                         language-pack-de \
                         libaio1 \
                         net-tools \
                         tzdata

# Setting Locale & Timezone ----------------------------------------------------
sudo ln -fs /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
sudo dpkg-reconfigure --frontend noninteractive tzdata
sudo locale-gen "${LOCALE}"
sudo dpkg-reconfigure --frontend noninteractive locales
eval echo 'export ENV LANG=${LOCALE}' >> ~/.bashrc
eval echo 'export LANGUAGE=${LOCALE}' >> ~/.bashrc
eval echo 'export LC_ALL=${LOCALE}' >> ~/.bashrc

if [ "${ORA_BENCH_HOST_ENVIRONMENT}" = "vm" ]; then
    echo "--------------------------------------------------------------------------------"
    echo "Install Docker Desktop - Version ${ORA_BENCH_VERSION_DOCKER}"
    echo "--------------------------------------------------------------------------------"

    sudo apt-get remove docker docker-engine docker.io containerd runc
    sudo apt-get update
    sudo apt-get install apt-transport-https \
                         ca-certificates \
                         gnupg-agent \
                         software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo apt-key fingerprint 0EBFCD88
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo groupadd -f docker
    sudo usermod -a -G docker $USER
    echo group=$(groups)
    . ~/.bashrc
    echo group=$(groups)

    echo "--------------------------------------------------------------------------------"
    echo "Install Docker Compose - Version ${ORA_BENCH_VERSION_DOCKER_COMPOSE}"
    echo "--------------------------------------------------------------------------------"

    sudo curl -L "https://github.com/docker/compose/releases/download/$(export ORA_BENCH_VERSION_DOCKER_COMPOSE)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

echo "--------------------------------------------------------------------------------"
echo "Install Erlang"
echo "--------------------------------------------------------------------------------"

wget --quiet https://packages.erlang-solutions.com/erlang-solutions_${ORA_BENCH_VERSION_ERLANG_SOLUTIONS}_all.deb
sudo dpkg -i erlang-solutions_${ORA_BENCH_VERSION_ERLANG_SOLUTIONS}_all.deb
sudo apt update
sudo apt-get -qy install esl-erlang
rm erlang-solutions_${ORA_BENCH_VERSION_ERLANG_SOLUTIONS}_all.deb

echo "--------------------------------------------------------------------------------"
echo "Install Elixir"
echo "--------------------------------------------------------------------------------"

sudo mix local.hex --force
sudo mix local.rebar --force

echo "--------------------------------------------------------------------------------"
echo "Install Git"
echo "--------------------------------------------------------------------------------"

sudo add-apt-repository ppa:git-core/ppa --yes
sudo apt update
sudo apt -qy install git
sudo git config --global credential.helper 'cache --timeout 3600'

echo "--------------------------------------------------------------------------------"
echo "Install Go - Version ${ORA_BENCH_VERSION_GO}"
echo "--------------------------------------------------------------------------------"

wget --quiet https://dl.google.com/go/go${ORA_BENCH_VERSION_GO}.linux-amd64.tar.gz
sudo tar -xf go${ORA_BENCH_VERSION_GO}.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo mv go /usr/local

rm -rf go${ORA_BENCH_VERSION_GO}.linux-amd64.tar.gz
eval echo 'export GOPATH=/ora_bench/src_go/go' >> ~/.bashrc
eval echo 'export GOROOT=/usr/local/go' >> ~/.bashrc
export PATH=/usr/local/go/bin:${PATH}

echo "--------------------------------------------------------------------------------"
echo "Install Java SE Development Kit - Version ${ORA_BENCH_VERSION_JAVA}"
echo "--------------------------------------------------------------------------------"

(
    cd /
    sudo wget -quiet https://download.java.net/java/GA/jdk${ORA_BENCH_VERSION_JAVA}/779bf45e88a44cbd9ea6621d33e33db1/36/GPL/openjdk-${ORA_BENCH_VERSION_JAVA}_linux-x64_bin.tar.gz
    sudo tar -xf openjdk-${ORA_BENCH_VERSION_JAVA}_linux-x64_bin.tar.gz
    sudo rm -rf /opt/jdk-${ORA_BENCH_VERSION_JAVA}
    sudo mv jdk-${ORA_BENCH_VERSION_JAVA} /opt/
    sudo rm -rf openjdk-${ORA_BENCH_VERSION_JAVA}_linux-x64_bin.tar.gz
)

eval echo 'export JAVA_HOME=/opt/jdk-${ORA_BENCH_VERSION_JAVA}' >> ~/.bashrc
export PATH=/opt/jdk-${ORA_BENCH_VERSION_JAVA}/bin:${PATH}

echo "--------------------------------------------------------------------------------"
echo "Install Gradle - Version ${ORA_BENCH_VERSION_GRADLE}"
echo "--------------------------------------------------------------------------------"

wget --quiet https://services.gradle.org/distributions/gradle-${ORA_BENCH_VERSION_GRADLE}-bin.zip -P /tmp
sudo unzip -o -d /opt/gradle /tmp/gradle-*.zip
eval echo 'export GRADLE_HOME=/opt/gradle/gradle-${ORA_BENCH_VERSION_GRADLE}' >> ~/.bashrc
export PATH=/opt/gradle/gradle-${ORA_BENCH_VERSION_GRADLE}/bin:${PATH}

echo "--------------------------------------------------------------------------------"
echo "Install Kotlin"
echo "--------------------------------------------------------------------------------"

curl -s https://get.sdkman.io | bash
chmod a+x "$HOME/.sdkman/bin/sdkman-init.sh"
source "$HOME/.sdkman/bin/sdkman-init.sh"
if [ ! -z "${ORA_BENCH_VERSION_KOTLIN}" ]; then
    sdk uninstall kotlin ${ORA_BENCH_VERSION_KOTLIN}
fi
sdk install kotlin
echo kotlin=$PATH

echo "--------------------------------------------------------------------------------"
echo "Install Oracle Instant Client - Version ${ORA_BENCH_VERSION_ORACLE_INSTANT_CLIENT_1}.${ORA_BENCH_VERSION_ORACLE_INSTANT_CLIENT_2}.0.0.0"
echo "--------------------------------------------------------------------------------"

(
    cd /
    sudo rm -rf oracle-instantclient${ORA_BENCH_VERSION_ORACLE_INSTANT_CLIENT_1}.${ORA_BENCH_VERSION_ORACLE_INSTANT_CLIENT_2}-basic-${ORA_BENCH_VERSION_ORACLE_INSTANT_CLIENT_1}.${ORA_BENCH_VERSION_ORACLE_INSTANT_CLIENT_2}.0.0.0
    sudo wget --quiet https://download.oracle.com/otn_software/linux/instantclient/${ORA_BENCH_VERSION_ORACLE_INSTANT_CLIENT_1}${ORA_BENCH_VERSION_ORACLE_INSTANT_CLIENT_2}00/oracle-instantclient${ORA_BENCH_VERSION_ORACLE_INSTANT_CLIENT_1}.${ORA_BENCH_VERSION_ORACLE_INSTANT_CLIENT_2}-basic-${ORA_BENCH_VERSION_ORACLE_INSTANT_CLIENT_1}.${ORA_BENCH_VERSION_ORACLE_INSTANT_CLIENT_2}.0.0.0-1.x86_64.rpm
    sudo wget --quiet https://download.oracle.com/otn_software/linux/instantclient/${ORA_BENCH_VERSION_ORACLE_INSTANT_CLIENT_1}${ORA_BENCH_VERSION_ORACLE_INSTANT_CLIENT_2}00/oracle-instantclient${ORA_BENCH_VERSION_ORACLE_INSTANT_CLIENT_1}.${ORA_BENCH_VERSION_ORACLE_INSTANT_CLIENT_2}-sqlplus-${ORA_BENCH_VERSION_ORACLE_INSTANT_CLIENT_1}.${ORA_BENCH_VERSION_ORACLE_INSTANT_CLIENT_2}.0.0.0-1.x86_64.rpm
    sudo alien -i *.rpm
    sudo rm -rf *.x86_64.rpm
)

eval echo 'export ORACLE_HOME=/usr/lib/oracle/${ORA_BENCH_VERSION_ORACLE_INSTANT_CLIENT_1}.${ORA_BENCH_VERSION_ORACLE_INSTANT_CLIENT_2}/client64' >> ~/.bashrc
eval echo 'export LD_LIBRARY_PATH=/usr/lib/oracle/${ORA_BENCH_VERSION_ORACLE_INSTANT_CLIENT_1}.${ORA_BENCH_VERSION_ORACLE_INSTANT_CLIENT_2}/client64/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
export PATH=/usr/lib/oracle/${ORA_BENCH_VERSION_ORACLE_INSTANT_CLIENT_1}.${ORA_BENCH_VERSION_ORACLE_INSTANT_CLIENT_2}/client64:${PATH}

echo "--------------------------------------------------------------------------------"
echo "Install Python3"
echo "--------------------------------------------------------------------------------"

(
    cd /
    sudo rm -rf /usr/bin/python
    sudo apt install -qy python3
    sudo apt install -qy python3-venv
    sudo ln -s /usr/bin/python3 /usr/bin/python
    sudo wget --quiet https://bootstrap.pypa.io/get-pip.py
    sudo python3 get-pip.py
)

python3 -m pip install -r src_python/requirements.txt

echo "--------------------------------------------------------------------------------"
echo "Install rebar3"
echo "--------------------------------------------------------------------------------"

(
    cd /
    sudo rm -rf /usr/bin/rebar3
    sudo wget --quiet https://s3.amazonaws.com/rebar3/rebar3
    sudo chmod +x rebar3
    sudo mv rebar3 /usr/bin
)

echo "--------------------------------------------------------------------------------"
echo "Customizing the repository"
echo "--------------------------------------------------------------------------------"

sudo chmod +x *.sh
sudo chmod +x */*.sh
sudo chmod +x */*/*.sh

sudo sudo dos2unix *.sh
sudo dos2unix */*.sh
sudo dos2unix */*/*.sh

eval echo 'export PATH=${PATH}' >> ~/.bashrc
. ~/.bashrc

echo "=====================================================================> Environment variable LANG: "
echo $LANG
echo "=====================================================================> Environment variable LANGUAGE: "
echo $LANGUAGE
echo "=====================================================================> Environment variable LC_ALL: "
echo $LC_ALL

echo "=====================================================================> Version  Alien: "
if ! alien --version; then
    exit 255
fi

echo "=====================================================================> Version  Autoconf: "
if ! autoconf -V; then
    exit 255
fi

echo "=====================================================================> Version  Automake: "
if ! automake --version; then
    exit 255
fi

echo "=====================================================================> Version  CMake: "
if ! cmake --version; then
    exit 255
fi

echo "=====================================================================> Version  cURL: "
if ! curl --version; then
    exit 255
fi

echo "=====================================================================> Version  Docker: "
if ! docker version; then
    exit 255
fi

echo "=====================================================================> Version  dos2unix: "
if ! dos2unix --version; then
    exit 255
fi

echo "=====================================================================> Version  Elixir: "
if ! elixir -v; then
    exit 255
fi
if ! mix --version; then
    exit 255
fi

echo "=====================================================================> Version  GCC: "
if ! gcc --version; then
    exit 255
fi

echo "=====================================================================> Version  Git: "
if ! git --version; then
    exit 255
fi

echo "=====================================================================> Version  Go: "
if ! go version; then
    exit 255
fi
if ! go env; then
    exit 255
fi

echo "=====================================================================> Version  Java: "
if ! java -version; then
    exit 255
fi

echo "=====================================================================> Version  Gradle: "
if ! gradle --version; then
    exit 255
fi

echo "=====================================================================> Version  Kotlin: "
if ! kotlin -version; then
    exit 255
fi

echo "=====================================================================> Version  Oracle Instant Client: "
if ! sqlplus -V; then
    exit 255
fi

echo "=====================================================================> Version  Python3: "
if ! python3 --version; then
    exit 255
fi

echo "=====================================================================> Version  rebar3: "
if ! rebar3 version; then
    exit 255
fi

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"

exit
