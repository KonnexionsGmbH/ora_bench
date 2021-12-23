extern crate chrono;
extern crate crossbeam;
#[macro_use]
extern crate log;
extern crate num_cpus;
extern crate rustc_version_runtime;

use std::env;

use env_logger::Env;

use orabench::run_benchmark;

mod orabench;

// =============================================================================
// Main function.
// -----------------------------------------------------------------------------

fn main() {
    let env = Env::default().filter_or("ORA_BENCH_RUST_LOG_LEVEL", "trace");

    env_logger::init_from_env(env);

    debug!("Start main()");

    let args: Vec<String> = env::args().collect();

    let number_args = args.len();

    println!("main() - number arguments={}", number_args);

    if number_args <= 1 {
        error!("main() - not enough command line arguments available");
        std::process::exit(1);
    }

    let file_name_config = args[1].clone();

    println!("main() - 2nd argument={}", file_name_config);

    if number_args > 2 {
        error!("main() - more than two command line arguments available");
        std::process::exit(1);
    }

    run_benchmark(file_name_config);

    debug!("End   main()");
}
