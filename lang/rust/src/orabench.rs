use std::collections::HashMap;
use std::fs::{File, OpenOptions};
use std::io::BufReader;
use std::path::Path;

use chrono::prelude::*;
use chrono::Duration;
use crossbeam::thread;
use csv::Writer;
use java_properties::read;
use oracle::{Batch, Connection, Error};
use rustc_version_runtime::version;

// =============================================================================
// Type definitions.
// -----------------------------------------------------------------------------

#[derive(Clone, Copy)]
struct ParamsRunInsert<'a> {
    benchmark_batch_size: u32,
    benchmark_core_multiplier: u32,
    benchmark_number_partitions: usize,
    benchmark_transaction_size: u32,
    connections: &'a Vec<Connection>,
    partitions: &'a Vec<Vec<(String, String)>>,
    sql_insert: &'a str,
}

#[derive(Clone, Copy)]
struct ParamsRunSelect<'a> {
    benchmark_core_multiplier: u32,
    benchmark_number_partitions: usize,
    connections: &'a Vec<Connection>,
    partitions: &'a Vec<Vec<(String, String)>>,
    sql_select: &'a str,
}

#[derive(Clone, Copy)]
struct ParamsRunTrial<'a> {
    benchmark_batch_size: u32,
    benchmark_core_multiplier: u32,
    benchmark_number_partitions: usize,
    benchmark_transaction_size: u32,
    connections: &'a Vec<Connection>,
    partitions: &'a Vec<Vec<(String, String)>>,
    sql_create: &'a str,
    sql_drop: &'a str,
    sql_insert: &'a str,
    sql_select: &'a str,
}

#[derive(Clone)]
struct StatisticsEntry {
    action: String,
    end_time: DateTime<Local>,
    sql_stmnt: String,
    start_time: DateTime<Local>,
    trial_no: u32,
}

// =============================================================================
// Commit the transaction.
// -----------------------------------------------------------------------------

fn commit(connection: &Connection) {
    match connection.commit() {
        Ok(_) => {}
        Err(error) => {
            error!("commit() - Problem with connection.commit(): {}", error);
            std::process::exit(1);
        }
    };
}

// =============================================================================
// create a separate database connection (without auto commit behaviour) for each partition.
// -----------------------------------------------------------------------------

fn create_connections(
    benchmark_number_partitions: usize,
    config: &HashMap<String, String>,
) -> Vec<Connection> {
    let mut connection_string: String = "//".to_string();
    connection_string.push_str(config.get("connection.host").unwrap());
    connection_string.push(':');
    connection_string.push_str(config.get("connection.port").unwrap());
    connection_string.push('/');
    connection_string.push_str(config.get("connection.service").unwrap());
    let password: &String = config.get("connection.password").unwrap();
    let user: &String = config.get("connection.user").unwrap();

    let mut connections: Vec<Connection> = Vec::with_capacity(benchmark_number_partitions);

    for _ in 0..benchmark_number_partitions {
        connections
            .push(Connection::connect(user.clone(), password.clone(), &connection_string).unwrap());
    }

    connections
}

// =============================================================================
// Create the result file.
// -----------------------------------------------------------------------------

