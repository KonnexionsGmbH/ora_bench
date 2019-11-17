# Benchmark Configuration Parameter

The following table contains all possible configuration parameters.
The `Parameter Name` column contains the parameter name as used in the configuration file.
The parameters with the default value 'n/a' must be defined at runtime. 
If the parameter can be overridden by an environment variable (column `Env.`) then this environment variable must have the prefix `ORA_BENCH_` and the dots in the `Parameter Name` must be replaced by underscores. 

| Parameter Name | Default Value | Env. | Description |
| :--- | :--- | :---: | :--- |
| benchmark.batch.size | 256 | no | If the database driver used allows batch operations, this value must be used as the upper limit for the database operations contained in a batch. |
| benchmark.comment | n/a | yes | In the result files, this comment is used to identify the benchmark run. |
| benchmark.database | n/a | yes | The database shortcut defines the Oracle database used in the benchmark run. |
| benchmark.driver | n/a | yes | The name and version of the database driver used in the benchmark run, for example 'JDBC (Version 19.3.0.0.0)'. This value should be determined at runtime. |
| benchmark.environment | n/a | yes | In the result files, this comment is used to identify the operating system environment, for example 'amd64 / Linux / 4.15.0-1028-gcp'. This value should be determined at runtime. |
| benchmark.module | n/a | yes | The name of the module and the programming language with name and version executing the benchmark run, for example 'OraBench (Java 11.0.5)'. the version of the programming language should be determined at runtime |
| benchmark.program.name.oranif.c | OraBench.bin | no | Specifies the name of the executable C file. |
| benchmark.transaction.size | 512 | no | The number of `INSERT` operations until a `COMMIT` is performed. | 
| benchmark.trials | 10 | no | This determines the number of tests to be performed per database. |
| connection.host | 0.0.0.0 | yes | The IP address or host name of the Oracle server to which you are connecting. |
| connection.password | regit | no | The password corresponding to the connection user name. |
| connection.port | 1521 | yes | The number of the TCP port that the Oracle server uses to listen for client connections. |
| connection.service | n/a | yes | The service name of the database to access. |
| connection.string | (DESCRIPTION=<br>(ADDRESS_LIST=<br>(ADDRESS=<br>(PROTOCOL=TCP)<br>(HOST=127.0.0.1)<br>(PORT=1521)))<br>(CONNECT_DATA=<br>(SERVER=dedicated)<br>(SERVICE_NAME=xe))) | no | The connection string for direct access to the database. |
| connection.user | scott | no | The user name to use to access the Oracle server. |
| file.bulk.delimiter | ; | no | The delimiter character in the bulk file. |
| file.bulk.header | key;<br>data | no | The header used to generate the bulk file. |
| file.bulk.length | 1024 | no | The length of the data part in the bulk file - minimum 33 and maximum 4000. |
| file.bulk.name | priv/ora_bench_bulk_data.csv | no | The relative filename of the bulk file. |
| file.bulk.size | 100000 | no | The number of records to be generated in the bulk file. |
| file.configuration.name.oranif.c | scripts/run_bench_oranif_c.sh | no | The relative filename of the oranif & C version of the configuration file. |
| file.configuration.name.oranif.erlang | priv/ora_bench_oranif_erlang.properties | no | The relative filename of the oranif & Erlang version of the configuration file. |
| file.configuration.name | priv/ora_bench.properties | yes | The relative filename of the configuration file. |
| file.result.detailed.delimiter | \t | no | The delimiter character in the detailed result file. Here the semicolon must be used as separator. |
| file.result.detailed.header | benchmark comment;<br>environment;<br>database;<br>module;<br>driver;<br>trial no.;<br>SQL statement;<br>transaction size;<br>bulk length;<br>bulk size;<br>batch size;<br>action;<br>start day time;<br>end day time;<br>duration (sec);<br>duration (ns) | no | The header used to generate the detailed result file. At runtime, this is replaced by the character specified in parameter `file.result.detailed.delimiter`. |
| file.result.detailed.name | priv/ora_bench_result_detailed.tsv | yes | The relative filename of the detailed result file. |
| file.result.statistical.delimiter | \t | no | The delimiter character in the summary result file. |
| file.result.statistical.header | benchmark comment;<br>environment;<br>database;<br>module;<br>driver;<br>SQL statement;<br>transaction size;<br>bulk length;<br>bulk size;<br>batch size;<br>trials;<br>start day time;<br>end day time;<br>mean duration (ns);<br>mean time per SQL stmnt (ns);<br>minimum duaration (ns);<br>maximum duartion (ns) | no | The header used to generate the summary result file. At runtime, this is replaced by the character specified in parameter `file.result.statistical.delimiter`. |
| file.result.statistical.name | priv/ora_bench_result_statistical.tsv | yes | The relative filename of the summary result file. |
| sql.create | CREATE TABLE ora_bench_table<br>(key VARCHAR2(32) PRIMARY KEY,<br>data VARCHAR2(4000)) | no | The SQL statement to create the test table. |
| sql.drop | DROP TABLE ora_bench_table | no | The SQL statement to delete the test table. |
| sql.insert.jamdb | INSERT INTO ora_bench_table<br>(item)<br>VALUES<br>('~10..0B') | no | The SQL statement to insert the data from the bulk file into the test table - JamDB version. |
| sql.insert.oracle | INSERT INTO ora_bench_table<br>(key, data)<br>VALUES<br>(:key, :data) | no | The SQL statement to insert the data from the bulk file into the test table - standard version. |
| sql.select | SELECT data<br>FROM ora_bench_table<br>WHERE key = :key | no | The SQL statement to retrieve the previously inserted data. |
