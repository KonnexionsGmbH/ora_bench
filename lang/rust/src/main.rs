#[macro_use]
extern crate log;

use env_logger::Env;
use java_properties::{read, PropertiesError};

use std::collections::HashMap;
use std::env;
use std::fs::File;
use std::io::BufReader;

// =============================================================================
// Load properties from properties file.
// -----------------------------------------------------------------------------

fn get_config(
    file_name: String,
) -> Result<HashMap<String, String>, java_properties::PropertiesError> {
    debug!("Start get_config()");

    let file = match File::open(&file_name) {
        Ok(file) => file,
        Err(error) => {
            error!("Problem opening the properties file: {}", error);
            std::process::exit(1);
        }
    };

    let config = read(BufReader::new(file))?;

    debug!("End   get_config()");

    Ok(config)
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

    let config = get_config(file_name_config);

    run_benchmark(config);

    debug!("End   main()");
}

// =============================================================================
// Performing a complete benchmark run that can consist of several trial runs.
// -----------------------------------------------------------------------------

fn run_benchmark(_config: Result<HashMap<String, String>, PropertiesError>) {
    debug!("Start run_benchmark()");

    debug!("End   run_benchmark()");
}

// // =============================================================================
// // Supervise function for inserting data into the database.
// // -----------------------------------------------------------------------------
//
// fn run_insert() {
//     debug!("Start run_insert()");
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
//     debug!("End   run_trial()");
// }