fn create_result_file(
    config: &HashMap<String, String>,
    statistics: &mut Vec<StatisticsEntry>,
) -> (i64, i64, i64) {
    debug!("Start create_statistics_file()");

    const POS_ACTION: usize = 18;
    const POS_DURATION_NS: usize = 22;
    const POS_DURATION_SEC: usize = 21;
    const POS_END_TIME: usize = 20;
    const POS_SQL_STMNT: usize = 11;
    const POS_START_TIME: usize = 19;
    const POS_TRIAL_NO: usize = 10;

    let file_delimiter: u8 = *config
        .get("file.result.delimiter")
        .unwrap()
        .clone()
        .as_bytes()
        .get(0)
        .unwrap();
    let file_path = Path::new(config.get("file.result.name").unwrap());

    let existing: bool = std::path::Path::new(file_path).is_file();

    let file = match OpenOptions::new()
        .write(true)
        .create(true)
        .append(true)
        .open(file_path)
    {
        Ok(file) => file,
        Err(error) => {
            error!(
                "create_result_file() - Problem opening the result file: {}",
                error
            );
            std::process::exit(1);
        }
    };

    let mut writer: Writer<File> = csv::WriterBuilder::new()
        .delimiter(file_delimiter)
        .from_writer(file);

    if !existing {
        let file_header = config.get("file.result.header").unwrap().split(';');

        match writer.write_record(file_header) {
            Ok(result) => result,
            Err(error) => {
                error!(
                    "create_result_file() - Problem writing the header of the result file: {}",
                    error
                );
                std::process::exit(1);
            }
        };
    }

    let mut result_entry: Vec<String> = Vec::with_capacity((POS_DURATION_NS + 1) as usize);

    result_entry.push(config.get("benchmark.release").unwrap().clone());
    result_entry.push(config.get("benchmark.id").unwrap().clone());
    result_entry.push(config.get("benchmark.comment").unwrap().clone());
    result_entry.push(config.get("benchmark.host.name").unwrap().clone());
    result_entry.push(config.get("benchmark.number.cores").unwrap().clone());
    result_entry.push(config.get("benchmark.os").unwrap().clone());
    result_entry.push(config.get("benchmark.user.name").unwrap().clone());
    result_entry.push(config.get("benchmark.database").unwrap().clone());

    let mut language: String = "Rust ".to_string();
    language.push_str(&version().to_string());
    result_entry.push(language);

    let mut driver: String = "Rust-oracle ".to_string();
    driver.push_str("0.5.3");
    result_entry.push(driver);

    result_entry.push("".to_string());
    result_entry.push("".to_string());
    result_entry.push(config.get("benchmark.core.multiplier").unwrap().clone());
    result_entry.push(config.get("connection.fetch.size").unwrap().clone());
    result_entry.push(config.get("benchmark.transaction.size").unwrap().clone());
    result_entry.push(config.get("file.bulk.length").unwrap().clone());
    result_entry.push(config.get("file.bulk.size").unwrap().clone());
    result_entry.push(config.get("benchmark.batch.size").unwrap().clone());
    result_entry.push("".to_string());
    result_entry.push("".to_string());
    result_entry.push("".to_string());
    result_entry.push("".to_string());
    result_entry.push("".to_string());

    let mut trial_max: i64 = 0;
    let mut trial_min: i64 = 0;
    let mut trial_total: i64 = 0;

    for statistics_entry in statistics.iter() {
        let action = &statistics_entry.action;

        let end_time: DateTime<Local> = if action == "benchmark" {
            Local::now()
        } else {
            statistics_entry.end_time
        };

        let start_time: DateTime<Local> = statistics_entry.start_time;

        let difference: Duration = end_time - start_time;

        result_entry[POS_TRIAL_NO] = statistics_entry.trial_no.to_string();
        result_entry[POS_SQL_STMNT] = statistics_entry.sql_stmnt.clone();
        result_entry[POS_ACTION] = action.clone();
        result_entry[POS_START_TIME] = start_time.to_string();
        result_entry[POS_END_TIME] = end_time.to_string();

        result_entry[POS_DURATION_SEC] = difference.num_seconds().to_string();
        result_entry[POS_DURATION_NS] = difference.num_nanoseconds().unwrap().to_string();

        match writer.write_record(&result_entry) {
            Ok(result) => result,
            Err(error) => {
                error!(
                    "create_result_file() - Problem writing result file entries: {}",
                    error
                );
                std::process::exit(1);
            }
        };

        if action.eq("trial") {
            let difference_ms = difference.num_milliseconds();

            if trial_max == 0 || trial_max < difference_ms {
                trial_max = difference_ms;
            }

            if trial_min == 0 || trial_min > difference_ms {
                trial_min = difference_ms;
            }

            trial_total += difference_ms;
        }
    }

    match writer.flush() {
        Ok(result) => result,
        Err(error) => {
            error!(
                "create_result_file(9 - Problem flushing the result file: {}",
                error
            );
            std::process::exit(1);
        }
    };

    debug!("End   create_statistics_file()");

    (trial_min, trial_max, trial_total)
}

// =============================================================================
// Execute batch processing.
// -----------------------------------------------------------------------------

fn execute_batch(batch_collection: &mut Batch) {
    match batch_collection.execute() {
        Ok(_) => {}
        Err(error) => {
            error!(
                "run_insert_helper() - Problem with batch.execute(): {}",
                error
            );
            std::process::exit(1);
        }
    };
}

// =============================================================================
// Load properties from properties file.
// -----------------------------------------------------------------------------

