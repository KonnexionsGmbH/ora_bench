# ora_bench - Benchmark Framework for Oracle Database Drivers.

## 1 Introduction

**ora_bench** can be used to determine the performance of different Oracle database drivers under identical conditions.
The framework parameters for a benchmark run are stored in a central configuration file.

The currently supported database drivers are:

| Driver | Version | Programming Language | Version |
| :--- | :--- | :--- | :--- |
| JDBC | ojdbc10.jar| Java | 11.0.5 |

The following Oracle database versions are provided in a benchmark run via Docker Container:

| Shortcut | Oracle Database Version |
| :--- | :--- |
| db_11_2_xe | Oracle Database 11gR2 Express Edition for Linux x64 |
| db_12_2_ee | Oracle Database 12c Release 2 (12.2.0.1.0) - Enterprise Edition - Linux x86-64 |
| db_18_3_ee | Oracle Database 18c 18.3 - Linux x86-64 |
| db_19_3_ee | Oracle Database 19c 19.3 - Linux x86-64 |

The results of the benchmark runs are collected in either csv (comma-separated values) or tsv (tab-separated values) files.

## 2 Framework Tools

### 2.1 Benchmark Configuration

The benchmark configuration file controls the execution and output of the benchmark.
The default name for the configuration file is `priv/ora_bench.properties`.
A detailed description of the configuration options can be found [here](docs/benchmark_configuration_parameter.md).
For reasons of convenience the executable script `scripts/run_bench_c.sh` with corresponding environment variables is created for the programming language C and the configuration file `priv/ora_bench_erlang.properties` with a corresponding map is created for the programming language Erlang.
All the file names specified here are also part of the configuration file and can be changed if necessary.

### 2.2 Benchmark Execution

#### 2.2.1 Locally

#### 2.2.2 Travis CI

### 2.3 Benchmark Results

#### 2.3.1 Detailed Results

#### 2.3.2 Statistical Results

## 3 Coding Pattern

## 4 Driver Specific Features

## 5 ToDo List

| Completed | Created | Assigned | Task Description |
| :---: | :---: | :--- | :--- |
|  | 2019.11.05 | c_bik | C / odpi-c: new |
|  | 2019.11.05 | c_bik | C++ / occi: new |
|  | 2019.11.05 | c_bik | Erlang / JamDB : new |
|  | 2019.11.05 | c_bik | Erlang / odbc: new |
|  | 2019.11.05 | c_bik | Erlang / oranif: dynamic batchsize |
|  | 2019.11.05 | c_bik | Erlang / oranif: multithreading |
|  | 2019.11.05 | wwe | Java / JDBC: multithreading |
|  | 2019.11.05 | wwe | Overall: documentation |
|  | 2019.11.05 | wwe | Overall: partitioned table |
|  | 2019.11.05 | wwe | Python / cx_Oracle: new |
| 2019.11.05 | 2019.11.05 | wwe | Java / JDBC: dynamic batchsize | 
| 2019.11.06 | 2019.11.05 | wwe | Java: finishing with summary report |
| 2019.11.06 | 2019.11.05 | wwe | Overall: separating key column and data column |
| 2019.11.07 | 2019.11.05 | wwe | Java / JDBC: dynamic Oracle database version |
| 2019.11.07 | 2019.11.05 | wwe | Overall: databases via docker containers |
| 2019.11.08 | 2019.11.05 | wwe | Java: generating language specific configuration files |
| 2019.11.12 | 2019.11.05 | wwe | Overall: Travis/CI integration |

## 6. Contributing

1. fork it
2. create your feature branch (`git checkout -b my-new-feature`)
3. commit your changes (`git commit -am 'Add some feature'`)
4. push to the branch (`git push origin my-new-feature`)
5. create a new pull request
