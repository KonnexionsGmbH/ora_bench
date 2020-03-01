# WSL 2 and Ubuntu 18.04 LTS

The version 2 of the Windows Subsystem for Linux (WSL 2) is only available in Windows 10 builds 18917 or higher.
The documentation for installing WSL 2 can be found [here](https://docs.microsoft.com/en-us/windows/wsl/wsl2-install).

The Linux distribution Ubuntu 18.04 LTS can be installed via the Microsoft Store.

## Specific installation work for `ora_bench` 

### 1 Update of the Linux distribution Ubuntu

After starting WSL 2 you should change to the root directory of your local ora_bench repository:

    cd /mnt/.../ora_bench
    
Next the Linux distribution Ubuntu must be updated:

    sudo apt update
    sudo apt upgrade

### 2 Installing Docker

    sudo apt install docker.io
    
    sudo /etc/init.d/docker start
    echo "sudo /etc/init.d/docker start" >> ~/.bashrc && source ~/.bashrc
    
    sudo groupadd docker
    sudo gpasswd -a $USER docker
    newgrp docker 

### 3 Installing Oracle Instant Client for Linux x86-64 (64-bit)

    sudo apt-get install libaio1
    sudo sh -c "echo /opt/oracle/instantclient_${VERSION_ORACLE_INSTANT_CLIENT} > /etc/ld.so.conf.d/oracle-instantclient.conf"
    sudo ldconfig
    echo "export LD_LIBRARY_PATH=priv/oracle/instantclient-linux.x64/instantclient_${VERSION_ORACLE_INSTANT_CLIENT}" >> ~/.bashrc && source ~/.bashrc
    sudo chmod +x priv/oracle/instantclient-linux.x64/instantclient_${VERSION_ORACLE_INSTANT_CLIENT}/sqlplus

### 4 Installing the Build Essentials

    sudo apt-get install build-essential

### 5 Installing Programming Languages

#### 5.1 Installing Elixir (optional)

#### 5.1.1 without previous Erlang installation

    wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb
	sudo dpkg -i erlang-solutions_2.0_all.deb
	sudo apt-get update
	sudo apt-get install esl-erlang
	sudo apt-get install elixir

#### 5.1.2 with previous Erlang installation

    sudo apt-get install elixir

#### 5.2 Installing Erlang (optional)

    wget https://packages.erlang-solutions.com/erlang-solutions_${VERSION_ERLANG_SOLUTION}_all.deb
	sudo dpkg -i erlang-solutions_${VERSION_ERLANG_SOLUTION}_all.deb
	sudo apt-get update
	sudo apt-get install erlang

#### 5.3 Installing Go (optional)

    wget https://dl.google.com/go/go${VERSION_GO}.linux-amd64.tar.gz
    tar -xvf go${VERSION_GO}.linux-amd64.tar.gz
    mv go /usr/local
    export GOPATH=/ora_bench/src_go/go
    export GOROOT=/usr/local/go
    export PATH=${GOPATH}/bin:${GOROOT}/bin:${PATH}

#### 5.4 Installing Java

    sudo apt install default-jdk

#### 5.5 Installing Gradle (optional)

    wget https://services.gradle.org/distributions/gradle-${VERSION_GRADLE}-bin.zip -P /tmp  
    sudo unzip -d /opt/gradle /tmp/gradle-*.zip
    export GRADLE_HOME=/opt/gradle/gradle-${VERSION_GRADLE}
    export PATH=${GRADLE_HOME}/bin:${PATH}

#### 5.6 Installing Python (optional)

    sudo apt-get install software-properties-common
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    
    sudo apt install python3
    
    sudo apt install python3-venv
    python3 -m venv _build/ora_bench-env
    source _build/ora_bench-env/bin/activate

### 6 Installing Database Drivers (optional)

#### 6.1 Installing cx_Oracle

    sudo apt-get install python3-pip
    python3 -m pip install --upgrade cx_Oracle

## Fixing Possible Issues

### Python compile error: `locale.Error: unsupported locale setting`

The missing locale is `de_DE.utf8`.

    export LC_ALL=C
    sudo dpkg-reconfigure locales
