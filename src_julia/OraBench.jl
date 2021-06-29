#= 
OraBench:
- Julia version: 1.6.1
- Author: Konnexions GmbH
- Date: 2021-06-26
=#

import Pkg

Pkg.add("CSV")
Pkg.add("DataFrames")
Pkg.add("Formatting")
Pkg.add("Oracle")
Pkg.add("TimesDates")

using CSV
using DataFrames
using Dates
using Formatting
using Oracle
using TimesDates
using TOML

# ------------------------------------------------------------------------------
# Definition of the global variables.
# ------------------------------------------------------------------------------

BENCHMARK_DRIVER::String
BENCHMARK_LANGUAGE::String
BENCHMARK_NUMBER_PARTITIONS::UInt32

CONNECTION_HOST::String
CONNECTION_PASSWORD::String
CONNECTION_PORT::UInt32
CONNECTION_SERVICE::String
CONNECTION_USER::String

FILE_CONFIGURATION_NAME_TOML = "priv/properties/ora_bench_toml.properties"
FILE_RESULT_DELIMITER = ""

IX_DURATION_INSERT_SUM = 4
IX_DURATION_SELECT_SUM = 5
IX_LAST_BENCHMARK = 1
IX_LAST_QUERY = 3
IX_LAST_TRIAL = 2

# ------------------------------------------------------------------------------
# Creating the database connections.
# ------------------------------------------------------------------------------

function create_connections(config::Dict)
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start " * function_name

    connections = Dict()

    connection_string =
        CONNECTION_HOST *
        ":" *
        string(CONNECTION_PORT) *
        "/" *
        CONNECTION_SERVICE

    for partition_key = 1:BENCHMARK_NUMBER_PARTITIONS
        try
            connections[partition_key] =
                Oracle.Connection(connection_user, connection_password, connection_string)
            @info "wwe connection " * string(partition_key) * " open"
        catch reason
            @info "partition_key      =" * string(partition_key)
            @info "connection_user    =" * connection_user
            @info "connection_password=" * connection_password
            @info "connection_string  =" * connection_string
            error(
                "fatal error: program abort =====> database connect error: '" *
                string(reason) *
                "' <=====",
            )
        end
    end

    @debug "End   " * function_name

    return connections
end

# ------------------------------------------------------------------------------
# Writing the results.
# ------------------------------------------------------------------------------

function create_result(
    config,
    result_file,
    measurement_data,
    action,
    trial_number,
    sql_statement,
    start_date_time,
    sql_operation,
)
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start " * function_name

    end_date_time = TimeDate(now())

    duration_ns = (end_date_time - start_date_time).value

    if sql_operation == "insert"
        measurement_data[IX_DURATION_INSERT_SUM] += duration_ns
    elseif sql_operation == "select"
        measurement_data[IX_DURATION_SELECT_SUM] += duration_ns
    end

    write(
        result_file,
        config["benchmark_release"] *
        FILE_RESULT_DELIMITER *
        config["benchmark_id"] *
        FILE_RESULT_DELIMITER *
        config["benchmark_comment"] *
        FILE_RESULT_DELIMITER *
        config["benchmark_host_name"] *
        FILE_RESULT_DELIMITER *
        string(config["benchmark_number_cores"]) *
        FILE_RESULT_DELIMITER *
        config["benchmark_os"] *
        FILE_RESULT_DELIMITER *
        config["benchmark_user_name"] *
        FILE_RESULT_DELIMITER *
        config["benchmark_database"] *
        FILE_RESULT_DELIMITER *
        BENCHMARK_LANGUAGE *
        FILE_RESULT_DELIMITER *
        BENCHMARK_DRIVER *
        FILE_RESULT_DELIMITER *
        string(trial_number) *
        FILE_RESULT_DELIMITER *
        sql_statement *
        FILE_RESULT_DELIMITER *
        string(config["benchmark_core_multiplier"]) *
        FILE_RESULT_DELIMITER *
        string(config["connection_fetch_size"]) *
        FILE_RESULT_DELIMITER *
        string(config["benchmark_transaction_size"]) *
        FILE_RESULT_DELIMITER *
        string(config["file_bulk_length"]) *
        FILE_RESULT_DELIMITER *
        string(config["file_bulk_size"]) *
        FILE_RESULT_DELIMITER *
        string(config["benchmark_batch_size"]) *
        FILE_RESULT_DELIMITER *
        action *
        FILE_RESULT_DELIMITER *
        string(start_date_time) *
        FILE_RESULT_DELIMITER *
        string(end_date_time) *
        FILE_RESULT_DELIMITER *
        string(round((end_date_time - start_date_time).value * 0.001)) *
        FILE_RESULT_DELIMITER *
        string(duration_ns) *
        FILE_RESULT_DELIMITER *
        "\n",
    )

    @debug "End   " * function_name
end

# ------------------------------------------------------------------------------
# Creating the result file.
# ------------------------------------------------------------------------------

