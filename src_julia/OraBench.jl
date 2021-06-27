#= 
OraBench:
- Julia version: 1.6.1
- Author: Konnexions GmbH
- Date: 2021-06-26
=#

import Pkg;
Pkg.add("Oracle");

using Dates
using DelimitedFiles
using TOML

# ------------------------------------------------------------------------------
# Definition of the global variables.
# ------------------------------------------------------------------------------

BENCHMARK_DRIVER = ""
BENCHMARK_LANGUAGE = ""

FILE_CONFIGURATION_NAME_TOML = "priv/properties/ora_bench_toml.properties"

IX_DURATION_INSERT_SUM = 4
IX_DURATION_SELECT_SUM = 5
IX_LAST_BENCHMARK = 1
IX_LAST_QUERY = 3
IX_LAST_TRIAL = 2

# ------------------------------------------------------------------------------
# Creating the result file.
# ------------------------------------------------------------------------------

function create_result_file(config::Dict)
    function_name::String = string(StackTraces.stacktrace()[1].func)
    @debug "Start " * function_name

    result_file::File = open(config["file_result_name"])

    if not
        is_file(result_file)
        error_msg::String =
            "fatal error: program abort =====> result file '" +
            result_file +
            "' is missing <====="
        @error error_msg
        stop("Stopped: " * error_msg)
    end

    close(result_file)
    result_file = open(result_file, "a")

    @debug "End   " * function_name

    return result_file
end

# ------------------------------------------------------------------------------
# Recording the results of the benchmark - start processing.
# ------------------------------------------------------------------------------

function create_result_measuring_point_start_benchmark(config::Dict)
    function_name::String = string(StackTraces.stacktrace()[1].func)
    @debug "Start " * function_name

    measurement_data::Array = [nothing, nothing, nothing, 0, 0]

    # println("left="*typeof(measurement_data[IX_LAST_BENCHMARK]))

    println("rght="*typeof(now()))

    measurement_data[IX_LAST_BENCHMARK] = now()

    result_file::File = create_result_file(config)

    measurement_data_result_file::File = (measurement_data, result_file)

    @debug "End   " * function_name

    return measurement_data_result_file
end

# ------------------------------------------------------------------------------
# Loading the configuration parameters into memory.
# ------------------------------------------------------------------------------

function get_config()
    function_name::String = string(StackTraces.stacktrace()[1].func)
    @debug "Start " * function_name

    config_parser::Dict = TOML.parsefile(FILE_CONFIGURATION_NAME_TOML)

    config::Dict = Dict()

    config["benchmark_batch_size"] =
        parse(Int64, config_parser["DEFAULT"]["benchmark_batch_size"])
    config["benchmark_comment"] = config_parser["DEFAULT"]["benchmark_comment"]
    config["benchmark_core_multiplier"] =
        parse(Int64, config_parser["DEFAULT"]["benchmark_core_multiplier"])
    config["benchmark_database"] = config_parser["DEFAULT"]["benchmark_database"]
    config["benchmark_host_name"] = config_parser["DEFAULT"]["benchmark_host_name"]
    config["benchmark_id"] = config_parser["DEFAULT"]["benchmark_id"]
    config["benchmark_number_cores"] =
        parse(Int64, config_parser["DEFAULT"]["benchmark_number_cores"])
    config["benchmark_number_partitions"] =
        parse(Int64, config_parser["DEFAULT"]["benchmark_number_partitions"])
    config["benchmark_os"] = config_parser["DEFAULT"]["benchmark_os"]
    config["benchmark_release"] = config_parser["DEFAULT"]["benchmark_release"]
    config["benchmark_transaction_size"] =
        parse(Int64, config_parser["DEFAULT"]["benchmark_transaction_size"])
    config["benchmark_trials"] = parse(Int64, config_parser["DEFAULT"]["benchmark_trials"])
    config["benchmark_user_name"] = config_parser["DEFAULT"]["benchmark_user_name"]

    config["connection_fetch_size"] =
        parse(Int64, config_parser["DEFAULT"]["connection_fetch_size"])
    config["connection_host"] = config_parser["DEFAULT"]["connection_host"]
    config["connection_password"] = config_parser["DEFAULT"]["connection_password"]
    config["connection_port"] = parse(Int64, config_parser["DEFAULT"]["connection_port"])
    config["connection_service"] = config_parser["DEFAULT"]["connection_service"]
    config["connection_user"] = config_parser["DEFAULT"]["connection_user"]

    config["file_bulk_delimiter"] =
        replace(config_parser["DEFAULT"]["file_bulk_delimiter"], "TAB" => "\t")
    config["file_bulk_length"] = parse(Int64, config_parser["DEFAULT"]["file_bulk_length"])
    config["file_bulk_name"] = config_parser["DEFAULT"]["file_bulk_name"]
    config["file_bulk_size"] = parse(Int64, config_parser["DEFAULT"]["file_bulk_size"])
    config["file_configuration_name_python"] =
        config_parser["DEFAULT"]["file_configuration_name_python"]
    config["file_result_delimiter"] =
        replace(config_parser["DEFAULT"]["file_result_delimiter"], "TAB" => "\t")
    config["file_result_name"] = config_parser["DEFAULT"]["file_result_name"]

    config["sql_create"] = config_parser["DEFAULT"]["sql_create"]
    config["sql_drop"] = config_parser["DEFAULT"]["sql_drop"]
    config["sql_insert"] = replace(
        replace(config_parser["DEFAULT"]["sql_insert"], ":key" => ":1"),
        ":data" => ":2",
    )
    config["sql_select"] = config_parser["DEFAULT"]["sql_select"]

    @debug "End   " * function_name

    return config
end

# ------------------------------------------------------------------------------
# Determining the package version.
# ------------------------------------------------------------------------------

function get_pkg_version(pkg_name::String)
    function_name::String = string(StackTraces.stacktrace()[1].func)
    @debug "Start " * function_name

    m = Pkg.Operations.Context().env.manifest
    print(typeof(m))
    v = m[findfirst(v -> v.name == pkg_name, m)].version
    print(typeof(v))

    @debug "End   " * function_name

    return string(v)
end

# ------------------------------------------------------------------------------
# Main routine.
# ------------------------------------------------------------------------------

function main()
    function_name::String = string(StackTraces.stacktrace()[1].func)
    @debug "Start " * function_name

    @info "Start OraBench.jl"

    run_benchmark()

    @info "End   OraBench.jl"

    @debug "end"
end

# ------------------------------------------------------------------------------
# Performing the benchmark run.
# ------------------------------------------------------------------------------

function run_benchmark()
    function_name::String = string(StackTraces.stacktrace()[1].func)
    @debug "Start " * function_name

    config::Dict = get_config()

    measurement_data_result_file::File =
        create_result_measuring_point_start_benchmark(config)

    @debug "End   " * function_name
end

# ------------------------------------------------------------------------------
# Entry point.
# ------------------------------------------------------------------------------

if abspath(PROGRAM_FILE) == @__FILE__
    BENCHMARK_DRIVER = get_pkg_version("Oracle")
    BENCHMARK_LANGUAGE = "Julia " * string(Base.VERSION)

    main()
end