fn get_config(file_name: String) -> HashMap<String, String> {
    debug!("Start get_config()");

    let file = match File::open(&file_name) {
        Ok(file) => file,
        Err(error) => {
            error!(
                "get_config() - Problem opening the properties file: {}",
                error
            );
            std::process::exit(1);
        }
    };

    let config = match read(BufReader::new(file)) {
        Ok(config) => config,
        Err(error) => {
            error!(
                "get_config() - Problem reading the properties file: {}",
                error
            );
            std::process::exit(1);
        }
    };

    debug!("End   get_config()");

    config
}

// =============================================================================
// Load bulk data from csv / tsv file.
// -----------------------------------------------------------------------------

fn load_bulk(
    benchmark_number_partitions: usize,
    config: &HashMap<String, String>,
) -> Vec<Vec<(String, String)>> {
    debug!("Start load_bulk()");

    let file_bulk_delimiter: u8 = *config
        .get("file.bulk.delimiter")
        .unwrap()
        .clone()
        .as_bytes()
        .get(0)
        .unwrap();
    let file_bulk_name: String = config.get("file.bulk.name").unwrap().clone();

    info!("Start Distribution of the data in the partitions");

    let bulk_file = match File::open(&file_bulk_name) {
        Ok(bulk_file) => bulk_file,
        Err(error) => {
            error!("load_bulk() - Problem opening the bulk file: {}", error);
            std::process::exit(1);
        }
    };

    let mut bulk_file_reader = csv::ReaderBuilder::new()
        .delimiter(file_bulk_delimiter)
        .from_reader(bulk_file);

    let mut partitions: Vec<Vec<(String, String)>> =
        Vec::with_capacity(benchmark_number_partitions);
    let partition_vector: Vec<(String, String)> = Vec::new();

    for _ in 0..benchmark_number_partitions {
        partitions.push(partition_vector.clone());
    }

    for result in bulk_file_reader.records() {
        let record = match result {
            Ok(record) => record,
            Err(error) => {
                error!(
                    "load_bulk() - Problem reading CSV from bulk file: {}",
                    error
                );
                std::process::exit(1);
            }
        };

        let partition = (*record[0].as_bytes().get(0).unwrap() as usize * 251
            + *record[0].as_bytes().get(1).unwrap() as usize)
            % benchmark_number_partitions;

        partitions[partition].push((record[0].to_string(), record[1].to_string()));
    }

    for (partition, partition_vector) in partitions.iter().enumerate() {
        info!(
            "Partition {} has {} rows",
            partition,
            partition_vector.len()
        );
    }

    info!("End   Distribution of the data in the partitions");

    debug!("End   load_bulk()");

    partitions
}

// =============================================================================
// Performing a complete benchmark run that can consist of several trial runs.
// -----------------------------------------------------------------------------

pub(crate) fn run_benchmark(file_name_config: String) {
    debug!("Start run_benchmark()");

    // READ the configuration parameters into the memory (config params `file.configuration.name ...`)
    let config: HashMap<String, String> = get_config(file_name_config);

    // save the current time as the start of the 'benchmark' action
    let start_time: DateTime<Local> = Local::now();

    let benchmark_number_partitions: usize = config
        .get("benchmark.number.partitions")
        .unwrap()
        .parse::<usize>()
        .unwrap();

    // READ the bulk file data into the partitioned collection bulk_data_partitions (config param 'file.bulk.name')
    let partitions: Vec<Vec<(String, String)>> = load_bulk(benchmark_number_partitions, &config);

    let connections = create_connections(benchmark_number_partitions, &config);

    /*
    trial_no = 0
    WHILE trial_no < config_param 'benchmark.trials'
        DO run_trial(database connections,
                     trial_no,
                     bulk_data_partitions)
    ENDWHILE
    */
    let trials: u32 = config
        .get("benchmark.trials")
        .unwrap()
        .parse::<u32>()
        .unwrap();

    let sql_insert: String = config
        .get("sql.insert")
        .unwrap()
        .clone()
        .replace(":key", ":1")
        .replace(":data", ":2");
    let mut statistics: Vec<StatisticsEntry> = Vec::with_capacity((trials * 3 + 1) as usize);

    let params_run_trial: ParamsRunTrial = ParamsRunTrial {
        benchmark_batch_size: config
            .get("benchmark.batch.size")
            .unwrap()
            .parse::<u32>()
            .unwrap(),
        benchmark_core_multiplier: config
            .get("benchmark.core.multiplier")
            .unwrap()
            .parse::<u32>()
            .unwrap(),
        benchmark_number_partitions,
        benchmark_transaction_size: config
            .get("benchmark.transaction.size")
            .unwrap()
            .parse::<u32>()
            .unwrap(),
        connections: &connections,
        partitions: &partitions,
        sql_create: config.get("sql.create").unwrap(),
        sql_drop: config.get("sql.drop").unwrap(),
        sql_insert: &sql_insert,
        sql_select: config.get("sql.select").unwrap(),
    };

    for trial_no in 1..=trials {
        run_trial(params_run_trial, &mut statistics, trial_no);
    }

    /*
    partition_no = 0
    WHILE partition_no < config_param 'benchmark.number.partitions'
        close the database connection
    ENDWHILE
    */
    for connection in connections.iter() {
        match connection.close() {
            Ok(_) => {}
            Err(error) => {
                error!("run_benchmark() - Problem connection.close(): {}", error);
                std::process::exit(1);
            }
        }
    }

    // WRITE an entry for the action 'benchmark' in the result file (config param 'file.result.name')
    let end_time: DateTime<Local> = Local::now();

    statistics.push(StatisticsEntry {
        action: "benchmark".to_string(),
        end_time,
        sql_stmnt: "".to_string(),
        start_time,
        trial_no: 0,
    });

    let (trial_min, trial_max, trial_total) = create_result_file(&config, &mut statistics);

    info!("Duration (ms) trial min.    : {}", trial_min);
    info!("Duration (ms) trial max.    : {}", trial_max);
    info!(
        "Duration (ms) trial average : {}",
        math::round::half_up((trial_total / trials as i64) as f64, 2)
    );
    info!(
        "Duration (ms) benchmark run : {}",
        (end_time - start_time).num_milliseconds()
    );

    debug!("End   run_benchmark()");
}

