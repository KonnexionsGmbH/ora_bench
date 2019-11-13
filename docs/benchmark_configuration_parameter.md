# Benchmark Configuration Parameter

The following table contains all possible configuration parameters.
The `Parameter Name` column contains the parameter name as used in the configuration file.
If the parameter can be overridden by an environment variable (column `Env.`) then this environment variable must have the prefix `ORA_BENCH_` and the dots in the `Parameter Name` must be replaced by underscores. 

| Parameter Name | Default Value | Env. | Description  |
| :--- | :--- | :---: | :--- |
| benchmark.batch.size | 256 | no | If the database driver used allows batch operations, this value must be used as the upper limit for the database operations contained in a batch. |
| benchmark.comment | Standard tests | yes | In the result files, this comment is used to identify the benchmark run. |
| benchmark.database | db_19_3_ee | yes | The database shortcut defines the Oracle database used in the benchmark run. |
| benchmark.environment | jfww-windows | yes | In the result files, this comment is used to identify the system environment. |
| benchmark.program.name.c | OraBench.bin | no | Specifies the name of the executable C file. |
| benchmark.trials | 10 | no | This determines the number of tests to be performed per database. |
| connection.host | 0.0.0.0 | yes | The IP address or host name of the Oracle server to which you are connecting. |
| connection.password | regit | no | The password corresponding to the connection user name. |
| connection.port | 1521 | yes | The number of the TCP port that the Oracle server uses to listen for client connections. |
| connection.service | orclpdb1 | yes | The service name of the database to access. |
| connection.string | (DESCRIPTION=<br>(ADDRESS_LIST=<br>(ADDRESS=<br>(PROTOCOL=TCP)<br>(HOST=127.0.0.1)<br>(PORT=1521)))<br>(CONNECT_DATA=<br>(SERVER=dedicated)<br>(SERVICE_NAME=xe))) | no | The connection string for direct access to the database. |
| connection.user | scott | no | The user name to use to access the Oracle server. |
| file.bulk.delimiter | ; | no | The delimiter character in the bulk file. |
| file.bulk.header | key;<br>data | no | The header used to generate the bulk file. |
| file.bulk.length | 1024 | no | The length of the data part in the bulk file - minimum 33 and maximum 4000. |
| file.bulk.name | priv/ora_bench_bulk_data.csv | no | The relative filename of the bulk file. |
| file.bulk.size | 100000 | no | The number of records to be generated in the bulk file. |
| file.configuration.name.c | scripts/run_bench_c.sh | no | The relative filename of the C version of the configuration file. |
| file.configuration.name.erlang | priv/ora_bench_erlang.properties | no | The relative filename of Erlang version of the configuration file. |
| file.configuration.name | priv/ora_bench.properties | yes | The relative filename of the configuration file. |
| file.result.delimiter | \t | no | The delimiter character in the detailed result file. Here the semicolon must be used as separator. |
| file.result.header | benchmark comment;<br>environment;<br>database;<br>module;<br>interface;<br>trial no.;<br>SQL statement;<br>bulk length;<br>bulk size;<br>batch size;<br>action;<br>start day time;<br>end day time;<br>duration (sec);<br>duration (ns) | no | The header used to generate the detailed result file. At runtime, this is replaced by the character specified in parameter `file.result.delimiter`. |
| file.result.name | priv/ora_bench_result.tsv | yes | The relative filename of the detailed result file. |
| file.summary.delimiter | \t | no | The delimiter character in the summary result file. |
| file.summary.header | benchmark comment;<br>environment;<br>database;<br>module;<br>interface;<br>SQL statement;<br>bulk length;<br>bulk size;<br>batch size;<br>trials;<br>start day time;<br>end day time;<br>average duration (ns);<br>average per SQL stmnt (ns);<br>minimum duaration (ns);<br>maximum duartion (ns) | no | The header used to generate the summary result file. At runtime, this is replaced by the character specified in parameter `file.summary.delimiter`. |
| file.summary.name | priv/ora_bench_summary.tsv | yes | The relative filename of the summary result file. |
| sql.create | CREATE TABLE ora_bench_table<br>(key VARCHAR2(32) PRIMARY KEY,<br>data VARCHAR2(4000)) | no | The SQL statement to create the test table. |
| sql.drop | DROP TABLE ora_bench_table | no | The SQL statement to delete the test table. |
| sql.insert.jamdb | INSERT INTO ora_bench_table<br>(item)<br>VALUES<br>>('~10..0B') | no | The SQL statement to insert the data from the bulk file into the test table - JamDB version. |
| sql.insert.oracle | INSERT INTO ora_bench_table<br>(key, data)<br>VALUES<br>>(:key, :data) | no | The SQL statement to insert the data from the bulk file into the test table - standard version. |
| sql.select | SELECT data<br>FROM ora_bench_table<br>WHERE key = :key | no | The SQL statement to retrieve the previously inserted data. |
