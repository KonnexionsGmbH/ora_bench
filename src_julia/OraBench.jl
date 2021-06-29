#= 
OraBench:
- Julia version: 1.6.1
- Author: Konnexions GmbH
- Date: 2021-06-26 =#

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

BENCHMARK_BATCH_SIZE::UInt
BENCHMARK_COMMENT::String
BENCHMARK_CORE_MULTIPLIER::UInt
BENCHMARK_DATABASE::String
BENCHMARK_DRIVER::String
BENCHMARK_HOST_NAME::String 
BENCHMARK_ID::String 
BENCHMARK_LANGUAGE::String
BENCHMARK_NUMBER_CORES::UInt
BENCHMARK_NUMBER_PARTITIONS::Uint 
BENCHMARK_OS::String 
BENCHMARK_RELEASE::String
BENCHMARK_TRANSACTION_SIZE::UInt
BENCHMARK_TRIALS::UInt 
BENCHMARK_USER_NAME::String

CONNECTION_FETCH_SIZE::UInt
CONNECTION_HOST::String
CONNECTION_PASSWORD::String
CONNECTION_PORT::UInt
CONNECTION_SERVICE::String
CONNECTION_USER::String

FILE_BULK_DELIMITER::String
FILE_BULK_LENGTH::UInt 
FILE_BULK_NAME::String
FILE_BULK_SIZE::UInt 
FILE_CONFIGURATION_NAME_TOML = "priv/properties/ora_bench_toml.properties"
FILE_RESULT_DELIMITER::String
FILE_RESULT_NAME::String 

IX_DURATION_INSERT_SUM = 4
IX_DURATION_SELECT_SUM = 5
IX_LAST_BENCHMARK = 1
IX_LAST_QUERY = 3
IX_LAST_TRIAL = 2

SQL_CREATE::String
SQL_DROP::String 
SQL_INSERT::String
SQL_SELECT::String

# ------------------------------------------------------------------------------
# Creating the database connections.
# ------------------------------------------------------------------------------

function create_connections()
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
            @info "connection_user    =" * CONNECTION_USER
            @info "connection_password=" * CONNECTION_PASSWORD
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
        BENCHMARK_RELEASE *
        FILE_RESULT_DELIMITER *
        BENCHMARK_ID *
        FILE_RESULT_DELIMITER *
        BENCHMARK_COMMENT *
        FILE_RESULT_DELIMITER *
        BENCHMARK_HOST_NAME *
        FILE_RESULT_DELIMITER *
        string(BENCHMARK_NUMBER_CORES) *
        FILE_RESULT_DELIMITER *
        BENCHMARK_OS *
        FILE_RESULT_DELIMITER *
        BENCHMARK_USER_NAME *
        FILE_RESULT_DELIMITER *
        BENCHMARK_DATABASE *
        FILE_RESULT_DELIMITER *
        BENCHMARK_LANGUAGE *
        FILE_RESULT_DELIMITER *
        BENCHMARK_DRIVER *
        FILE_RESULT_DELIMITER *
        string(trial_number) *
        FILE_RESULT_DELIMITER *
        sql_statement *
        FILE_RESULT_DELIMITER *
        string(BENCHMARK_CORE_MULTIPLIER) *
        FILE_RESULT_DELIMITER *
        string(CONNECTION_FETCH_SIZE) *
        FILE_RESULT_DELIMITER *
        string(BENCHMARK_TRANSACTION_SIZE) *
        FILE_RESULT_DELIMITER *
        string(FILE_BULK_LENGTH) *
        FILE_RESULT_DELIMITER *
        string(FILE_BULK_SIZE) *
        FILE_RESULT_DELIMITER *
        string(BENCHMARK_BATCH_SIZE) *
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

function create_result_file()
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start " * function_name

    touch(RESULT_FILE_NAME)

    if not
        isfile(RESULT_FILE_NAME)
        error(
            "fatal error: program abort =====> result file '" *
            RESULT_FILE_NAME *
            "' is missing <=====",
        )
    end

    result_file = open(RESULT_FILE_NAME, "a")

    @debug "End   " * function_name

    return result_file
end

# ------------------------------------------------------------------------------
# Recording the results of the benchmark - end processing.
# ------------------------------------------------------------------------------

