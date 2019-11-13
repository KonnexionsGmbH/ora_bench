# Benchmark Configuration Parameter

| Parameter Name | Default Value | Overloadable | Description  |
| :--- | :--- | :---: | :--- |
| benchmark.batch.size | 256 | no |   |
| benchmark.comment | Standard tests | yes |   |
| benchmark.database | db_19_3_ee | yes |   |
| benchmark.environment | jfww-windows | yes |   |
| benchmark.program.name.c | OraBench.bin | no |   |
| benchmark.trials | 10 | no |   |
| connection.host | 0.0.0.0 | yes |   |
| connection.password | regit | no |   |
| connection.port | 1521 | yes |   |
| connection.service | orclpdb1 | yes |   |
| connection.string | (DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST=127.0.0.1)(PORT=1521)))(CONNECT_DATA=(SERVER=dedicated)(SERVICE_NAME=xe))) | no |   |
| connection.user | scott | no |   |
| file.bulk.delimiter | ; | no | the delimiter character in the bulk file |
| file.bulk.header | key;data | no |   |
| file.bulk.length | 1024 | no |   |
| file.bulk.name | priv/ora_bench_bulk_data.csv | no | the full relative filename of the bulk file |
| file.bulk.size | 100000 | no |   |
| file.configuration.name.c | scripts/run_bench_c.sh | no | the full relative filename of the C version of the configuration file |
| file.configuration.name.erlang | priv/ora_bench_erlang.properties | no | the full relative filename of Erlang version of the configuration file |
| file.configuration.name | priv/ora_bench.properties | yes | the full relative filename of the configuration file |
| file.result.delimiter | \t | no | the delimiter character in the detailed result file |
| file.result.header | benchmark comment;environment;database;module;interface;trial no.;SQL statement;bulk length;bulk size;batch size;action;start day time;end day time;duration (sec);duration (ns) | no |   |
| file.result.name | priv/ora_bench_result.tsv | yes | the full relative filename of the detailed result file |
| file.summary.delimiter | \t | no | the delimiter character in the summary result file |
| file.summary.header | benchmark comment;environment;database;module;interface;SQL statement;bulk length;bulk size;batch size;trials;start day time;end day time;average duration (ns);average per SQL stmnt (ns);minimum duaration (ns);maximum duartion (ns) | no |   |
| file.summary.name | priv/ora_bench_summary.tsv | yes | the full relative filename of the summary result file |
| sql.create | CREATE TABLE ora_bench_table (key VARCHAR2(32) PRIMARY KEY, data VARCHAR2(4000)) | no |   |
| sql.drop | DROP TABLE ora_bench_table | no |   |
| sql.insert.jamdb | INSERT INTO ora_bench_table (item) VALUES ('~10..0B') | no |   |
| sql.insert.oracle | INSERT INTO ora_bench_table (key, data) VALUES (:key, :data) | no |   |
| sql.select | SELECT data FROM ora_bench_table WHERE key = :key | no |   |
