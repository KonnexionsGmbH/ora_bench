# Benchmark Configuration Parameter

The following table contains all possible configuration parameters.
The `Parameter Name` column contains the parameter name as used in the configuration file.
The parameters with the default value 'n/a' must be defined at runtime. 
If the parameter can be overridden by an environment variable (column `Env.`) then this environment variable must have the prefix `ORA_BENCH_` and the dots in the `Parameter Name` must be replaced by underscores. 

| Parameter Name | Default Value | Env. | Description |
| :--- | :--- | :---: | :--- |
| benchmark.batch.size | 256 | yes | If the database driver used allows batch operations, this value must be used as the upper limit for the database operations contained in a batch. Only the value 0 prevents the execution of batch operations. The specified value must not be less than zero. |
| benchmark.comment | n/a | yes | In the result file, this comment is used to identify the benchmark run. |
| benchmark.core.multiplier | 0 | yes | This parameter determines whether multithreading is applied or not. If this value is zero, no multithreading is performed. Otherwise the product of this parameter and the parameter `benchmark.number.cores` defines the number of threads and also the number of database connections. The specified value must not be less than zero. |
| benchmark.database | n/a | yes | The database shortcut defines the Oracle database used in the benchmark run. |
| benchmark.driver | n/a | yes | The name and version of the database driver used in the benchmark run, for example 'JDBC (Version 19.3.0.0.0)'. This version of the driver should be determined by the specific benchmark driver routine at runtime. |
| benchmark.host.name | n/a | no | In the result file, this value is used as a unique identifier of the current computer. This value will be determined during the setup. |
| benchmark.id | n/a | no | In the result file, this value is used as a unique identifier of the benchmark run. This value will be determined during the setup. |
| benchmark.language | n/a | yes | The programming language with name and version executing the benchmark run, for example 'Java 11.0.5'. The version of the programming language should be determined by the specific benchmark driver routine at runtime. |
| benchmark.number.cores | n/a | yes | The number of cores. This value will be determined during the setup. |
| benchmark.number.partitions | 0 | no | The number of partitions. This value will be determined during the setup. |
| benchmark.os | n/a | no | In the result file, this comment is used to identify the operating system environment, for example 'amd64 / Linux / 4.15.0-1028-gcp'. This value will be determined during the setup. |
| benchmark.release | n/a | no | In the result file, this comment is used to identify the release number of the ora_bench application, for example '1.0.0'. |
| benchmark.transaction.size | 512 | yes | The number of `INSERT` operations until a `COMMIT` is performed. The value 0 means that all INSERT operations are performed in a single transaction. The value must be at least as large as the value of batch size (`benchmark.batch.size`). | 
| benchmark.trials | 10 | no | This determines the number of tests to be performed per database. The specified value must be at least 1. |
| benchmark.user.name | n/a | no | In the result file, this value is used as a unique identifier of the user account name. This value will be determined during the setup. |
| connection.fetch.size | 1024 | no | The number determines how much data is pulled from the database across the network. With value 0 the default value of the driver is used. The specified value must not be less than zero. |
| connection.host | 0.0.0.0 | yes | The IP address or host name of the Oracle server to which you are connecting. |
| connection.password | regit | no | The password corresponding to the connection user name. |
| connection.port | 1521 | yes | The number of the TCP port that the Oracle server uses to listen for client connections. |
| connection.service | n/a | yes | The service name of the database to access. |
| connection.user | scott | no | The user name to use to access the Oracle server. |
| file.bulk.delimiter | ; | no | The delimiter character in the bulk file. |
| file.bulk.header | key;<br>data | no | The header used to generate the bulk file. |
| file.bulk.length | 1024 | no | The length of the data part in the bulk file - minimum 80 and maximum 4000. |
| file.bulk.name | priv/ora_bench_bulk_data.csv | no | The relative filename of the bulk file. |
| file.bulk.size | 100000 | no | The number of records to be generated in the bulk file. The specified value must be at least 1. |
| file.configuration.name | priv/properties/ora_bench.properties | yes | The relative filename of the configuration file. |
| file.configuration.name.c | priv/properties/ora_bench_c.properties | no | The relative filename of the C version of the configuration file. |
| file.configuration.name.erlang | priv/properties/ora_bench_erlang.properties | no | The relative filename of the Erlang version of the configuration file. |
| file.configuration.name.json | priv/properties/ora_bench.json | no | The relative filename of the JSON version of the configuration file. |
| file.configuration.name.python | priv/properties/ora_bench_python.properties | no | The relative filename of the Python version of the configuration file. |
| file.result.delimiter | \t | no | The delimiter character in the result file. Here the semicolon must be used as separator. |
| file.result.header | release;benchmark id;<br>benchmark comment;<br>host name;<br>no. cores;<br>os;<br>user name;<br>database;<br>language;<br>driver;<br>trial no.;<br>SQL statement;<br>core multiplier;<br>fetch size;<br>transaction size;<br>bulk length;<br>bulk size;<br>batch size;<br>action;<br>start day time;<br>end day time;<br>duration (sec);<br>duration (ns) | no | The header used to generate the result file. At runtime, this is replaced by the character specified in parameter `file.result.delimiter`. |
| file.result.name | priv/ora_bench_result.tsv | yes | The relative filename of the result file. |
| sql.create | n/a | no | The SQL statement to create the test table. |
| sql.drop | DROP TABLE ora_bench_table | no | The SQL statement to delete the test table. |
| sql.insert | INSERT INTO ora_bench_table<br>(key, data)<br>VALUES<br>(:key, :data) | no | The SQL statement to insert the data from the bulk file into the test table. |
| sql.select | SELECT data<br>FROM ora_bench_table<br>WHERE key = :key | no | The SQL statement to retrieve the previously inserted data. |
