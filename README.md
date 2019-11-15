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

## <a name="framework_tools"></a> 2 Framework Tools

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

In a file defined by the configuration parameters `file.result.delimiter`, `file.result.header` and `file.result.name`, the detailed results of the benchmark run with the actions `benchmark`, `trial` and `query` are stored.

| Column | Format | Content |
| :--- | :--- | :--- |
| benchmark comment | alphanumeric  | config param `benchmark.comment` |
| environment | alphanumeric | config param `benchmark.environment` |
| database | alphanumeric | config param `benchmark.database` |
| module | alphanumeric |  the name of the benchmark module, e.g. OraBench.java |
| interface | alphanumeric |  the name of the database driver, e.g. JDBC |
| trial no. | integer | trial no. if action equals `trial` , `0` elsewise |
| SQL statement | alphanumeric | SQL statement if action equals `query` , empty elsewise |
| bulk length | integer | config param `file.bulk.length` |
| bulk size | integer | config param `file.bulk.size` |
| batch size | integer | config param `benchmark.batch.size` |
| action | alphanumeric | one of `benchmark`, `query` or `trial`   |
| start day time | yyyy.mm.dd hh24:mi:ss.ffffffff | current date and time at the start of the action |
| end day time | yyyy.mm.dd hh24:mi:ss.ffffffff | current date and time at the end of the action |
| duration (sec) | integer | time difference in seconds between start time and end time of the action |
| duration (ns) | integer | time difference in nanoseconds between start time and end time of the action |
 
#### 2.3.2 Statistical Results

In a file defined by the configuration parameters `file.summary.delimiter`, `file.summary.header` and `file.summary.name`, the statistical results of the benchmark run with the actions `query` are stored.

| Column | Format | Content |
| :--- | :--- | :--- |
| benchmark comment | alphanumeric  | config param `benchmark.comment` |
| environment | alphanumeric | config param `benchmark.environment` |
| database | alphanumeric | config param `benchmark.database` |
| module | alphanumeric |  the name of the benchmark module, e.g. OraBench.java |
| interface | alphanumeric |  the name of the database driver, e.g. JDBC |
| SQL statement | alphanumeric | SQL statement if action equals `query` , empty elsewise |
| bulk length | integer | config param `file.bulk.length` |
| bulk size | integer | config param `file.bulk.size` |
| batch size | integer | config param `benchmark.batch.size` |
| trials | integer | number of test runs within a benchmark run |
| start day time | yyyy.mm.dd hh24:mi:ss.ffffffff | current date and time at the start of the benchmark run |
| end day time | yyyy.mm.dd hh24:mi:ss.ffffffff | current date and time at the end of the benchmark run |
| average duration (ns) | integer | average time in nanoseconds to execute the SQL statement for all bulk data in a test run |
| average per SQL stmnt (ns) | integer | average time in nanoseconds to execute the SQL statement once |
| minimum duaration (ns) | integer | minimum time in nanoseconds to execute the SQL statement for all bulk data in a test run |
| maximum duartion (ns) | integer | maximum time in nanoseconds to execute the SQL statement for all bulk data in a test run |

## 3 <a name="coding_pattern"></a> Coding Pattern

### 3.1 `Benchmark Routine` (main routine)

1. load the configuration parameters (config params `file.configuration. ...`)
1. open the detailed results file (config params `file.result. ...`)
1. if the result file did not exist yet, then write a header line (config param `file.result.header`)
1. record the current time as the benchmark start
1. load the bulk data into the memory (config params `file.bulk. ...`)
1. establish the database connection (config params `connection. ...`)
1. execute the `Trial Routine` as often as defined in config param `benchmark.trials`
1. close the database connection
1. create the benchmark entry for the detailed results
1. close the detailed results file (config param `file.result.name`)
1. open the statistical results file (config params `file.summary. ...`)
1. if the statistical file did not exist yet, then write a header line (config param `file.summary.header`)
1. produce the statistical results
1. close the statistical results file (config param `file.summary.name`)
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
1. execute the SQL statement either in the config param `sql.insert.jamdb` or in the config param `sql.insert.oracle`for each record in the bulk file.
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

### 4.1 JDBC and Java

## 5 <a name="todo_list"></a> ToDo List

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

## 6. <a name="contributing"></a> Contributing

1. fork it
2. create your feature branch (`git checkout -b my-new-feature`)
3. commit your changes (`git commit -am 'Add some feature'`)
4. push to the branch (`git push origin my-new-feature`)
5. create a new pull request