function create_result_file(config)
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start " * function_name

    result_file_name = config["file_result_name"]

    touch(result_file_name)

    if not
        isfile(result_file_name)
        error(
            "fatal error: program abort =====> result file '" *
            result_file_name *
            "' is missing <=====",
        )
    end

    result_file = open(result_file_name, "a")

    @debug "End   " * function_name

    return result_file
end

# ------------------------------------------------------------------------------
# Recording the results of the benchmark - end processing.
# ------------------------------------------------------------------------------

function create_result_measuring_point_end(
    config,
    result_file,
    measurement_data,
    action,
    trial_number = 0,
    sql_statement = "",
    sql_operation = "",
)
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start " * function_name

    if action == "query"
        create_result(
            config,
            result_file,
            measurement_data,
            action,
            trial_number,
            sql_statement,
            measurement_data[IX_LAST_QUERY],
            sql_operation,
        )
    elseif action == "trial"
        create_result(
            config,
            result_file,
            measurement_data,
            action,
            trial_number,
            sql_statement,
            measurement_data[IX_LAST_TRIAL],
            sql_operation,
        )
    elseif action == "benchmark"
        create_result(
            config,
            result_file,
            measurement_data,
            action,
            trial_number,
            sql_statement,
            measurement_data[IX_LAST_BENCHMARK],
            sql_operation,
        )
        close(result_file)
    else
        error(
            "fatal error: program abort =====> unknown action='" *
            action *
            "' status='end' <=====",
        )
    end

    @debug "End   " * function_name
end

# ------------------------------------------------------------------------------
# Recording the results of the benchmark - start processing.
# ------------------------------------------------------------------------------

function create_result_measuring_point_start_benchmark(config::Dict)
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start " * function_name

    measurement_data = Array(["", "", "", 0, 0])

    measurement_data[IX_LAST_BENCHMARK] = TimeDate(now())

    measurement_data_result_file = (measurement_data, open(config["file_result_name"], "a"))

    @debug "End   " * function_name

    return measurement_data_result_file
end

# ------------------------------------------------------------------------------
# Loading the bulk file into memory.
# ------------------------------------------------------------------------------

function get_bulk_data_partitions(config::Dict)
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start " * function_name

    file_bulk_delimiter = config["file_bulk_delimiter"]
    file_bulk_size = config["file_bulk_size"]

    if file_bulk_size < BENCHMARK_NUMBER_PARTITIONS
        error(
            "fatal error: program abort =====> size of the bulk file ($(file_bulk_size)) is smaller than the number of partitions ($(BENCHMARK_NUMBER_PARTITIONS)) <=====",
        )
    end

    bulk_data = DataFrame(
        CSV.File(config["file_bulk_name"], header = 1, delim = file_bulk_delimiter),
    )

    partition_size = div(file_bulk_size, BENCHMARK_NUMBER_PARTITIONS)

    # ------------------------------------------------------------------------------
    # Loading the bulk file into memory.
    # ------------------------------------------------------------------------------

    bulk_data_partitions = Dict()

    @info "Start Distribution of the data in the partitions"

    last_partition_upper = 0

    for partition_key = 1:BENCHMARK_NUMBER_PARTITIONS
        current_partition_upper = last_partition_upper + partition_size
        if current_partition_upper > file_bulk_size
            current_partition_upper = file_bulk_size
        end
        bulk_data_partitions[partition_key] =
            last_partition_upper + 1, current_partition_upper
        @info format(
            "Partition p{1:0>5d} contains {2:n} rows",
            partition_key,
            current_partition_upper - last_partition_upper,
        )
        last_partition_upper = current_partition_upper
    end

    @info "End   Distribution of the data in the partitions"

    @debug "End   " * function_name

    return bulk_data, bulk_data_partitions
end

# ------------------------------------------------------------------------------
# Loading the configuration parameters into memory.
# ------------------------------------------------------------------------------

function get_config()
    function_name = string(StackTraces.stacktrace()[1].func)
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
    BENCHMARK_NUMBER_PARTITIONS = 1
    # wwe   parse(Int64, config_parser["DEFAULT"]["benchmark_number_partitions"])
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
    FILE_RESULT_DELIMITER =
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
    function_name = string(StackTraces.stacktrace()[1].func)
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
    function_name = string(StackTraces.stacktrace()[1].func)
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
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start " * function_name

    config::Dict = get_config()

    measurement_data_result_file::Tuple =
        create_result_measuring_point_start_benchmark(config)

    measurement_data = measurement_data_result_file[1]
    result_file = measurement_data_result_file[2]

    bulk_data, bulk_data_partitions = get_bulk_data_partitions(config)

    connections = create_connections(config)

    for partition_key = 1:BENCHMARK_NUMBER_PARTITIONS
        Oracle.close(connections[partition_key])
        @info "connection " * string(partition_key) * " closed"
    end

    create_result_measuring_point_end(config, result_file, measurement_data, "benchmark")

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
