#!/bin/bash

set -e

# ----------------------------------------------------------------------------------
#
# run_install_4_vm_wsl2_2.sh: Install a ora_bench_dev environment for Ubuntu 20.04 - Step 2.
#
# ------------------------------------------------------------------------------

export PWD_PREVIOUS="${PWD}"
cd ~/

echo " "
echo "Script $0 is now running"

export LOG_FILE=run_install_4_vm_wsl2_2.log

echo " "
echo "You can find the run log in the file ${LOG_FILE}"
echo " "

exec &> >(tee -i ${LOG_FILE}) 2>&1
sleep .1

echo "=============================================================================="
echo "Start $0"
echo "------------------------------------------------------------------------------"
echo "Install a ora_bench_dev environment for Ubuntu 20.04 - Step 2."
echo "------------------------------------------------------------------------------"
echo "HOST_ENVIRONMENT                  : ${HOST_ENVIRONMENT}"
echo "USER                              : ${USER}"
echo "------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "=============================================================================="
echo "Step: Install asdf - part 2"
echo "------------------------------------------------------------------------------"
echo " "
echo "Current version of asdf is: $(asdf --version)"
echo " "
echo "=============================================================================="



sudo rm -rf ~/.asdf/downloads/cmake
sudo rm -rf ~/.asdf/downloads/elixir
sudo rm -rf ~/.asdf/downloads/erlang
sudo rm -rf ~/.asdf/downloads/golang
sudo rm -rf ~/.asdf/downloads/gradle
sudo rm -rf ~/.asdf/downloads/java
sudo rm -rf ~/.asdf/downloads/julia
sudo rm -rf ~/.asdf/downloads/kotlin
sudo rm -rf ~/.asdf/downloads/python
sudo rm -rf ~/.asdf/downloads/rebar
sudo rm -rf ~/.asdf/downloads/rust
sudo rm -rf ~/.asdf/downloads/tmux
sudo rm -rf ~/.asdf/downloads/vim

sudo rm -rf ~/.asdf/installs/cmake
sudo rm -rf ~/.asdf/installs/elixir
sudo rm -rf ~/.asdf/installs/erlang
sudo rm -rf ~/.asdf/installs/golang
sudo rm -rf ~/.asdf/installs/gradle
sudo rm -rf ~/.asdf/installs/java
sudo rm -rf ~/.asdf/installs/julia
sudo rm -rf ~/.asdf/installs/kotlin
sudo rm -rf ~/.asdf/installs/python
sudo rm -rf ~/.asdf/installs/rebar
sudo rm -rf ~/.asdf/installs/rust
sudo rm -rf ~/.asdf/installs/tmux
sudo rm -rf ~/.asdf/installs/vim

sudo rm -rf ~/.asdf/plugins/cmake
sudo rm -rf ~/.asdf/plugins/elixir
sudo rm -rf ~/.asdf/plugins/erlang
sudo rm -rf ~/.asdf/plugins/golang
sudo rm -rf ~/.asdf/plugins/gradle
sudo rm -rf ~/.asdf/plugins/java
sudo rm -rf ~/.asdf/plugins/julia
sudo rm -rf ~/.asdf/plugins/kotlin
sudo rm -rf ~/.asdf/plugins/python
sudo rm -rf ~/.asdf/plugins/rebar
sudo rm -rf ~/.asdf/plugins/rust
sudo rm -rf ~/.asdf/plugins/tmux
sudo rm -rf ~/.asdf/plugins/vim

touch ~/.tool-versions
echo "=============================================================================="
echo "Step: Install CMake - Version ${VERSION_CMAKE}"
echo "------------------------------------------------------------------------------"
asdf plugin add cmake
asdf install cmake ${VERSION_CMAKE}
asdf global cmake ${VERSION_CMAKE}
echo " "
echo "=============================================================================> Version  CMake: "
echo " "
echo "Current version of CMake: $(cmake --version)"
echo " "
echo "=============================================================================="

echo "=============================================================================="
echo "Step: Install Erlang - Version ${VERSION_ERLANG}"
echo "------------------------------------------------------------------------------"
asdf plugin add erlang
asdf install erlang ${VERSION_ERLANG}
asdf global erlang ${VERSION_ERLANG}
echo " "
echo "=============================================================================> Version  Erlang: "
echo " "
echo "Current version of Erlang: $(erl -eval '{ok, Version} = file:read_file(filename:join([code:root_dir(), "releases", erlang:system_info(otp_release), "OTP_VERSION"])), io:fwrite(Version), halt().' -noshell)"
echo " "
echo "=============================================================================="

