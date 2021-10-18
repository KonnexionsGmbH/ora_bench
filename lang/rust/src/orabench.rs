use chrono::prelude::*;
use java_properties::read;

use std::collections::HashMap;

use std::fs::File;
use std::io::BufReader;

// =============================================================================
// Load properties from properties file.
// -----------------------------------------------------------------------------

fn get_config(file_name: String) -> HashMap<String, String> {
    debug!("Start get_config()");

    let file = match File::open(&file_name) {
        Ok(file) => file,
        Err(error) => {
            error!("Problem opening the properties file: {}", error);
            std::process::exit(1);
        }
    };

    let config = match read(BufReader::new(file)) {
        Ok(config) => config,
        Err(error) => {
            error!("Problem reading the properties file: {}", error);
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
    config: &HashMap<String, String>,
    benchmark_number_partitions: usize,
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
            error!("Problem opening the bulk file: {}", error);
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
                error!("Problem reading CSV from bulk file: {}", error);
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
    let _start_bench_ts: DateTime<Local> = Local::now();

    let benchmark_number_partitions: usize = config
        .get("benchmark.number.partitions")
        .unwrap()
        .parse::<usize>()
        .unwrap();

    // READ the bulk file data into the partitioned collection bulk_data_partitions (config param 'file.bulk.name')
    let _partitions: Vec<Vec<(String, String)>> = load_bulk(&config, benchmark_number_partitions);

    // create a separate database connection (without auto commit behaviour) for each partition

    /*
    trial_no = 0
    WHILE trial_no < config_param 'benchmark.trials'
        DO run_trial(database connections,
                     trial_no,
                     bulk_data_partitions)
    ENDWHILE
    */
    let _trials: u32 = config
        .get("benchmark.trials")
        .unwrap()
        .parse::<u32>()
        .unwrap();

    /*
    partition_no = 0
    WHILE partition_no < config_param 'benchmark.number.partitions'
        close the database connection
    ENDWHILE
    */

    // WRITE an entry for the action 'benchmark' in the result file (config param 'file.result.name')

    debug!("End   run_benchmark()");
}

// // =============================================================================
// // Supervise function for inserting data into the database.
// // -----------------------------------------------------------------------------
//
// fn run_insert() {
//     debug!("Start run_insert()");
//
//     // save the current time as the start of the 'query' action
//
//     /*
//     partition_no = 0
//     WHILE partition_no < config_param 'benchmark.number.partitions'
//         IF config_param 'benchmark.core.multiplier' = 0
//             DO run_insert_helper(database connections(partition_no),
//                     bulk_data_partitions(partition_no))
//         ELSE
//             DO run_insert_helper (database connections(partition_no),
//                     bulk_data_partitions(partition_no)) as a thread
//         ENDIF
//     ENDWHILE
//     */
//
//     // WRITE an entry for the action 'query' in the result file (config param 'file.result.name')
//
//     debug!("End   run_insert()");
// }
//
// // =============================================================================
// // Helper function for inserting data into the database.
// // -----------------------------------------------------------------------------
//
// fn run_insert_helper() {
//     debug!("Start run_insert_helper()");
//
//     /*
//     count = 0
//     collection batch_collection = empty
//     WHILE iterating through the collection bulk_data_partition
//       count + 1
//
//       add the SQL statement in config param 'sql.insert' with the current bulk_data entry to the collection batch_collection
//
//       IF config_param 'benchmark.batch.size' > 0
//           IF count modulo config param 'benchmark.batch.size' = 0
//               execute the SQL statements in the collection batch_collection
//               batch_collection = empty
//           ENDIF
//       ENDIF
//
//       IF  config param 'benchmark.transaction.size' > 0
//       AND count modulo config param 'benchmark.transaction.size' = 0
//           commit
//       ENDIF
//     ENDWHILE
//     */
//
//     /*
//     IF collection batch_collection is not empty
//       execute the SQL statements in the collection batch_collection
//     ENDIF
//     */
//
//     // commit
//
//     debug!("End   run_insert_helper()");
// }
//
// // =============================================================================
// // Supervise function for retrieving of the database data.
// // -----------------------------------------------------------------------------
//
// fn run_select() {
//     debug!("Start run_select()");
//
//     // save the current time as the start of the 'query' action
//
//     /*
//     partition_no = 0
//     WHILE partition_no < config_param 'benchmark.number.partitions'
//         IF config_param 'benchmark.core.multiplier' = 0
//             DO run_select_helper(database connections(partition_no),
//                                  bulk_data_partitions(partition_no,
//                                  partition_no)
//         ELSE
//             DO run_select_helper(database connections(partition_no),
//                                  bulk_data_partitions(partition_no,
//                                  partition_no) as a thread
//         ENDIF
//     ENDWHILE
//     */
//
//     // WRITE an entry for the action 'query' in the result file (config param 'file.result.name')
//
//     debug!("End   run_select()");
// }
//
// // =============================================================================
// // Helper function for retrieving data from the database.
// // -----------------------------------------------------------------------------
//
// fn run_select_helper() {
//     debug!("Start run_select_helper()");
//
//     // execute the SQL statement in config param 'sql.select'
//
//     /*
//     int count = 0;
//     WHILE iterating through the result set
//         count + 1
//     ENDWHILE
//     */
//
//     /*
//     IF NOT count = size(bulk_data_partition)
//         display an error message
//     ENDIF
//     */
//
//     debug!("End   run_select_helper()");
// }
//
// // =============================================================================
// // Performing a single trial run.
// // -----------------------------------------------------------------------------
//
// fn run_trial() {
//     debug!("Start run_trial()");
//
//     // save the current time as the start of the 'trial' action
//
//     /*
//     create the database table (config param 'sql.create')
//     IF error
//         drop the database table (config param 'sql.drop')
//         create the database table (config param 'sql.create')
//     ENDIF
//     */
//
//     /*
//     DO run_insert(database connections,
//                   trial_no,
//                   bulk_data_partitions)
//     */
//
//     /*
//     DO run_select(database connections,
//                   trial_no,
//                   bulk_data_partitions)
//     */
//
//     // drop the database table (config param 'sql.drop')
//
//     // WRITE an entry for the action 'trial' in the result file (config param 'file.result.name')
//
//     debug!("End   run_trial()");
// }
