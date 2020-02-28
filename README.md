# ora_bench - Benchmark Framework for Oracle Database Drivers.

![Travis (.org)](https://img.shields.io/travis/KonnexionsGmbH/ora_bench.svg?branch=master)
![GitHub](https://img.shields.io/github/license/KonnexionsGmbH/ora_bench.svg)
![GitHub release](https://img.shields.io/github/release/KonnexionsGmbH/ora_bench.svg)
![GitHub Release Date](https://img.shields.io/github/release-date/KonnexionsGmbH/ora_bench.svg)
![GitHub commits since latest release](https://img.shields.io/github/commits-since/KonnexionsGmbH/ora_bench/1.0.0.svg)

----

### Table of Contents

**[1. Introduction](#introduction)**<br>
**[2. Framework Tools](#framework_tools)**<br>
**[3. Coding Pattern](#coding_pattern)**<br>
**[4. Driver Specific Features](#driver_specifica)**<br>
**[5. Reporting](#reporting)**<br>
**[6. Docker](#docker)**<br>
**[7. Contributing](#contributing)**<br>

----

## <a name="introduction"></a> 1 Introduction

**ora_bench** can be used to determine the performance of different Oracle database drivers under identical conditions.
The framework parameters for a benchmark run are stored in a central configuration file.

The currently supported database drivers are:

| Driver    | Programming Languages |
| :---      | :--- |
| cx_Oracle | Python                |
| JamDB     | Erlang                |
| JDBC      | Java                  |
| ODPI      | C                     |
| oranif    | Elixir &amp; Erlang   |

The following Oracle database versions are provided in a benchmark run via Docker container:

| Shortcut   | Oracle Database Version |
| :---       | :--- |
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

- the configuration file `priv/ora_bench_c.propperties` for C,
- the configuration file `priv/ora_bench_erlang.properties` with a corresponding map for Erlang, and
- the configuration file `priv/ora_bench_python.propperties` for Python.

All the file names specified here are also part of the configuration file and can be changed if necessary.

### 2.2 Benchmark Execution

#### 2.2.1 Locally

##### 2.2.1.1 System Requirements

##### 2.2.1.1.1 Windows Platform

- Docker Desktop for Windows from [here](https://www.docker.com/products/docker-desktop)

- Make for Windows from [here](http://gnuwin32.sourceforge.net/packages/make.htm)

- Oracle Instant Client from [here](https://www.oracle.com/database/technologies/instant-client/winx64-64-downloads.html)

- Erlang from [here](https://www.erlang.org/downloads/)
- Elixir from [here](https://elixir-lang.org/install.html#windows)

- Java SE Development Kit, e.g. Version 11 from [here](https://www.oracle.com/technetwork/java/javase/downloads/jdk11-downloads-5066655.html)

- Gradle from [here](https://www.python.org/downloads/) 

- Python 3 from [here](https://www.python.org/downloads/)

##### 2.2.1.1.2 Windows Subsystem for Linux (WSL 2 and Ubuntu 18.04 LTS)

See [here](docs/requirements_windows_wsl_2_ubuntu_18.04_lts.md).

##### 2.2.1.1.3 Linux Platform

- Oracle Instant Client, e.g.
    - `sudo apt-get install alien`
    - `sudo alien priv/oracle/oracle-instantclient19.3-basiclite-19.3.0.0.0-1.x86_64.rpm`
    - `sudo dpkg -i oracle-instantclient19.3-basiclite_19.3.0.0.0-2_amd64.deb`

- Erlang
    - `sudo apt -y install erlang`
- Elixir
    - `sudo apt install elixir`
    - `mix local.hex`

- Java SE Development Kit, e.g.
    - `sudo apt install default-jdk`

- Gradle, e.g.
    - `wget https://services.gradle.org/distributions/gradle-6.2-bin.zip -P /tmp`  
    - `sudo unzip -d /opt/gradle /tmp/gradle-*.zip`
    - `export GRADLE_HOME=/opt/gradle/gradle-6.2`
    - `export PATH=${GRADLE_HOME}/bin:${PATH}`

- Python 3, e.g.:
    - `sudo apt install software-properties-common`
    - `sudo add-apt-repository -y ppa:deadsnakes/ppa`
    - `sudo apt install python3`
    - `sudo apt install python3-venv`
    - `python3 -m venv my-project-env`
    - `source my-project-env/bin/activate`

##### 2.2.1.1.4 Platform-independent Installation

- Install [cx_Oracle](https://oracle.github.io/python-cx_Oracle/):
    - `python -m pip install --upgrade pip`
    - `python -m pip install --upgrade cx_Oracle`

##### 2.2.1.2 `run_bench_all_dbs_props_std`

This script executes the `run_db_setup_benchmark_props_std` script for each of the databases listed in chapter [Introduction](#introduction) with standard properties.
At the beginning of the script it is possible to exclude individual databases or drivers from the current benchmark.
The run log is stored in the `run_bench_all_dbs_props_std.log` file.

##### 2.2.1.3 `run_bench_all_dbs_props_var`

This script executes the `run_db_setup_benchmark_props_var` script for each of the databases listed in chapter [Introduction](#introduction) with variations of properties.
At the beginning of the script it is possible to exclude individual databases or drivers from the current benchmark.
The run log is stored in the `run_bench_all_dbs_props_var.log` file.

##### 2.2.1.4 `run_bench_all_drivers`

This script executes the following driver specific sub-scripts:

- `run_bench_cx_oracle`
- `run_bench_jamdb_oracle`
- `run_bench_jdbc`
- `run_bench_odpi`
- `run_bench_oranif`

The possible exclusion of drivers made before is taken into account.

##### 2.2.1.5 `run_create_bulk_file`

This scripts is used to create a bulk file (see chapter 2.4).

##### 2.2.1.6 `run_create_image_ora_bench_dev`

This script creates the Docker image `ora_bench_dev` based on `Ubuntu 19.10`.
The script performs the following tasks:

1. A possibly running Docker container `ora_bench_dev` is stopped and deleted. 
2. A locally existing Docker image `ora_bench_dev` is deleted. 
3. A new Docker image `ora_bench_dev` is created based on the Docker file in the directory `priv\docker`.
4. The new Docker image `ora_bench_dev` is tagged as `konnexionsgmbh/ora_bench_dev` tag.
5. Then the new Docker image is loaded into the Docker Hub.
6. Subsequently, any locally existing dangling Docker images are deleted.
7. Finally the Docker container `ora_bench_dev` is created.

The run log is stored in the `run_create_image_ora_bench_dev.log` file.

##### 2.2.1.7 `run_db_setup_benchmark_props_std`

This script is executed for one of the databases listed in in chapter [Introduction](#introduction) with standard properties. 
The script performs the following tasks:

1. Depending on the selected drivers, any necessary compilations for the programming languages C, Elixir and Erlang are performed.
2. A possibly running Docker container is stopped and deleted. 
3. The Docker container for the selected database version is started.
4. Then the database is prepared for the benchmark run with the following steps:

  - If not yet available, create the database user according to the parameters `connection.user` and `connection.password`.
  - Grant this database user the following rights:

    - `ALTER SYSTEM`.
    - `CREATE PROCEDURE`
    - `CREATE SESSION`
    - `CREATE TABLE`
    - `UNLIMITED TABLESPACE`

5. Finally the following sub-script `run_bench_all_drivers` is running.

##### 2.2.1.8 `run_db_setup_benchmark_props_var`

This script is executed for one of the databases listed in in chapter [Introduction](#introduction). 
The script performs the following tasks:

1. Depending on the selected drivers, any necessary compilations for the programming languages C, Elixir and Erlang are performed.
2. A possibly running Docker container is stopped and deleted. 
3. The Docker container for the selected database version is started.
4. Then the database is prepared for the benchmark run with the following steps:

  - If not yet available, create the database user according to the parameters `connection.user` and `connection.password`.
  - Grant this database user the following rights:

    - `ALTER SYSTEM`.
    - `CREATE PROCEDURE`
    - `CREATE SESSION`
    - `CREATE TABLE`
    - `UNLIMITED TABLESPACE`

5. Finally the sub-script `run_bench_all_drivers` is running for each of the following parameter combinations:

| batch.size    | core.multiplier | transaction.size | 
| :---          | :---            | :---             | 
| default value | default value   | default value    |
| default value | 1               | default value    |
| 0             | default value   | default value    |
| 0             | default value   | 0                |
| 0             | 1               | default value    |
| 0             | 1               | 0                |


##### 2.2.1.9 `run_finalise_benchmark`

In this script, OraBench.java is used to reset the following configuration parameters to the value 'n/a':

- `benchmark.comment`
- `benchmark.database`
- `benchmark.driver`
- `benchmark.host.name`
- `benchmark.id`
- `benchmark.language`
- `benchmark.number.cores`
- `benchmark.os`
- `benchmark.user.name`
- `connection.service`
- `sql.create`

##### 2.2.1.10 `run_bench_<driver>_<programming language>`

The driver and programming language related scripts, such as `run_bench_jdbc` in the `src_java` directory, 
first execute the insert statements and then the select statements in each trial with the data from the bulk file.
The time consumed is captured and recorded in result files.

#### 2.2.2 Travis CI

In Travis CI, the following two environment variables are defined per build for each of the databases listed in chapter [Introduction](#introduction):

- `ORA_BENCH_BENCHMARK_DATABASE`

In each build the following tasks are performed:

1. Installation of Elixir, Erlang, Java, Oracle Instant Client and Python.
2. Creation of the bulk file with the script `run_create_bulk_file`.
3. Execution of the `run_db_setup_benchmark_props_var`sub-script.
4. Storing the measurement results in the branch `gh-pages`.

### 2.3 Benchmark Results

In a file defined by the configuration parameters `file.result.delimiter`, `file.result.header` and `file.result.name`, the results of the benchmark run with the actions `benchmark`, `trial` and `query` are stored.
If the result file does not yet exist, a new result file is created. 
Otherwise, the new current results are appended to existing results. 

| Column            | Format                          | Content |
| :---              | :---                            | :--- |
| release           | alphanumeric                    | config param `benchmark.release` |
| benchmark id      | alphanumeric                    | config param `benchmark.id` |
| benchmark comment | alphanumeric                    | config param `benchmark.comment` |
| host name         | alphanumeric                    | config param `benchmark.host.name` |
| no. cores         | integer                         | config param `benchmark.number.cores` |
| os                | alphanumeric                    | config param `benchmark.os` |
| user name         | alphanumeric                    | config param `benchmark.user.name` |
| database          | alphanumeric                    | config param `benchmark.database` |
| language          | alphanumeric                    | config param `benchmark.language` |
| driver            | alphanumeric                    | config param `benchmark.driver` |
| trial no.         | integer                         | `0` if action equals `benchmark`, trial no. otherwise |
| SQL statement     | alphanumeric                    | SQL statement if action equals `query`, empty otherwise |
| core multiplier   | integer                         | config param `benchmark.core.multiplier` |
| fetch size        | integer                         | config param `connection.fetch.size` |
| transaction size  | integer                         | config param `benchmark.transaction.size` |
| bulk length       | integer                         | config param `file.bulk.length` |
| bulk size         | integer                         | config param `file.bulk.size` |
| batch size        | integer                         | config param `benchmark.batch.size` |
| action            | alphanumeric                    | one of `benchmark`, `query` or `trial`   |
| start day time    | yyyy-mm-dd hh24:mi:ss.fffffffff | current date and time at the start of the action |
| end day time      | yyyy-mm-dd hh24:mi:ss.fffffffff | current date and time at the end of the action |
| duration (sec)    | integer                         | time difference in seconds between start time and end time of the action |
| duration (ns)     | integer                         | time difference in nanoseconds between start time and end time of the action |
 
### 2.4 Bulk File

The bulk file in `csv` or `tsv` format is created in the `run_create_bulk_file` script if it does not already exist. 
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
        READ the bulk file data into the partitioned collection bulk_data_partitions (config param 'file.bulk.name')
            partition key = modulo (ASCII value of 1st byte of key * 256 + ASCII value of 2nd byte of key, 
                                    number partitions (config param 'benchmark.number.partitions'))
        Create a separate database connection (without auto commit behaviour) for each partition                            
        
        trial_no = 0
        WHILE trial_no < config_param 'benchmark.trials'
            DO run_benchmark_trial(database connections, trial_no, bulk_data_partitions)
        ENDWHILE    
        
        partition_no = 0
        WHILE partition_no < config_param 'benchmark.number.partitions'
            close the database connection
        ENDWHILE    
        
        WRITE an entry for the action 'benchmark' in the result file (config param 'file.result.name')
```


### 3.2 `Trial Function`

```
    run_trial(database connections, trial_no, bulk_data_partitions)
    INPUT: the database connections
           the current trial number
           the partitioned bulk data
    
        save the current time as the start of the 'trial' action
    
        create the database table (config param 'sql.create')
        
        IF error
            drop the database table (config param 'sql.drop')
            create the database table (config param 'sql.create')
        ENDIF    
        
        DO run_benchmark_insert(database connections, trial_no, bulk_data_partitions)
        DO run_benchmark_select(database connections, trial_no, bulk_data_partitions)
        
        drop the database table (config param 'sql.drop')
        
        WRITE an entry for the action 'trial' in the result file (config param 'file.result.name')
```

### 3.3 `Insert Control Function`

```
    run_insert(database connections, trial_no, bulk_data_partitions)
    INPUT: the database connections
           the current trial number
           the partitioned bulk data
    
        save the current time as the start of the 'query' action
     
        partition_no = 0
        WHILE partition_no < config_param 'benchmark.number.partitions'
            IF config_param 'benchmark.core.multiplier' = 0
                DO Insert(database connections(partition_no), bulk_data_partitions(partition_no)) 
            ELSE    
                DO Insert(database connections(partition_no), bulk_data_partitions(partition_no)) as a thread
        ENDWHILE    

        WRITE an entry for the action 'query' in the result file (config param 'file.result.name')
```

### 3.4 `Insert Function`

```
    insert(database connection, bulk_data_partition)
    INPUT: the database connection
           the bulk data partition
    
        count = 0
        collection batch_collection = empty
        
        WHILE iterating through the collection bulk_data_partition
            count + 1
            
            add the SQL statement in config param 'sql.insert' with the current bulk_data entry to the collection batch_collection 
            IF config_param 'benchmark.batch.size' > 0
                IF count modulo config param 'benchmark.batch.size' = 0 
                    execute the SQL statements in the collection batch_collection
                    batch_collection = empty
                ENDIF                    
            END IF
            
            IF config param 'benchmark.transaction.size' > 0 AND count modulo config param 'benchmark.transaction.size' = 0
                commit
            ENDIF    
        ENDWHILE

        IF collection batch_collection is not empty
            execute the SQL statements in the collection batch_collection
        ENDIF

        commit
```

### 3.5 `Select Control Function`

```
    run_select(database connections, trial_no, bulk_data_partitions)
    INPUT: the database connections
           the current trial number
           the partitioned bulk data
    
        save the current time as the start of the 'query' action
     
        partition_no = 0
        WHILE partition_no < config_param 'benchmark.number.partitions'
            IF config_param 'benchmark.core.multiplier' = 0
                DO Select(database connections(partition_no), bulk_data_partitions(partition_no, partition_no) 
            ELSE    
                DO Select(database connections(partition_no), bulk_data_partitions(partition_no, partition_no) as a thread
        ENDWHILE    

        WRITE an entry for the action 'query' in the result file (config param 'file.result.name')
```

### 3.6 `Select Function`

```
    run_select(database connection, bulk_data_partition, partition_no)
    INPUT: the database connection
           the bulk data partition
           the current partition number
    
        save the current time as the start of the 'query' action
     
        count = 0

        execute the SQL statement in config param 'sql.select' 

        WHILE iterating through the result set
            count + 1
        ENDWHILE

        IF NOT count = size(bulk_data_partition)
            display an error message            
        ENDIF                    
```

## 4 <a name="driver_specifica"></a> Driver Specific Features

### 4.1 cx_Oracle and Python

- the following data in the configuration parameters is determined at runtime: 
    - cx_Oracle version (`benchmark.driver`) and
    - Python version (`benchmark.language`). 
- all configuration parameters are managed by the program OraBench.java and made available in a suitable file (`file.configuration.name.python`) 
- Python uses for batch operations the `executemany` method of the `cursor` class for the operation `INSERT`
- the value fetch size (`connection.fetch.size`) is not used because the operation `SELECT` uses the operation `Cursor.fetchall()`

### 4.2 JDBC and Java

- the following data in the configuration parameters is determined at runtime: 
    - JDBC version (`benchmark.driver`),
    - benchmark identifier (`benchmark.id`),
    - host name (`benchmark.host.name`), 
    - number of cores (`benchmark.number.cores`), 
    - JRE version (`benchmark.language`), 
    - operating system environment (`benchmark.os`), 
    - user name (`benchmark.user.name`) and 
    - SQL create statement (`sql.create`). 
- the Java source code is compiled with the help of Gradle
- Java uses the `PreparedStatement` class for the operations `INSERT` and `SELECT`
- Java uses for batch operations the `executeBatch` method of the `PreparedStatement` class for the operation `INSERT`

### 4.3 ODPI and C

- the following data in the configuration parameters is determined at runtime: 
    - ODPI version (`benchmark.driver`) and
    - C version (`benchmark.language`). 
- all configuration parameters are managed by the program OraBench.java and made available in a suitable file (`file.configuration.name.c`) 

### 4.4 oranif and Elixir

- the following data in the configuration parameters is determined at runtime: 
    - oranif version (`benchmark.driver`) and
    - Elixir version (`benchmark.language`). 

### 4.5 oranif and Erlang

- the following data in the configuration parameters is determined at runtime: 
    - oranif version (`benchmark.driver`) and
    - Erlang version (`benchmark.language`). 
- all configuration parameters are managed by the program OraBench.java and made available in a suitable file (`file.configuration.name.erlang`) 

### 4.6 godror and Go

- the following data in the configuration parameters is determined at runtime: 
    - godror version (`benchmark.driver`) and
    - Go version (`benchmark.language`). 
- all configuration parameters are managed by the program OraBench.java and made available in a suitable file (`file.configuration.name.json`) 

## 5 <a name="reporting"> Reporting

[see here](https://konnexionsgmbh.github.io/ora_bench/)

## 6 <a name="docker"></a> Docker

[see here](docker/README.md)

## 7. <a name="contributing"></a> Contributing

1. fork it
2. create your feature branch (`git checkout -b my-new-feature`)
3. commit your changes (`git commit -am 'Add some feature'`)
4. push to the branch (`git push origin my-new-feature`)
5. create a new pull request