// =============================================================================
// Supervise function for inserting data into the database.
// -----------------------------------------------------------------------------

fn run_insert(
    params: ParamsRunInsert,
    statistics: &mut Vec<StatisticsEntry>,
    trial_no: u32,
) -> Result<(), Error> {
    debug!("Start run_insert()");

    // save the current time as the start of the 'query' action
    let start_time: DateTime<Local> = Local::now();

    /*
    partition_no = 0
    WHILE partition_no < config_param 'benchmark.number.partitions'
        IF config_param 'benchmark.core.multiplier' = 0
            DO run_insert_helper(database connections(partition_no),
                    bulk_data_partitions(partition_no))
        ELSE
            DO run_insert_helper (database connections(partition_no),
                    bulk_data_partitions(partition_no)) as a thread
        ENDIF
    ENDWHILE
    */
    if params.benchmark_core_multiplier == 0 {
        for partition_no in 0..params.benchmark_number_partitions {
            run_insert_helper(
                params.benchmark_batch_size,
                params.benchmark_transaction_size,
                &params.connections[partition_no],
                partition_no,
                &params.partitions[partition_no],
                params.sql_insert,
                trial_no,
            );
        }
    } else {
        thread::scope(|s| {
            for partition_no in 0..params.benchmark_number_partitions {
                s.spawn(move |_| {
                    run_insert_helper(
                        params.benchmark_batch_size,
                        params.benchmark_transaction_size,
                        &params.connections[partition_no],
                        partition_no,
                        &params.partitions[partition_no],
                        params.sql_insert,
                        trial_no,
                    );
                });
            }
        })
        .unwrap();
    }

    // WRITE an entry for the action 'query' in the result file (config param 'file.result.name')
    statistics.push(StatisticsEntry {
        action: "insert".to_string(),
        end_time: Local::now(),
        sql_stmnt: params.sql_insert.parse().unwrap(),
        start_time,
        trial_no,
    });

    debug!("End   run_insert()");

    Ok(())
}

// =============================================================================
// Helper function for inserting data into the database.
// -----------------------------------------------------------------------------