echo "------------------------------------------------------------------------------"
echo "Step: Install Go - Version ${VERSION_GO}"
echo "------------------------------------------------------------------------------"
asdf plugin add golang
asdf install golang ${VERSION_GO}
asdf global golang ${VERSION_GO}
echo " "
echo "=============================================================================> Environment Go: "
echo " "
echo "Go environment is: $(go env)"
echo " "
echo "=============================================================================> Version  Go: "
echo " "
echo "Current version of Go: $(go version)"
echo " "
echo "=============================================================================="

echo "=============================================================================="
echo "Step: Install Java SE Development Kit - Version ${VERSION_JAVA}"
echo "------------------------------------------------------------------------------"
asdf plugin add java
asdf install java ${VERSION_JAVA}
asdf global java ${VERSION_JAVA}
echo " "
echo "=============================================================================> Version  Java: "
echo " "
echo "Current version of Java SE Development Kit: $(java -version)"
echo " "
echo "=============================================================================="

echo "------------------------------------------------------------------------------"
echo "Step: Install Julia - Version ${VERSION_JULIA}"
echo "------------------------------------------------------------------------------"
asdf plugin add julia
asdf install julia ${VERSION_JULIA}
asdf global julia ${VERSION_JULIA}
echo " "
echo "=============================================================================> Version  Julia: "
echo " "
echo "Current version of Julia: $(julia -version)"
echo " "
echo "=============================================================================="

echo "------------------------------------------------------------------------------"
echo "Step: Install Python3 - Version ${VERSION_PYTHON}"
echo "------------------------------------------------------------------------------"
asdf plugin add python
asdf install python ${VERSION_PYTHON3}
asdf global python ${VERSION_PYTHON3}
echo "------------------------------------------------------------------------------"
echo "Step: Install pip"
echo "------------------------------------------------------------------------------"
wget --no-check-certificate -nv https://bootstrap.pypa.io/get-pip.py
python3 -m pip install --upgrade pip
python3 -m pip  install -r ~/kxn_install/config_python3/requirements.txt
sudo rm -f get-pip.py
echo " "
echo "=============================================================================> Version  Python3: "
echo " "
echo "Current version of Python3: $(python3 --version)"
echo " "
echo "Current version of pip: $(pip --version)"
echo " "
python3 -m pip freeze | egrep -i 'alpha-vantage|- cx-Oracle|fire|Keras|jupyter|matplotlib|notebook|numpy|pandas|pip|PyYAML|requests|scikit-learn|scipy|seaborn|statsmodels|tensorflow|Theano'
echo " "
echo "=============================================================================="

echo "------------------------------------------------------------------------------"
echo "Install Rust - Version ${VERSION_RUST}"
echo "------------------------------------------------------------------------------"
asdf plugin add rust
asdf install rust ${VERSION_RUST}
asdf global rust ${VERSION_RUST}
sudo curl -sSL https://sh.rustup.rs -sSf | sh -s -- -y
source ${HOME}/.cargo/env
echo " "
echo "=============================================================================> Version  Rust: "
echo " "
echo "Current version of Rust: $(rustc --version)"
echo " "
echo "=============================================================================="

echo "------------------------------------------------------------------------------"
echo "Step: Install tmux - Version ${VERSION_TMUX}"
echo "------------------------------------------------------------------------------"
asdf plugin add tmux
asdf install tmux ${VERSION_TMUX}
asdf global tmux ${VERSION_TMUX}
echo " "
echo "=============================================================================> Version  tmux: "
echo " "
echo "Current version of tmux: $(tmux -V)"
echo " "
echo "=============================================================================="


if [ "${HOST_ENVIRONMENT}" = "vm" ]; then
    echo "------------------------------------------------------------------------------"
    echo "Step: Install DBeaver - Version ${VERSION_DBEAVER}"
    echo "------------------------------------------------------------------------------"
    wget --quiet https://github.com/dbeaver/dbeaver/releases/download/${VERSION_DBEAVER}/dbeaver-ce-${VERSION_DBEAVER}-linux.gtk.x86_64.tar.gz
    sudo tar -xf dbeaver-ce-${VERSION_DBEAVER}-linux.gtk.x86_64.tar.gz
    sudo rm -rf ${HOME_DBEAVER}
    sudo cp -r dbeaver ${HOME_DBEAVER}
    sudo rm -rf dbeaver
    sudo rm -f dbeaver-ce-*.tar.gz
    echo " "
    echo "=============================================================================> Version  DBeaver: "
    echo " "
    echo "Current version of DBeaver: $(${HOME_DBEAVER}/dbeaver -help)"
    echo " "
    echo "=============================================================================="