function create_result_measuring_point_end(
    result_file,
    measurement_data,
    action,
    trial_number=0,
    sql_statement="",
    sql_operation="",
)
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start " * function_name

    if action == "query"
        create_result(
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

function create_result_measuring_point_start_benchmark()
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start " * function_name

    measurement_data = Array(["", "", "", 0, 0])

    measurement_data[IX_LAST_BENCHMARK] = TimeDate(now())

    measurement_data_result_file = (measurement_data, open(FILE_RESULT_NAME, "a"))

    @debug "End   " * function_name

    return measurement_data_result_file
end

# ------------------------------------------------------------------------------
# Loading the bulk file into memory.
# ------------------------------------------------------------------------------

function get_bulk_data_partitions()
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start " * function_name

    if FILE_BULK_SIZE < BENCHMARK_NUMBER_PARTITIONS
        error(
            "fatal error: program abort =====> size of the bulk file ($(FILE_BULK_SIZE)) is smaller than the number of partitions ($(BENCHMARK_NUMBER_PARTITIONS)) <=====",
        )
    end

    bulk_data = DataFrame(
        CSV.File(FILE_BULK_NAME, header=1, delim=FILE_BULK_DELIMITER),
    )

    partition_size = div(FILE_BULK_SIZE, BENCHMARK_NUMBER_PARTITIONS)

    # ------------------------------------------------------------------------------
    # Loading the bulk file into memory.
    # ------------------------------------------------------------------------------

    bulk_data_partitions = Dict()

    @info "Start Distribution of the data in the partitions"

    last_partition_upper = 0

    for partition_key = 1:BENCHMARK_NUMBER_PARTITIONS
        current_partition_upper = last_partition_upper + partition_size
        if current_partition_upper > FILE_BULK_SIZE
            current_partition_upper = FILE_BULK_SIZE
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

    BENCHMARK_BATCH_SIZE =
        parse(Int64, config_parser["DEFAULT"]["benchmark_batch_size"])
    BENCHMARK_COMMENT = config_parser["DEFAULT"]["benchmark_comment"]
    BENCHMARK_CORE_MULTIPLIER =
        parse(Int64, config_parser["DEFAULT"]["benchmark_core_multiplier"])
    BENCHMARK_DATABASE = config_parser["DEFAULT"]["benchmark_database"]
    BENCHMARK_HOST_NAME = config_parser["DEFAULT"]["benchmark_host_name"]
    BENCHMARK_ID = config_parser["DEFAULT"]["benchmark_id"]
    BENCHMARK_NUMBER_CORES =
        parse(Int64, config_parser["DEFAULT"]["benchmark_number_cores"])
    BENCHMARK_NUMBER_PARTITIONS = 1
    # wwe   parse(Int64, config_parser["DEFAULT"]["benchmark_number_partitions"])
    BENCHMARK_OS = config_parser["DEFAULT"]["benchmark_os"]
    BENCHMARK_RELEASE = config_parser["DEFAULT"]["benchmark_release"]
    BENCHMARK_TRANSACTION_SIZE =
        parse(Int64, config_parser["DEFAULT"]["benchmark_transaction_size"])
    BENCHMARK_TRIALS = parse(Int64, config_parser["DEFAULT"]["benchmark_trials"])
    BENCHMARK_USER_NAME = config_parser["DEFAULT"]["benchmark_user_name"]

    CONNECTION_FETCH_SIZE =
        parse(Int64, config_parser["DEFAULT"]["connection_fetch_size"])
    CONNECTION_HOST = config_parser["DEFAULT"]["connection_host"]
    CONNECTION_PASSWORD = config_parser["DEFAULT"]["connection_password"]
    CONNECTION_PORT = parse(Int64, config_parser["DEFAULT"]["connection_port"])
    CONNECTION_SERVICE = config_parser["DEFAULT"]["connection_service"]
    CONNECTION_USER = config_parser["DEFAULT"]["connection_user"]

    FILE_BULK_DELIMITER =
        replace(config_parser["DEFAULT"]["file_bulk_delimiter"], "TAB" => "\t")
    FILE_BULK_LENGTH = parse(Int64, config_parser["DEFAULT"]["file_bulk_length"])
    FILE_BULK_NAME = config_parser["DEFAULT"]["file_bulk_name"]
    FILE_BULK_SIZE = parse(Int64, config_parser["DEFAULT"]["file_bulk_size"])
    FILE_RESULT_DELIMITER =
        replace(config_parser["DEFAULT"]["file_result_delimiter"], "TAB" => "\t")
    FILE_RESULT_NAME = config_parser["DEFAULT"]["file_result_name"]

    SQL_CREATE = config_parser["DEFAULT"]["sql_create"]
    SQL_DROP = config_parser["DEFAULT"]["sql_drop"]
    SQL_INSERT = replace(
        replace(config_parser["DEFAULT"]["sql_insert"], ":key" => ":1"),
        ":data" => ":2",
    )
    SQL_SELECT = config_parser["DEFAULT"]["sql_select"]

    @debug "End   " * function_name
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

    get_config()

    measurement_data_result_file::Tuple =
        create_result_measuring_point_start_benchmark()

    measurement_data = measurement_data_result_file[1]
    result_file = measurement_data_result_file[2]

    bulk_data, bulk_data_partitions = get_bulk_data_partitions()

    connections = create_connections()

    for partition_key = 1:BENCHMARK_NUMBER_PARTITIONS
        Oracle.close(connections[partition_key])
        @info "connection " * string(partition_key) * " closed"
    end

    create_result_measuring_point_end(result_file, measurement_data, "benchmark")

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
