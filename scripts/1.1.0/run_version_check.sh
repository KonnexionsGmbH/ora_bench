#!/bin/bash

set -e

# ----------------------------------------------------------------------------------
#
# run_version_check.sh: Check the installed software versions.
#
# ----------------------------------------------------------------------------------

exec &> >(tee -i run_version_check.log) 2>&1
sleep .1

date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo " "
echo "=============================================================================> Version Alien: "
echo " "
echo "Current version of Alien: $(alien --version)"
echo " "
echo "=============================================================================> Version asdf: "
echo " "
echo "Current version of asdf: $(asdf --version)"
echo " "
echo "=============================================================================> Version CMake: "
echo " "
echo "Current version of CMake: $(cmake --version)"
echo " "
echo "=============================================================================> Version cURL: "
echo " "
echo "Current version of cURL: $(curl --version)"
echo " "
echo "=============================================================================> Version DBeaver: "
echo " "
echo "Current version of DBeaver: $(${HOME_DBEAVER}/dbeaver -help)"
echo " "
echo "=============================================================================> Version Docker Compose: "
echo " "
echo "Current version of Docker Compose: $(docker-compose version)"
echo " "
echo "=============================================================================> Version Docker Desktop: "
echo " "
echo "Current version of Docker Desktop: $(docker version)"
echo " "
echo "=============================================================================> Version dos2unix: "
echo " "
echo "Current version of dos2unix: $(dos2unix --version)"
echo " "
echo "=============================================================================> Version Eclipse: "
echo " "
echo "Current version of Eclipse: $(cat ${HOME_ECLIPSE}/configuration/config.ini | grep 'eclipse.buildId=')"
echo " "
echo "=============================================================================> Version Elixir "
echo " "
echo "Current version of Elixir: $(elixir -v)"
echo "Current version of Mix: $(mix --version)"
echo " "
echo "=============================================================================> Version Erlang: "
echo " "
echo "Current version of Erlang: $(erl -eval '{ok, Version} = file:read_file(filename:join([code:root_dir(), "releases", erlang:system_info(otp_release), "OTP_VERSION"])), io:fwrite(Version), halt().' -noshell)"
echo " "
echo "=============================================================================> Version GCC / G++: "
echo " "
echo "Current version of GCC: $(gcc --version)"
echo "Current version of G++: $(g++ --version)"
echo " "
echo "=============================================================================> Version Git: "
echo " "
echo "Current version of Git: $(git --version)"
echo " "
echo "=============================================================================> Version GNU Autoconf: "
echo " "
echo "Current version of GNU Autoconf: $(autoconf -V)"
echo " "
echo "=============================================================================> Version GNU Automake: "
echo " "
echo "Current version of GNU Automake: $(automake --version)"
echo " "
echo "=============================================================================> Version GNU Make: "
echo " "
echo "Current version of GNU Make: $(make --version)"
echo " "
echo "=============================================================================> Version Go: "
echo " "
echo "Current version of Go: $(go version)"
echo "Current version of Go environment is: $(go env)"
echo " "
echo "=============================================================================> Version Gradle: "
echo " "
echo "Current version of Gradle: $(gradle --version)"
echo " "
echo "=============================================================================> Version htop: "
echo " "
echo "Current version of htop: $(htop --version)"
echo " "
echo "=============================================================================> Version ImageMagick: "
echo " "
echo "Current version of ImageMagick: $(magick identify -version)"
echo " "
echo "=============================================================================> Version Java: "
echo " "
echo "Current version of Java SE Development Kit: $(java -version)"
echo " "
echo "=============================================================================> Version Julia: "
echo " "
echo "Current version of Julia: $(julia -version)"
echo " "
echo "=============================================================================> Version Kotlin: "
echo " "
echo "Current version of Kotlin: $(kotlin -version)"
echo " "
echo "=============================================================================> Version LCOV: "
echo " "
echo "Current version of LCOV: $(lcov --version)"
echo " "
echo "=============================================================================> Version nginx: "
echo " "
echo "Current version of nginx: $(nginx -v)"
echo " "
echo "=============================================================================> Version Node.js / npm: "
echo " "
echo "Current version of Node: $(node --version)"
echo "Current version of npm: $(npm --version)"
echo " "
echo "=============================================================================> Version ODBC: "
echo " "
echo "Current version of ODBC: $(odbcinst -j)"
echo " "
echo "=============================================================================> Version OpenSSL: "
echo " "
echo "Current version of OpenSSL: $(openssl version -a)"
echo " "
echo "=============================================================================> Version Oracle Instant Client: "
echo " "
echo "Current version of Oracle Instant Client: $(sqlplus -V)"
echo " "
echo "=============================================================================> Version procps: "
echo " "
echo "Current version of procps: $(ps --version)"
echo " "
echo "=============================================================================> Version Python3: "
echo " "
echo "Current version of Python3: $(python3 --version)"
echo " "
echo "Current version of pip3: $(pip3 --version || true)"
echo " "
# python3 -m pip freeze | egrep -i 'alpha-vantage|cx_oracle|fire|Keras|jupyter|matplotlib|notebook|numpy|pandas|pip|PyYAML|requests|scikit-learn|scipy|seaborn|statsmodels|tensorflow|Theano'
echo " "
echo "=============================================================================> Version R: "
echo " "
echo "Current version of R: $(R --version)"
echo "Current version of Rscript: $(Rscript ~/kxn_install/config_r/packageVersion.R)"
echo " "
echo "=============================================================================> Version rebar3: "
echo " "
echo "Current version of rebar3: $(rebar3 version)"
echo " "
echo "=============================================================================> Version RStudio: "
echo " "
echo "Current version of RStudio: $(rstudio --version)"
echo " "
echo "=============================================================================> Version Rust: "
echo " "
echo "Current version of Rust: $(rustc --version)"
echo " "
echo "=============================================================================> Version tmux: "
echo " "
echo "Current version of tmux: $(tmux -V)"
echo " "
echo "=============================================================================> Version Ubuntu: "
echo " "
echo "Current version of Ubuntu: $(lsb_release -a)"
echo " "
echo "=============================================================================> Version Vim: "
echo " "
echo "Current version of Vim: $(vim --version)"
echo " "
echo "=============================================================================> Version Wget: "
echo " "
echo "Current version of Wget: $(wget --version)"
echo " "
echo "=============================================================================> Version Wget2: "
echo " "
echo "Current version of Wget2: $(wget2 --version)"
echo " "
echo "=============================================================================> Version Yarn: "
echo " "
echo "Current version of Yarn: $(yarn --version)"
echo " "
echo "=============================================================================="

exit 0
