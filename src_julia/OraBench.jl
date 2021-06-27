#= 
OraBench:
- Julia version: 1.6.1
- Author: Konnexions GmbH
- Date: 2021-06-26 =#

import Oracle

using Pkg
using TOML

# ------------------------------------------------------------------------------
# Definition of the global variables.
# ------------------------------------------------------------------------------

BENCHMARK_DRIVER = Pkg.status("Oracle")
BENCHMARK_LANGUAGE = "Julia " * string(VERSION)

FILE_CONFIGURATION_NAME_PYTHON = "priv/properties/ora_bench_toml.properties"

IX_DURATION_INSERT_SUM = 3
IX_DURATION_SELECT_SUM = 4
IX_LAST_BENCHMARK = 0
IX_LAST_QUERY = 2
IX_LAST_TRIAL = 1

# ------------------------------------------------------------------------------
# Loading the configuration parameters into memory.
# ------------------------------------------------------------------------------

function get_config()
    @debug "Start"
    
    config_parser::Dict = TOML.parsefile(FILE_CONFIGURATION_NAME_PYTHON)
    
    config = Dict()

    config["benchmark_batch_size"] = parse(Int64, config_parser["DEFAULT"]["benchmark_batch_size"])
    config["benchmark_comment"] = config_parser["DEFAULT"]["benchmark_comment"]
    config["benchmark_core_multiplier"] = parse(Int64, config_parser["DEFAULT"]["benchmark_core_multiplier"])
    config["benchmark_database"] = config_parser["DEFAULT"]["benchmark_database"]
    config["benchmark_host_name"] = config_parser["DEFAULT"]["benchmark_host_name"]
    config["benchmark_id"] = config_parser["DEFAULT"]["benchmark_id"]
    config["benchmark_number_cores"] = parse(Int64, config_parser["DEFAULT"]["benchmark_number_cores"])
    config["benchmark_number_partitions"] = parse(Int64, config_parser["DEFAULT"]["benchmark_number_partitions"])
    config["benchmark_os"] = config_parser["DEFAULT"]["benchmark_os"]
    config["benchmark_release"] = config_parser["DEFAULT"]["benchmark_release"]
    config["benchmark_transaction_size"] = parse(Int64, config_parser["DEFAULT"]["benchmark_transaction_size"])
    config["benchmark_trials"] = parse(Int64, config_parser["DEFAULT"]["benchmark_trials"])
    config["benchmark_user_name"] = config_parser["DEFAULT"]["benchmark_user_name"]

    config["connection_fetch_size"] = parse(Int64, config_parser["DEFAULT"]["connection_fetch_size"])
    config["connection_host"] = config_parser["DEFAULT"]["connection_host"]
    config["connection_password"] = config_parser["DEFAULT"]["connection_password"]
    config["connection_port"] = parse(Int64, config_parser["DEFAULT"]["connection_port"])
    config["connection_service"] = config_parser["DEFAULT"]["connection_service"]
    config["connection_user"] = config_parser["DEFAULT"]["connection_user"]

    config["file_bulk_delimiter"] = replace(config_parser["DEFAULT"]["file_bulk_delimiter"], "TAB" => "\t")
    config["file_bulk_length"] = parse(Int64, config_parser["DEFAULT"]["file_bulk_length"])
    config["file_bulk_name"] = config_parser["DEFAULT"]["file_bulk_name"]
    config["file_bulk_size"] = parse(Int64, config_parser["DEFAULT"]["file_bulk_size"])
    config["file_configuration_name_python"] = config_parser["DEFAULT"]["file_configuration_name_python"]
    config["file_result_delimiter"] = replace(config_parser["DEFAULT"]["file_result_delimiter"], "TAB" => "\t")
    config["file_result_name"] = config_parser["DEFAULT"]["file_result_name"]

    config["sql_create"] = config_parser["DEFAULT"]["sql_create"]
    config["sql_drop"] = config_parser["DEFAULT"]["sql_drop"]
    config["sql_insert"] = replace(replace(config_parser["DEFAULT"]["sql_insert"], ":key" => ":1"), ":data" => ":2")
    config["sql_select"] = config_parser["DEFAULT"]["sql_select"]
    
    @debug "End"
    
    return config
end
    
# ------------------------------------------------------------------------------
# Main routine.
# ------------------------------------------------------------------------------

function main()
    @debug "Start"
    @info "Start OraBench.jl"
    
    run_benchmark()

    @info "End   OraBench.jl"
    @debug "end"
end

# ------------------------------------------------------------------------------
# Performing the benchmark run.
# ------------------------------------------------------------------------------

function run_benchmark()
    @debug "Start"
    
    println("BENCHMARK_DRIVER  =" * BENCHMARK_DRIVER)
    println("BENCHMARK_LANGUAGE=" * BENCHMARK_LANGUAGE)
    
    config = get_config()

    # measurement_data_result_file = create_result_measuring_point_start_benchmark(logger, config)

    @debug "End"
end

# ------------------------------------------------------------------------------
# Entry point.
# ------------------------------------------------------------------------------

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