fi

echo "------------------------------------------------------------------------------"
echo "Step: Install Eclipse - Version ${VERSION_ECLIPSE_1}/${VERSION_ECLIPSE_2}"
echo "------------------------------------------------------------------------------"
wget --quiet https://www.mirrorservice.org/sites/download.eclipse.org/eclipseMirror/technology/epp/downloads/release/${VERSION_ECLIPSE_1}/${VERSION_ECLIPSE_2}/eclipse-java-${VERSION_ECLIPSE_1}-${VERSION_ECLIPSE_2}-linux-gtk-x86_64.tar.gz
sudo tar -xf eclipse-java-${VERSION_ECLIPSE_1}-${VERSION_ECLIPSE_2}-linux-gtk-x86_64.tar.gz
sudo rm -rf ${HOME_ECLIPSE}
sudo cp -r eclipse ${HOME_ECLIPSE}
sudo rm -rf eclipse
sudo rm -f eclipse-*.tar.gz
cd ..
echo " "
echo "=============================================================================> Version  Eclipse: "
echo " "
echo "Current version of Eclipse: $(cat ${HOME_ECLIPSE}/configuration/config.ini | grep 'eclipse.buildId=')"
echo " "
echo "=============================================================================="

echo "------------------------------------------------------------------------------"
echo "Step: Install Elixir - Version ${VERSION_ELIXIR}"
echo "------------------------------------------------------------------------------"
asdf plugin add elixir
asdf install elixir ${VERSION_ELIXIR}
asdf global elixir ${VERSION_ELIXIR}
echo " "
echo "=============================================================================> Version  Elixir: "
echo " "
echo "Current version of Elixir: $(elixir -v)"
echo "Current version of Mix: $(mix --version)"
echo " "
echo "=============================================================================="

echo "------------------------------------------------------------------------------"
echo "Step: Install Gradle - Version ${VERSION_GRADLE}"
echo "------------------------------------------------------------------------------"
asdf plugin add gradle
asdf install gradle ${VERSION_GRADLE}
asdf global gradle ${VERSION_GRADLE}
echo " "
echo "=============================================================================> Version  Gradle: "
echo " "
echo "Current version of Gradle: $(gradle --version)"
echo " "
echo "=============================================================================="

echo "------------------------------------------------------------------------------"
echo "Step: Install Kotlin - Version ${VERSION_KOTLIN}"
echo "------------------------------------------------------------------------------"
asdf plugin add kotlin
asdf install kotlin ${VERSION_KOTLIN}
asdf global kotlin ${VERSION_KOTLIN}
echo " "
echo "=============================================================================> Version  Kotlin: "
echo " "
echo "Current version of Kotlin: $(kotlin -version)"
echo " "
echo "=============================================================================="

echo "------------------------------------------------------------------------------"
echo "Step: Install Rebar3 - Version ${VERSION_REBAR3}"
echo "------------------------------------------------------------------------------"
asdf plugin add rebar
asdf install rebar ${VERSION_REBAR3}
asdf global rebar ${VERSION_REBAR3}
echo " "
echo "=============================================================================> Version  Rebar3: "
echo " "
echo "Current version of Rebar3: $(rebar3 version)"
echo " "
echo "=============================================================================="

echo "------------------------------------------------------------------------------"
echo "Step: Cleanup"
echo "------------------------------------------------------------------------------"
sudo apt-get -qy autoremove
sudo rm -rf /tmp/*

cd "${PWD_PREVIOUS}"

echo "=============================================================================> Current Date: "
echo " "
date
echo " "
# Show Environment Variables -------------------------------------------------------
echo "=============================================================================> Environment variable LANG: "
echo " "
echo "${LANG}"
echo " "
echo "=============================================================================> Environment variable LANGUAGE: "
echo " "
echo "${LANGUAGE}"
echo " "
echo "=============================================================================> Environment variable LC_ALL: "
echo " "
echo "${LC_ALL}"
echo " "
echo "=============================================================================> Environment variable LD_LIBRARY_PATH: "
echo " "
echo ${LD_LIBRARY_PATH}
echo " "
echo "=============================================================================> Environment variable ORACLE_HOME: "
echo " "
echo ${ORACLE_HOME}
echo " "
echo "=============================================================================> Environment variable PATH: "
echo " "
echo "${PATH}"
echo " "
# Show component versions ----------------------------------------------------------
echo "=============================================================================> Components"
( /bin/bash ./run_version_check.sh )
echo " "
echo "------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "------------------------------------------------------------------------------"
echo "End   $0"
echo "=============================================================================="

exit 0
