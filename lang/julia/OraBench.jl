#= 
OraBench:
- Author: Konnexions GmbH
- Date: 2021-06-26
=#

module OraBench

using Pkg

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

# ----------------------------------------------------------------------------------
# Definition of the global variables.
# ----------------------------------------------------------------------------------

global BENCHMARK_BATCH_SIZE = 0
global BENCHMARK_COMMENT = ""
global BENCHMARK_CORE_MULTIPLIER = 0
global BENCHMARK_DATABASE = ""
global BENCHMARK_DRIVER = ""
global BENCHMARK_HOST_NAME = ""
global BENCHMARK_ID = ""
global BENCHMARK_LANGUAGE = ""
global BENCHMARK_NUMBER_CORES = 0
global BENCHMARK_NUMBER_PARTITIONS = 0
global BENCHMARK_OS = ""
global BENCHMARK_RELEASE = ""
global BENCHMARK_TRANSACTION_SIZE = 0
global BENCHMARK_TRIALS = 0
global BENCHMARK_USER_NAME = ""
global BULK_DATA = nothing
global BULK_DATA_PARTITIONS = Dict()

global CONNECTION_FETCH_SIZE = 0
global CONNECTION_HOST = ""
global CONNECTION_PASSWORD = ""
global CONNECTION_PORT = 0
global CONNECTION_SERVICE = ""
global CONNECTION_USER = ""
global CONNECTIONS = Dict()

global FILE_BULK_DELIMITER = ""
global FILE_BULK_LENGTH = 0
global FILE_BULK_NAME = ""
global FILE_BULK_SIZE = 0
global FILE_CONFIGURATION_NAME_TOML = "priv/properties/ora_bench_toml.properties"
global FILE_RESULT_DELIMITER = ""
global FILE_RESULT_NAME = ""

global IX_DURATION_INSERT_SUM = 4
global IX_DURATION_SELECT_SUM = 5
global IX_LAST_BENCHMARK = 1
global IX_LAST_QUERY = 3
global IX_LAST_TRIAL = 2

global MEASUREMENT_DATA = Array(["", "", "", 0, 0])

global RESULT_FILE = nothing

global SQL_CREATE = ""
global SQL_DROP = ""
global SQL_INSERT = ""
global SQL_SELECT = ""

# ----------------------------------------------------------------------------------
# Creating the database connections.
# ----------------------------------------------------------------------------------

function create_connections()
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start $(function_name)"

    connection_string =
        CONNECTION_HOST * ":" * string(CONNECTION_PORT) * "/" * CONNECTION_SERVICE

    for partition_key = 1:BENCHMARK_NUMBER_PARTITIONS
        try
            CONNECTIONS[partition_key] =
                Oracle.Connection(CONNECTION_USER, CONNECTION_PASSWORD, connection_string)
            @info "wwe connection " * string(partition_key) * " open"
        catch reason
            @info "partition_key      =" * string(partition_key)
            @info "connection_user    =" * CONNECTION_USER
            @info "connection_password=" * CONNECTION_PASSWORD
            @info "connection_string  =" * connection_string
            error(
                "fatal error: program abort =====> database connect error: '$(string(reason))' <=====",
            )
        end
    end

    @debug "End   $(function_name)"
    nothing
end

# ----------------------------------------------------------------------------------
# Writing the results.
# ----------------------------------------------------------------------------------

