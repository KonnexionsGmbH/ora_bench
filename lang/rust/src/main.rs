#[macro_use]
extern crate log;

use env_logger::Env;

fn main() {
    let env = Env::default().filter_or("ORA_BENCH_RUST_LOG_LEVEL", "trace");

    env_logger::init_from_env(env);

    debug!("Start main()");

    orabench::run_benchmark();

    debug!("End   main()");
}

mod orabench {
    pub fn run_benchmark() {
        debug!("Start run_benchmark()");

        debug!("End   run_benchmark()");
    }
}
