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

In a file defined by the configuration parameters `file.result.delimiter`, `file.result.header` and `file.result.name`, the results of the benchmark run with the actions `benchmark`, `trial` and `query` are stored.
If the result file does not yet exist, a new result file is created. 
Otherwise, the new current results are appended to existing results. 

| Column | Format | Content |
| :--- | :--- | :--- |
| benchmark id | alphanumeric  | config param `benchmark.id` |
| benchmark comment | alphanumeric  | config param `benchmark.comment` |
| host name | alphanumeric | config param `benchmark.host.name` |
| os | alphanumeric | config param `benchmark.os` |
| user name | alphanumeric | config param `benchmark.user.name` |
| database | alphanumeric | config param `benchmark.database` |
| module | alphanumeric |  config param `benchmark.module` |
| driver | alphanumeric |  config param `benchmark.driver` |
| trial no. | integer | trial no. if action equals `trial` , `0` elsewise |
| SQL statement | alphanumeric | SQL statement if action equals `query` , empty elsewise |
| connection pool size | integer | config param `connection.pool.size` |
| fetch size | integer | config param `connection.fetch.size` |
| transaction size | integer | config param `benchmark.transaction.size` |
| bulk length | integer | config param `file.bulk.length` |
| bulk size | integer | config param `file.bulk.size` |
| batch size | integer | config param `benchmark.batch.size` |
| action | alphanumeric | one of `benchmark`, `query` or `trial`   |
| start day time | yyyy-mm-dd hh24:mi:ss.fffffffff | current date and time at the start of the action |
| end day time | yyyy-mm-dd hh24:mi:ss.fffffffff | current date and time at the end of the action |
| duration (sec) | integer | time difference in seconds between start time and end time of the action |
| duration (ns) | integer | time difference in nanoseconds between start time and end time of the action |
 
### 2.4 Bulk File

The bulk file in `csv` or `tsv` format is created in the `run_bench_setup.sh` script if it does not already exist. 
The following configuration parameters are taken into account:

- `file.bulk.delimiter`
- `file.bulk.header`
- `file.bulk.length`
- `file.bulk.name`
- `file.bulk.size`

The data column in the bulk file is randomly generated with a unique key column (MD5 hash code).

## 3 <a name="coding_pattern"></a> Coding Patterns

### 3.1 `Benchmark Function` (main function)

```
    run_benchmark()
    
        save the current time as the start of the 'benchmark' action
    
        READ the configuration parameters into the memory (config params `file.configuration.name ...`)
        READ the bulk file data into the collection bulk_data (config param 'file.bulk.name')
        
        connect to the database (config params 'connection. ...')
        switch off auto commit
        
        trial_no = 0
        WHILE trial_no < config_param 'benchmark.trials'
            DO run_benchmark_trial(trial_no)
        ENDWHILE    
        
        disconnect from the database
        
        WRITE an entry for the action 'benchmark' in the result file (config param 'file.result.name')
```


### 3.2 `Trial Function`

```
    run_benchmark_trial(trial_no)
    INPUT: the current trial number
    
        save the current time as the start of the 'trial' action
    
        create the database table (config param 'sql.create')
        
        IF error
            drop the database table (config param 'sql.drop')
            create the database table (config param 'sql.create')
        ENDIF    
        
        DO run_benchmark_insert(trial_no)
        DO run_benchmark_select(trial_no)
        
        drop the database table (config param 'sql.drop')
        
        WRITE an entry for the action 'trial' in the result file (config param 'file.result.name')
```

### 3.2 `Insert Function`

```
    run_benchmark_insert(trial_no)
    INPUT: the current trial number
    
        save the current time as the start of the 'query' action
     
        count = 0
        collection batch_collection = empty
        
        WHILE iterating through the collection bulk_data
            count + 1
            
            IF config_param 'benchmark.batch.size' = 0
                execute the SQL statement in config param 'sql.insert' with the current bulk_data entry 
            ELSE
                add the SQL statement in config param 'sql.insert' with the current bulk_data entry to the collection batch_collection 
                IF count modulo config param 'benchmark.batch.size' = 0 
                    execute the SQL statements in the collection batch_collection
                    batch_collection = empty
                ENDIF                    
            END IF
            
            IF config param 'benchmark.transaction.size' > 0 AND count modulo config param 'benchmark.transaction.size' = 0
                commit
            ENDIF    
        ENDWHILE

        IF config param 'benchmark.batch.size' > 0 AND collection batch_collection is not empty
            execute the SQL statements in the collection batch_collection
        ENDIF

        IF config param 'benchmark.transaction.size' > 0 AND NOT count modulo config param 'benchmark.transaction.size' = 0
            commit
        ENDIF

        WRITE an entry for the action 'query' in the result file (config param 'file.result.name')
```

### 3.2 `Select Function`

```
    run_benchmark_select(trial_no)
    INPUT: the current trial number
    
        save the current time as the start of the 'query' action
     
        WHILE iterating through the collection bulk_data
            execute the SQL statement in config param 'sql.select' with the key column of the current bulk_data entry 

            IF NOT result column of database operation = data column of the current bulk_data entry
                display an error message            
            ENDIF                    
        ENDWHILE

        WRITE an entry for the action 'query' in the result file (config param 'file.result.name')
```

## 4 <a name="driver_specifica"></a> Driver Specific Features

### 4.1 cx_Oracle and Python

- the following data in the configuration parameters is determined at runtime: operating system environment (`benchmark.environment`), the Python version (`benchmark.module`) and cx_Oracle version (`benchmark.driver`)
- Python uses for batch operations the `executemany` method of the `cursor` class for the operation `INSERT`
- the fetch size (`connection.fetch.size`) 
- the value fetch size (`connection.fetch.size`) is not used because the operation `SELECT` uses the operation `Cursor.fetchall()`

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
| 2019.11.21 | 2019.11.21 | wwe      | all: detailed result file -> result file |
| 2019.11.21 | 2019.11.21 | wwe      | all: new config param: connection.fetch.size |
| 2019.11.21 | 2019.11.21 | wwe      | all: new config params: benchmark.host.name, benchmark.id & benchmark.user.name |
| 2019.11.21 | 2019.11.21 | wwe      | all: remove statistical results file |
| 2019.11.21 | 2019.11.21 | wwe      | all: result file - date format: yyyy-mm-dd hh24:mi:ss.ffffffff |
| 2019.11.23 | 2019.11.21 | wwe      | documentation: pseudocode |
| rejected   | 2019.11.05 | wwe      | all: partitioned table ??? |

## 6. <a name="contributing"></a> Contributing

1. fork it
2. create your feature branch (`git checkout -b my-new-feature`)
3. commit your changes (`git commit -am 'Add some feature'`)
4. push to the branch (`git push origin my-new-feature`)
5. create a new pull request