function create_result(action, trial_number, sql_statement, start_date_time, sql_operation)
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start $(function_name)"

    end_date_time = TimeDate(now())

    duration_ns = (end_date_time - start_date_time).value

    if sql_operation == "insert"
        MEASUREMENT_DATA[IX_DURATION_INSERT_SUM] += duration_ns
    elseif sql_operation == "select"
        MEASUREMENT_DATA[IX_DURATION_SELECT_SUM] += duration_ns
    end

    write(
        RESULT_FILE,
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

    @debug "End   $(function_name)"
    nothing
end

# ----------------------------------------------------------------------------------
# Recording the results of the benchmark - end processing.
# ----------------------------------------------------------------------------------

function create_result_measuring_point_end(
    action,
    trial_number = 0,
    sql_statement = "",
    sql_operation = "",
)
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start $(function_name)"

    if action == "query"
        create_result(
            action,
            trial_number,
            sql_statement,
            MEASUREMENT_DATA[IX_LAST_QUERY],
            sql_operation,
        )
    elseif action == "trial"
        create_result(
            action,
            trial_number,
            sql_statement,
            MEASUREMENT_DATA[IX_LAST_TRIAL],
            sql_operation,
        )
    elseif action == "benchmark"
        create_result(
            action,
            trial_number,
            sql_statement,
            MEASUREMENT_DATA[IX_LAST_BENCHMARK],
            sql_operation,
        )
        close(RESULT_FILE)
    else
        error(
            "fatal error: program abort =====> unknown action='$(action)' status='end' <=====",
        )
    end

    @debug "End   $(function_name)"
    nothing
end

# ----------------------------------------------------------------------------------
# Recording the results of the benchmark - start processing.
# ----------------------------------------------------------------------------------

function create_result_measuring_point_start(action)
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start $(function_name)"

    if action == "query"
        MEASUREMENT_DATA[IX_LAST_QUERY] = TimeDate(now())
    elseif action == "trial"
        MEASUREMENT_DATA[IX_LAST_TRIAL] = TimeDate(now())
    else
        error(
            "fatal error: program abort =====> unknown action='$(action)' status='start' <=====",
        )
    end

    @debug "End   $(function_name)"
    nothing
end

function create_result_measuring_point_start_benchmark()
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start $(function_name)"

    MEASUREMENT_DATA[IX_LAST_BENCHMARK] = TimeDate(now())

    if !(isfile(FILE_RESULT_NAME))
        error(
            "fatal error: program abort =====> result file '$(FILE_RESULT_NAME)' is missing <=====",
        )
    end

    global RESULT_FILE = open(FILE_RESULT_NAME, "a")

    @debug "End   $(function_name)"
    nothing
end

# ----------------------------------------------------------------------------------
# Loading the bulk file into memory.
# ----------------------------------------------------------------------------------

function get_bulk_data_partitions()
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start $(function_name)"

    if FILE_BULK_SIZE < BENCHMARK_NUMBER_PARTITIONS
        error(
            "fatal error: program abort =====> size of the bulk file ($(FILE_BULK_SIZE)) is smaller than the number of partitions ($(BENCHMARK_NUMBER_PARTITIONS)) <=====",
        )
    end

    global BULK_DATA =
        DataFrame(CSV.File(FILE_BULK_NAME, header = 1, delim = FILE_BULK_DELIMITER))

    partition_size = div(FILE_BULK_SIZE, BENCHMARK_NUMBER_PARTITIONS)

    # ----------------------------------------------------------------------------------
    # Loading the bulk file into memory.
    # ----------------------------------------------------------------------------------

    @info "Start Distribution of the data in the partitions"

    last_partition_upper = 0

    for partition_key = 1:BENCHMARK_NUMBER_PARTITIONS
        current_partition_upper = last_partition_upper + partition_size
        if current_partition_upper > FILE_BULK_SIZE
            current_partition_upper = FILE_BULK_SIZE
        end
        BULK_DATA_PARTITIONS[partition_key] =
            last_partition_upper + 1, current_partition_upper
        @info format(
            "Partition p{1:0>5d} contains {2:n} rows",
            partition_key,
            current_partition_upper - last_partition_upper,
        )
        last_partition_upper = current_partition_upper
    end

    @info "End   Distribution of the data in the partitions"

    @debug "End   $(function_name)"
    nothing
end

# ----------------------------------------------------------------------------------
# Loading the configuration parameters into memory.
# ----------------------------------------------------------------------------------

function get_config()
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start $(function_name)"

    config_parser::Dict = TOML.parsefile(FILE_CONFIGURATION_NAME_TOML)

    global BENCHMARK_BATCH_SIZE =
        parse(Int64, config_parser["DEFAULT"]["benchmark_batch_size"])
    global BENCHMARK_COMMENT = config_parser["DEFAULT"]["benchmark_comment"]
    global BENCHMARK_CORE_MULTIPLIER =
        parse(Int64, config_parser["DEFAULT"]["benchmark_core_multiplier"])
    global BENCHMARK_DATABASE = config_parser["DEFAULT"]["benchmark_database"]
    global BENCHMARK_HOST_NAME = config_parser["DEFAULT"]["benchmark_host_name"]
    global BENCHMARK_ID = config_parser["DEFAULT"]["benchmark_id"]
    global BENCHMARK_NUMBER_CORES =
        parse(Int64, config_parser["DEFAULT"]["benchmark_number_cores"])
    global BENCHMARK_NUMBER_PARTITIONS = 1
    # wwe   parse(Int64, config_parser["DEFAULT"]["benchmark_number_partitions"])
    global BENCHMARK_OS = config_parser["DEFAULT"]["benchmark_os"]
    global BENCHMARK_RELEASE = config_parser["DEFAULT"]["benchmark_release"]
    global BENCHMARK_TRANSACTION_SIZE =
        parse(Int64, config_parser["DEFAULT"]["benchmark_transaction_size"])
    global BENCHMARK_TRIALS = parse(Int64, config_parser["DEFAULT"]["benchmark_trials"])
    global BENCHMARK_USER_NAME = config_parser["DEFAULT"]["benchmark_user_name"]

    global CONNECTION_FETCH_SIZE =
        parse(Int64, config_parser["DEFAULT"]["connection_fetch_size"])
    global CONNECTION_HOST = config_parser["DEFAULT"]["connection_host"]
    global CONNECTION_PASSWORD = config_parser["DEFAULT"]["connection_password"]
    global CONNECTION_PORT = parse(Int64, config_parser["DEFAULT"]["connection_port"])
    global CONNECTION_SERVICE = config_parser["DEFAULT"]["connection_service"]
    global CONNECTION_USER = config_parser["DEFAULT"]["connection_user"]

    global FILE_BULK_DELIMITER =
        replace(config_parser["DEFAULT"]["file_bulk_delimiter"], "TAB" => "\t")
    global FILE_BULK_LENGTH = parse(Int64, config_parser["DEFAULT"]["file_bulk_length"])
    global FILE_BULK_NAME = config_parser["DEFAULT"]["file_bulk_name"]
    global FILE_BULK_SIZE = parse(Int64, config_parser["DEFAULT"]["file_bulk_size"])
    global FILE_RESULT_DELIMITER =
        replace(config_parser["DEFAULT"]["file_result_delimiter"], "TAB" => "\t")
    global FILE_RESULT_NAME = config_parser["DEFAULT"]["file_result_name"]

    global SQL_CREATE = config_parser["DEFAULT"]["sql_create"]
    global SQL_DROP = config_parser["DEFAULT"]["sql_drop"]
    global SQL_INSERT = replace(
        replace(config_parser["DEFAULT"]["sql_insert"], ":key" => ":1"),
        ":data" => ":2",
    )
    global SQL_SELECT = config_parser["DEFAULT"]["sql_select"]

    @debug "End   $(function_name)"
    nothing
end

# ----------------------------------------------------------------------------------
# Performing the insert operations.
# ----------------------------------------------------------------------------------

function insert(connection, bulk_data_partition)
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start $(function_name)"

    count = 0
    batch_data = list()

#     for key_data_tuple in bulk_data_partition
#         count += 1
# 
#         if BENCHMARK_BATCH_SIZE == 0:
#             cursor.execute(SQL_SELECT, [key_data_tuple[0], key_data_tuple[1]])
#         else:
#             batch_data.append(key_data_tuple)
#             if count % BENCHMARK_BATCH_SIZE == 0:
#                 cursor.executemany(SQL_SELECT, batch_data)
#                 batch_data = list()
#             end
#         end
# 
#         if BENCHMARK_TRANSACTION_SIZE > 0 and count % BENCHMARK_TRANSACTION_SIZE == 0:
#             connection.commit()
#     end
# 
#     if BENCHMARK_BATCH_SIZE > 0 and batch_data.__len__() > 0:
#         cursor.executemany(SQL_SELECT, batch_data)
#     end
# 
#     if BENCHMARK_TRANSACTION_SIZE == 0 or count % BENCHMARK_TRANSACTION_SIZE != 0:
#         connection.commit()
#     end

    @debug "End   $(function_name)"
    nothing
end

# ----------------------------------------------------------------------------------
# Main function.
# ----------------------------------------------------------------------------------

function main()
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start $(function_name)"

    @info "Start OraBench.jl"

    m = Pkg.Operations.Context().env.manifest
    v = m[findfirst(v -> v.name == "Oracle", m)].version

    global BENCHMARK_DRIVER = "Oracle.jl " * v
    @info "wwe BENCHMARK_DRIVER=" + BENCHMARK_DRIVER
    global BENCHMARK_LANGUAGE = "Julia " * string(Base.VERSION)
    @info "wwe BENCHMARK_LANGUAGE=" + BENCHMARK_LANGUAGE

    # run_benchmark()

    @info "End   OraBench.jl"

    @debug "End   $(function_name)"
    nothing
end

# ----------------------------------------------------------------------------------
# Performing the benchmark run.
# ----------------------------------------------------------------------------------

function run_benchmark()
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start $(function_name)"

    create_result_measuring_point_start_benchmark()

    get_config()

    get_bulk_data_partitions()

    create_connections()

    for trial_number = 1:BENCHMARK_TRIALS
        run_trial(trial_number)
    end

    for partition_key = 1:BENCHMARK_NUMBER_PARTITIONS
        Oracle.close(CONNECTIONS[partition_key])
        @info "wwe connection " * string(partition_key) * " closed"
    end

    create_result_measuring_point_end("benchmark")

    @debug "End   $(function_name)"
    nothing
end

# ----------------------------------------------------------------------------------
# Performing the insert operations.
# ----------------------------------------------------------------------------------

function run_insert(trial_number)
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start $(function_name)"

#     create_result_measuring_point_start('query')
# 
#     threads = list()
# 
#     for partition_key in 1: BENCHMARK_NUMBER_PARTITIONS
#         if BENCHMARK_CORE_MULTIPLIER == 0:
#             insert(connections[partition_key], bulk_data_partitions[partition_key])
#         else
#             thread = threading.Thread(target=insert, args=(config, connections[partition_key], cursors[partition_key], bulk_data_partitions[partition_key],))
#             threads.append(thread)
#             thread.start()
#          end
#     end        
# 
#     if BENCHMARK_CORE_MULTIPLIER > 0
#         for thread in threads:
#             thread.join()
#         end
#     end        
# 
#     create_result_measuring_point_end('query', trial_number, SQL_SELECT, 'insert')

    @debug "End   $(function_name)"
    nothing
end

# ----------------------------------------------------------------------------------
# Performing one trial.
# ----------------------------------------------------------------------------------

function run_trial(trial_number)
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start $(function_name)"

    create_result_measuring_point_start("trial")

    @info "Start trial no. $(string(trial_number))"

    try
        Oracle.execute(CONNECTIONS[1], SQL_CREATE)
        @debug "last DDL statement=$(SQL_CREATE)"
    catch
        Oracle.execute(CONNECTIONS[1], SQL_DROP)
        Oracle.execute(CONNECTIONS[1], SQL_CREATE)
        @debug "last DDL statement after DROP=$(SQL_CREATE)"
    end

            run_insert(
                trial_number,
            )

    #     run_select(trial_number)

    Oracle.execute(CONNECTIONS[1], SQL_DROP)
    @debug "last DDL statement=$(SQL_DROP)"

    create_result_measuring_point_end("trial", trial_number)

    @debug "End   $(function_name)"
    nothing
end


# ----------------------------------------------------------------------------------
# Entry point.
# ----------------------------------------------------------------------------------

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end