fn run_insert_helper<'a>(
    benchmark_batch_size: u32,
    benchmark_transaction_size: u32,
    connection: &'a Connection,
    partition_no: usize,
    partition: &'a [(String, String)],
    sql_insert: &'a str,
    trial_no: u32,
) {
    debug!("Start run_insert_helper()");

    /*
    IF trial_no == 1
       INFO Start insert partition_key=partition_key
    ENDIF
    */
    if trial_no == 1 {
        info!("Start insert partition_key={}", partition_no);
    }

    /*
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
      ENDIF

      IF  config param 'benchmark.transaction.size' > 0
      AND count modulo config param 'benchmark.transaction.size' = 0
          commit
      ENDIF
    ENDWHILE
    */

    let mut batch_collection = connection
        .batch(
            sql_insert,
            if benchmark_batch_size == 0 {
                partition.len()
            } else {
                benchmark_batch_size as usize
            },
        )
        .build()
        .unwrap();

    let mut statement = connection.prepare(sql_insert, &[]).unwrap();

    let mut count = 0;
    for record in partition.iter() {
        count += 1;

        if benchmark_batch_size == 1 {
            match statement.execute(&[&record.0, &record.1]) {
                Ok(_) => {}
                Err(error) => {
                    error!(
                        "run_insert_helper() - Problem with statement.execute(): {}",
                        error
                    );
                    std::process::exit(1);
                }
            }
        } else {
            match batch_collection.append_row(&[&record.0, &record.1]) {
                Ok(_) => {}
                Err(error) => {
                    error!(
                        "run_insert_helper() - Problem with batch.append_row(): {}",
                        error
                    );
                    std::process::exit(1);
                }
            };

            if benchmark_batch_size > 1 && (count % benchmark_batch_size == 0) {
                execute_batch(&mut batch_collection);
            }
        }

        if benchmark_transaction_size > 0 && (count % benchmark_transaction_size == 0) {
            commit(connection);
        }
    }

    /*
    IF collection batch_collection is not empty
      execute the SQL statements in the collection batch_collection
    ENDIF
    */
    if benchmark_batch_size != 1 {
        execute_batch(&mut batch_collection);
    }

    // commit
    commit(connection);

    /*
    IF trial_no == 1
       INFO End   insert partition_key=partition_key
    ENDIF
    */
    if trial_no == 1 {
        info!("End   insert partition_key={}", partition_no);
    }

    debug!("End   run_insert_helper()");
}

// =============================================================================
// Supervise function for retrieving of the database data.
// -----------------------------------------------------------------------------

fn run_select(
    params: ParamsRunSelect,
    statistics: &mut Vec<StatisticsEntry>,
    trial_no: u32,
) -> Result<(), Error> {
    debug!("Start run_select()");

    // save the current time as the start of the 'query' action
    let start_time: DateTime<Local> = Local::now();

    /*
    partition_no = 0
    WHILE partition_no < config_param 'benchmark.number.partitions'
        IF config_param 'benchmark.core.multiplier' = 0
            DO run_select_helper(database connections(partition_no),
                                 bulk_data_partitions(partition_no,
                                 partition_no)
        ELSE
            DO run_select_helper(database connections(partition_no),
                                 bulk_data_partitions(partition_no,
                                 partition_no) as a thread
        ENDIF
    ENDWHILE
    */
    if params.benchmark_core_multiplier == 0 {
        for partition_no in 0..params.benchmark_number_partitions {
            run_select_helper(
                &params.connections[partition_no],
                partition_no,
                &params.partitions[partition_no],
                params.sql_select,
                trial_no,
            );
        }
    } else {
        thread::scope(|s| {
            for partition_no in 0..params.benchmark_number_partitions {
                s.spawn(move |_| {
                    run_select_helper(
                        &params.connections[partition_no],
                        partition_no,
                        &params.partitions[partition_no],
                        params.sql_select,
                        trial_no,
                    );
                });
            }
        })
        .unwrap();
    }

    // WRITE an entry for the action 'query' in the result file (config param 'file.result.name')
    statistics.push(StatisticsEntry {
        action: "select".to_string(),
        end_time: Local::now(),
        sql_stmnt: params.sql_select.parse().unwrap(),
        start_time,
        trial_no,
    });

    debug!("End   run_select()");

    Ok(())
}

// =============================================================================
// Helper function for retrieving data from the database.
// -----------------------------------------------------------------------------

