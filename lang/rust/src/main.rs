#[macro_use]
extern crate log;
extern crate chrono;

use chrono::prelude::*;
use env_logger::Env;
use java_properties::read;

use std::collections::HashMap;
use std::env;
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
    _benchmark_number_partitions: u32,
    _file_bulk_delimiter: String,
    _file_bulk_name: String,
) -> HashMap<u32, Vec<(String, String)>> {
    let partitions = HashMap::new();

    partitions
}

// =============================================================================
// Main function.
// -----------------------------------------------------------------------------

fn main() {
    let env = Env::default().filter_or("ORA_BENCH_RUST_LOG_LEVEL", "trace");

    env_logger::init_from_env(env);

    debug!("Start main()");

    let args: Vec<String> = env::args().collect();

    let number_args = args.len();

    info!("main() - number arguments={}", number_args);

    if number_args <= 1 {
        error!("main() - not enough command line arguments available");
        std::process::exit(1);
    }

    let file_name_config = args[1].clone();

    info!("main() - 2nd argument={}", file_name_config);

    if number_args > 2 {
        error!("main() - more than two command line arguments available");
        std::process::exit(1);
    }

    run_benchmark(file_name_config);

    debug!("End   main()");
}

// =============================================================================
// Performing a complete benchmark run that can consist of several trial runs.
// -----------------------------------------------------------------------------

fn run_benchmark(file_name_config: String) {
    debug!("Start run_benchmark()");

    // READ the configuration parameters into the memory (config params `file.configuration.name ...`)
    let config = get_config(file_name_config);

    // save the current time as the start of the 'benchmark' action
    let _start_bench_ts = Local::now();

    let file_bulk_delimiter = config.get("file.bulk.delimiter").unwrap().clone();
    let file_bulk_name = config.get("file.bulk.name").unwrap().clone();
    let benchmark_number_partitions = config
        .get("benchmark.number.partitions")
        .unwrap()
        .parse::<u32>()
        .unwrap();
    let _trials = config
        .get("benchmark.trials")
        .unwrap()
        .parse::<u32>()
        .unwrap();

    // READ the bulk file data into the partitioned collection bulk_data_partitions (config param 'file.bulk.name')
    let _partitions = load_bulk(
        benchmark_number_partitions,
        file_bulk_delimiter,
        file_bulk_name,
    );

    // create a separate database connection (without auto commit behaviour) for each partition

    /*
    trial_no = 0
    WHILE trial_no < config_param 'benchmark.trials'
        DO run_trial(database connections,
                     trial_no,
                     bulk_data_partitions)
    ENDWHILE
    */

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
