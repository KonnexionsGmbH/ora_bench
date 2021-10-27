mod orabench;

#[macro_use]
extern crate log;
extern crate chrono;
extern crate crossbeam;
extern crate rustc_version_runtime;

use env_logger::Env;
use orabench::run_benchmark;
use std::env;

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
