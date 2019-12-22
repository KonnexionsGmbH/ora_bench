# WSL 2 and Ubuntu 18.04 LTS

The version 2 of the Windows Subsystem for Linux (WSL 2) is only available in Windows 10 builds 18917 or higher.
The documentation for installing WSL 2 can be found [here](https://docs.microsoft.com/en-us/windows/wsl/wsl2-install).

The Linux distribution Ubuntu 18.04 LTS can be installed via the Microsoft Store.

## `ora_bench` specific installation work

Matrix for the dependency between driver & programming language and their specific installation steps.
The installation steps not mentioned here are always required.

| Driver & Programming Language | Specific Installation Steps |
| ---                           | ---                         |
| cx_Oracle & Python            | no. 4 and 5                 |

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

### 3 Installing Java

    sudo apt install default-jdk

### 4 Installing Python

    sudo apt-get install software-properties-common
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    
    sudo apt install python3
    
    sudo apt install python3-venv
    python3 -m venv _build/ora_bench-env
    source _build/ora_bench-env/bin/activate

### 5 Installing cx_Oracle

    sudo apt-get install python3-pip
    python3 -m pip install --upgrade cx_Oracle

### 6 Installing Oracle Instant Client for Linux x86-64 (64-bit)

    sudo apt-get install libaio1
    sudo sh -c "echo /opt/oracle/instantclient_19_3 > /etc/ld.so.conf.d/oracle-instantclient.conf"
    sudo ldconfig
    echo "export LD_LIBRARY_PATH=priv/oracle/instantclient-linux.x64/instantclient_19_5" >> ~/.bashrc && source ~/.bashrc
    sudo chmod +x priv/oracle/instantclient-linux.x64/instantclient_19_5/sqlplus

### 7 Installing the Build Essentials

    sudo apt-get install build-essential

### Fixing Possible Issues

#### Python compile error 'locale.Error: unsupported locale setting'

The missing locale is `de_DE.utf8`.

    export LC_ALL=C
    sudo dpkg-reconfigure locales