fn run_select_helper<'a>(
    connection: &'a Connection,
    partition_no: usize,
    partition: &'a [(String, String)],
    sql_select: &'a str,
    trial_no: u32,
) {
    debug!("Start run_select_helper()");

    /*
    IF trial_no == 1
       INFO Start select partition_key=partition_key
    ENDIF
    */
    if trial_no == 1 {
        info!("Start select partition_key={}", partition_no);
    }

    // execute the SQL statement in config param 'sql.select
    let mut sql_select_complete: String = sql_select.to_string();
    sql_select_complete.push_str(" where partition_key = ");
    sql_select_complete.push_str(&partition_no.to_string());
    let rows = match connection.query(&sql_select_complete, &[]) {
        Ok(rows) => rows,
        Err(error) => {
            error!(
                "create_result_file() - Problem with select '{}': {}",
                sql_select_complete, error
            );
            std::process::exit(1);
        }
    };

    /*
    int count = 0;
    WHILE iterating through the result set
        count + 1
    ENDWHILE
    */
    let mut count: usize = 0;
    for _row in rows {
        count += 1;
    }

    /*
    IF NOT count = size(bulk_data_partition)
        display an error message
    ENDIF
    */

    if count != partition.len() {
        error!(
            "Number rows: expected={} - found={}",
            partition.len(),
            count
        );
        std::process::exit(1);
    }

    /*
    IF trial_no == 1
       INFO End   select partition_key=partition_key
    ENDIF
    */
    if trial_no == 1 {
        info!("End   select partition_key={}", partition_no);
    }

    debug!("End   run_select_helper()");
}

// =============================================================================
// Performing a single trial run.
// -----------------------------------------------------------------------------

fn run_trial(params: ParamsRunTrial, statistics: &mut Vec<StatisticsEntry>, trial_no: u32) {
    debug!("Start run_trial()");

    // save the current time as the start of the 'trial' action
    let start_time: DateTime<Local> = Local::now();

    // INFO  Start trial no. trial_no
    info!("Start trial no. {}", trial_no);

    /*
    create the database table (config param 'sql.create')
    IF error
        drop the database table (config param 'sql.drop')
        create the database table (config param 'sql.create')
    ENDIF
    */
    let mut result_create_drop = params.connections[0].execute(params.sql_create, &[]);
    if result_create_drop.is_ok() {
        debug!("last DDL statement={}", params.sql_create);
    } else {
        result_create_drop = params.connections[0].execute(params.sql_drop, &[]);
        if result_create_drop.is_err() {
            error!(
                "run_trial() - Problem dropping the database table: {}",
                result_create_drop.err().unwrap()
            );
            std::process::exit(1);
        }

        result_create_drop = params.connections[0].execute(params.sql_create, &[]);
        if result_create_drop.is_err() {
            error!(
                "run_trial() - Problem creating the database table: {}",
                result_create_drop.err().unwrap()
            );
            std::process::exit(1);
        }

        debug!("last DDL statement after DROP={}", params.sql_create);
    }

    /*
    DO run_insert(database connections,
                  trial_no,
                  bulk_data_partitions)
    */
    let params_run_insert = ParamsRunInsert {
        benchmark_batch_size: params.benchmark_batch_size,
        benchmark_core_multiplier: params.benchmark_core_multiplier,
        benchmark_number_partitions: params.benchmark_number_partitions,
        benchmark_transaction_size: params.benchmark_transaction_size,
        connections: params.connections,
        partitions: params.partitions,
        sql_insert: params.sql_insert,
    };

    let result_run_insert = run_insert(params_run_insert, statistics, trial_no);
    if result_run_insert.is_err() {
        error!(
            "run_trial() - Problem in run_insert: {}",
            result_run_insert.err().unwrap()
        );
        std::process::exit(1);
    }

    /*
    DO run_select(database connections,
                  trial_no,
                  bulk_data_partitions)
    */
    let params_run_select = ParamsRunSelect {
        benchmark_core_multiplier: params.benchmark_core_multiplier,
        benchmark_number_partitions: params.benchmark_number_partitions,
        connections: params.connections,
        partitions: params.partitions,
        sql_select: params.sql_select,
    };
    let result_run_select = run_select(params_run_select, statistics, trial_no);
    if result_run_select.is_err() {
        error!(
            "run_trial() - Problem in run_select: {}",
            result_run_select.err().unwrap()
        );
        std::process::exit(1);
    }

    // drop the database table (config param 'sql.drop')
    result_create_drop = params.connections[0].execute(params.sql_drop, &[]);
    if result_create_drop.is_err() {
        error!(
            "run_trial() - Problem dropping the database table: {}",
            result_create_drop.err().unwrap()
        );
        std::process::exit(1);
    }
    debug!("last DDL statement={}", params.sql_create);

    // WRITE an entry for the action 'trial' in the result file (config param 'file.result.name')
    let end_time: DateTime<Local> = Local::now();

    statistics.push(StatisticsEntry {
        action: "trial".to_string(),
        end_time,
        sql_stmnt: "".to_string(),
        start_time,
        trial_no,
    });

    info!(
        "Duration (ms) trial         : {}",
        (end_time - start_time).num_milliseconds()
    );

    debug!("End   run_trial()");
}
