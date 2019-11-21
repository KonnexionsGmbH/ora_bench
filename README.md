# ora_bench - Benchmark Framework for Oracle Database Drivers.

----

### Table of Contents

**[1. Introduction](#introduction)**<br>
**[2. Framework Tools](#framework_tools)**<br>
**[3. Coding Pattern](#coding_pattern)**<br>
**[4. Driver Specific Features](#driver_specifica)**<br>
**[5. ToDo List](#todo_list)**<br>
**[6. Contributing](#contributing)**<br>

----

## <a name="introduction"></a> 1 Introduction

**ora_bench** can be used to determine the performance of different Oracle database drivers under identical conditions.
The framework parameters for a benchmark run are stored in a central configuration file.

The currently supported database drivers are:

| Driver | Programming Language |
| :--- | :--- |
| cx_Oracle | Python |
| JDBC | Java |

The following Oracle database versions are provided in a benchmark run via Docker Container:

| Shortcut | Oracle Database Version |
| :--- | :--- |
| db_11_2_xe | Oracle Database 11gR2 Express Edition for Linux x64 |
| db_12_2_ee | Oracle Database 12c Release 2 (12.2.0.1.0) - Enterprise Edition - Linux x86-64 |
| db_18_3_ee | Oracle Database 18c 18.3 - Linux x86-64 |
| db_19_3_ee | Oracle Database 19c 19.3 - Linux x86-64 |

The results of the benchmark runs are collected in either csv (comma-separated values) or tsv (tab-separated values) files.

## <a name="framework_tools"></a> 2 Framework Tools

### 2.1 Benchmark Configuration

The benchmark configuration file controls the execution and output of a benchmark run.
The default name for the configuration file is `priv/properties/ora_bench.properties`.
A detailed description of the configuration options can be found [here](docs/benchmark_configuration_parameter.md).
For reasons of convenience the following files are generated:

- the configuration file `priv/ora_bench_cx_oracle_pytzhon.ini` for cx_Oracle &amp; Python.
- the executable script `scripts/run_bench_oranif_c.sh` with corresponding environment variables for the oranif &amp; C, and
- the configuration file `priv/ora_bench_oranif_erlang.properties` with a corresponding map for oranif &amp; Erlang.

All the file names specified here are also part of the configuration file and can be changed if necessary.

### 2.2 Benchmark Execution

#### 2.2.1 Locally

##### 2.2.1.1 System Requirements

##### 2.2.1.1.1 Windows Platform

- Docker Desktop for Windows from [here](https://www.docker.com/products/docker-desktop)
- Java SE Development Kit, e.g. Version 11 from [here](https://www.oracle.com/technetwork/java/javase/downloads/jdk11-downloads-5066655.html)
- Make for Windows from [here](http://gnuwin32.sourceforge.net/packages/make.htm)
- Python 3 from [here](https://www.python.org/downloads/)

##### 2.2.1.1.2 Linux Platform

- Java SE Development Kit, e.g. `sudo apt install default-jdk`
- Oracle Instant Client, e.g.
    - `sudo apt-get install alien`
    - `sudo alien priv/oracle/oracle-instantclient19.3-basiclite-19.3.0.0.0-1.x86_64.rpm`
    - `sudo dpkg -i oracle-instantclient19.3-basiclite_19.3.0.0.0-2_amd64.deb`
- Python 3, e.g.:
    - `sudo apt install software-properties-common`
    - `sudo add-apt-repository -y ppa:deadsnakes/ppa`
    - `sudo apt install python3`
    - `sudo apt install python3-venv`
    - `python3 -m venv my-project-env`
    - `source my-project-env/bin/activate`

##### 2.2.1.1.3 Platform-independent Installation

- Install [cx_Oracle](https://oracle.github.io/python-cx_Oracle/):
    - `python -m pip install --upgrade pip`
    - `python -m pip install --upgrade cx_Oracle`

##### 2.2.1.2 `run_bench.sh`

This script executes the `run_bench_database.sh` script for each of the databases listed in chapter [Introduction](#introduction).
The run log is stored in the `run_bench.log` file.

##### 2.2.1.3 `run_bench_database.sh`

This script is executed for one of the databases listed in in chapter [Introduction](#introduction). 
First the corresponding Docker image is downloaded from the DockerHub, if not already available.
Then a Docker container is started.
Finally the following child scripts are running:

- `run_bench_setup.sh`
- all driver and programming language related scripts, like for example: `run_bench_jdbc_java.sh`
- `run_bench_finalise.sh`

##### 2.2.1.4 `run_bench_setup.sh`

This script prepares the database for the benchmark run including the following steps:

1. If not yet available, create the database user according to the parameters `connection.user` and `connection.password`.

2. Grant this database user the following rights:

- `ALTER SYSTEM`.
- `CREATE PROCEDURE`
- `CREATE SESSION`
- `CREATE TABLE`
- `UNLIMITED TABLESPACE`

OraBench.java is also used to create a bulk file (see chapter 2.4) if it does not already exist.

##### 2.2.1.5 `run_bench_<driver>_<programming language>.sh`

The driver and programming language related scripts, such as `run_bench_jdbc_java.sh`, first execute the insert statements and then the select statements in each trial with the bulk file.
The time consumed is captured and recorded in result files.

##### 2.2.1.6 `run_bench_finalise.sh`

In this script, OraBench.java is used to reset the following configuration parameters to the value 'n/a':

- `benchmark.comment`
- `benchmark.database`
- `benchmark.driver`
- `benchmark.environment`
- `benchmark.module`
- `connection.service`

#### 2.2.2 Travis CI

In Travis CI, the following two environment variables are defined per build for each of the databases listed in chapter [Introduction](#introduction):

- `ORA_BENCH_BENCHMARK_DATABASE`
- `ORA_BENCH_CONNECTION_SERVICE`

In each build the script `run_bench_database.sh` will be executed.
The results are uploaded to the repositopry at the end.

### 2.3 Benchmark Results

If the result files do not yet exist, new result files are created. Otherwise, the new current results are appended to existing results. 

#### 2.3.1 Detailed Results

In a file defined by the configuration parameters `file.result.detailed.delimiter`, `file.result.detailed.header` and `file.result.detailed.name`, the detailed results of the benchmark run with the actions `benchmark`, `trial` and `query` are stored.

| Column | Format | Content |
| :--- | :--- | :--- |
| benchmark comment | alphanumeric  | config param `benchmark.comment` |
| environment | alphanumeric | config param `benchmark.environment` |
| database | alphanumeric | config param `benchmark.database` |
| module | alphanumeric |  config param `benchmark.module` |
| driver | alphanumeric |  config param `benchmark.driver` |
| trial no. | integer | trial no. if action equals `trial` , `0` elsewise |
| SQL statement | alphanumeric | SQL statement if action equals `query` , empty elsewise |
| connection pool size | integer | config param `connection.pool.size` |
| transaction size | integer | config param `benchmark.transaction.size` |
| bulk length | integer | config param `file.bulk.length` |
| bulk size | integer | config param `file.bulk.size` |
| batch size | integer | config param `benchmark.batch.size` |
| action | alphanumeric | one of `benchmark`, `query` or `trial`   |
| start day time | yyyy.mm.dd hh24:mi:ss.ffffffff | current date and time at the start of the action |
| end day time | yyyy.mm.dd hh24:mi:ss.ffffffff | current date and time at the end of the action |
| duration (sec) | integer | time difference in seconds between start time and end time of the action |
| duration (ns) | integer | time difference in nanoseconds between start time and end time of the action |
 
#### 2.3.2 Statistical Results

In a file defined by the configuration parameters `file.result.statistical.delimiter`, `file.result.statistical.header` and `file.result.statistical.name`, the statistical results of the benchmark run with the actions `query` are stored.

| Column | Format | Content |
| :--- | :--- | :--- |
| benchmark comment | alphanumeric  | config param `benchmark.comment` |
| environment | alphanumeric | config param `benchmark.environment` |
| database | alphanumeric | config param `benchmark.database` |
| module | alphanumeric |  config param `benchmark.module` |
| driver | alphanumeric |  config param `benchmark.driver` |
| trials | integer | number of test runs within a benchmark run |
| SQL statement | alphanumeric | SQL statement if action equals `query` , empty elsewise |
| connection pool size | integer | config param `connection.pool.size` |
| transaction size | integer | config param `benchmark.transaction.size` |
| bulk length | integer | config param `file.bulk.length` |
| bulk size | integer | config param `file.bulk.size` |
| batch size | integer | config param `benchmark.batch.size` |
| start day time | yyyy.mm.dd hh24:mi:ss.ffffffff | current date and time at the start of the benchmark run |
| end day time | yyyy.mm.dd hh24:mi:ss.ffffffff | current date and time at the end of the benchmark run |
| mean duration (ns) | integer | mean time in nanoseconds to execute the SQL statement for all bulk data in a test run |
| mean time per SQL stmnt (ns) | integer | mean time in nanoseconds to execute the SQL statement once |
| minimum duaration (ns) | integer | minimum time in nanoseconds to execute the SQL statement for all bulk data in a test run |
| maximum duartion (ns) | integer | maximum time in nanoseconds to execute the SQL statement for all bulk data in a test run |

### 2.4 Bulk File

The bulk file in `csv` or `tsv` format is created in the `run_bench_setup.sh` script if it does not already exist. 
The following configuration parameters are taken into account:

- `file.bulk.delimiter`
- `file.bulk.header`
- `file.bulk.length`
- `file.bulk.name`
- `file.bulk.size`

The data column in the bulk file is randomly generated with a unique key column (MD5 hash code).

## 3 <a name="coding_pattern"></a> Coding Pattern

### 3.1 `Benchmark Routine` (main routine)

1. load the configuration parameters (config params `file.configuration. ...`)
1. open the detailed results file (config params `file.result.detailed. ...`)
1. if the result file did not exist yet, then write a header line (config param `file.result.detailed.header`)
1. record the current time as the benchmark start
1. load the bulk data into the memory (config params `file.bulk. ...`)
1. establish the database connection (config params `connection. ...`)
1. execute the `Trial Routine` as often as defined in config param `benchmark.trials`
1. close the database connection
1. create the benchmark entry for the detailed results
1. close the detailed results file (config param `file.result.detailed.name`)
1. open the statistical results file (config params `file.result.statistical. ...`)
1. if the statistical file did not exist yet, then write a header line (config param `file.result.statistical.header`)
1. produce the statistical results
1. close the statistical results file (config param `file.result.statistical.name`)
1. terminate the benchmark run

### 3.2 `Trial Routine`

1. record the current time as the trial start time
1. execute the SQL statement in the config param `sql.create` 
1. In case of error: Execute the SQL statement in the config param `sql.drop` and repeat step 2.
1. execute the `Insert Routine`
1. execute the `Select Routine`
1. execute the SQL statement in the config param `sql.drop` 
1. create the trial entry for the detailed results
1. terminate the trial run

### 3.2 `Insert Routine`

1. record the current time as the start of the query
1. execute the SQL statement in the config param `sql.insert` for each record in the bulk file whereby the following configuration parameters must be taken into account: `benchmark.batch.size`, `benchmark.transaction.size` and `connection.pool.size`.
1. create the query entry for the detailed results
1. save the average, maximum and minimum values for the statistical results
1. finish the query run

### 3.2 `Select Routine`

1. record the current time as the start of the query
1. execute the SQL statement in the config param `sql.select` for each record in the bulk file and compare the found value with the value in the bulk file for match. 
1. create the query entry for the detailed results
1. save the average, maximum and minimum values for the statistical results
1. finish the query run

## 4 <a name="driver_specifica"></a> Driver Specific Features

### 4.1 cx_Oracle and Python

- the following data in the configuration parameters is determined at runtime: operating system environment (`benchmark.environment`), the Python version (`benchmark.module`) and cx_Oracle version (`benchmark.driver`)
- Python uses for batch operations the `executemany` method of the `cursor` class for the operation `INSERT`

### 4.2 JDBC and Java

- the following data in the configuration parameters is determined at runtime: operating system environment (`benchmark.environment`), the JRE version (`benchmark.module`) and JDBC version (`benchmark.driver`)
- the Java source code is compiled with the help of a make file
- Java uses the `PreparedStatement` class for the operations `INSERT` and `SELECT`
- Java uses for batch operations the `executeBatch` method of the `PreparedStatement` class for the operation `INSERT`

## 5 <a name="todo_list"></a> ToDo List

| Completed  | Created    | Assignee | Task Description |
| :---:      | :---:      | :---     | :--- |
|            | 2019.11.05 | c_bik    | jamdb_erlang: new |
|            | 2019.11.05 | c_bik    | occi_c++: new |
|            | 2019.11.05 | c_bik    | odbc_erlang: new |
|            | 2019.11.05 | c_bik    | odpi-c_c: new |
|            | 2019.11.05 | c_bik    | oranif_erlang: new |
|  prio. 1   | 2019.11.21 | c_bik    | setup: define new c ini file format |
|  prio. 1   | 2019.11.21 | c_bik    | upload to GitHub from Travis CI: authentication method |
|  prio. 1   | 2019.11.21 | wwe      | all: detailed result file -> result file |
|  prio. 1   | 2019.11.21 | wwe      | all: new config param: benchmark.prefetch.size |
|  prio. 1   | 2019.11.21 | wwe      | all: new config params: benchmark.hostname & benchmark.username |
|  prio. 1   | 2019.11.21 | wwe      | all: remove statistical results file |
|  prio. 1   | 2019.11.21 | wwe      | all: result file - date format: yyyy-mm-dd hh24:mi:ss.ffffffff |
|  prio. 1   | 2019.11.21 | wwe      | documentation: pseudocode |
|  prio. 2   | 2019.11.19 | wwe      | cx_oracle_python: connection pooling |
|  prio. 2   | 2019.11.19 | wwe      | jdbc_java: connection pooling |
|  prio. 2   | 2019.11.21 | wwe      | setup: c script-> new c ini file |
|  prio. 3   | 2019.11.05 | wwe      | jdbc_java: multithreading |
|  prio. 3   | 2019.11.19 | wwe      | cx_oracle_python: multithreading |
|  prio. 4   | 2019.11.21 | wwe      | ecto_elixir: new |
| 2019.11.05 | 2019.11.05 | wwe      | jdbc_java: dynamic batchsize | 
| 2019.11.06 | 2019.11.05 | wwe      | all: separating key column and data column |
| 2019.11.06 | 2019.11.05 | wwe      | jdbc_java: finishing with summary report |
| 2019.11.07 | 2019.11.05 | wwe      | all: databases via docker containers |
| 2019.11.07 | 2019.11.05 | wwe      | jdbc_java: dynamic Oracle database version |
| 2019.11.08 | 2019.11.05 | wwe      | jdbc_java: generating language specific configuration files |
| 2019.11.12 | 2019.11.05 | wwe      | all: Travis/CI integration |
| 2019.11.17 | 2019.11.05 | wwe      | all: documentation |
| 2019.11.21 | 2019.11.05 | wwe      | cx_oracle_python: new |
| 2019.11.21 | 2019.11.19 | wwe      | cx_oracle_python: benchmark.batch.size = 0 |
| 2019.11.21 | 2019.11.19 | wwe      | cx_oracle_python: benchmark.transaction.size = 0 |
| 2019.11.21 | 2019.11.19 | wwe      | jdbc_java: benchmark.batch.size = 0 |
| 2019.11.21 | 2019.11.19 | wwe      | jdbc_java: benchmark.transaction.size = 0 |
| rejected   | 2019.11.05 | wwe      | all: partitioned table ??? |

## 6. <a name="contributing"></a> Contributing

1. fork it
2. create your feature branch (`git checkout -b my-new-feature`)
3. commit your changes (`git commit -am 'Add some feature'`)
4. push to the branch (`git push origin my-new-feature`)
5. create a new pull request
