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

using Base.Threads
using CSV
using DataFrames
using Dates
using Formatting
using Logging
using Oracle
using TOML
using TimesDates

# ----------------------------------------------------------------------------------
# Definition of the global variables.
# ----------------------------------------------------------------------------------

global BENCHMARK_DRIVER = ""::String
global BENCHMARK_LANGUAGE = ""::String
global BENCHMARK_TRANSACTION_SIZE = 0::Int64

global IX_DURATION_INSERT_SUM = 4::Int64
global IX_DURATION_SELECT_SUM = 5::Int64
global IX_LAST_BENCHMARK = 1::Int64
global IX_LAST_QUERY = 3::Int64
global IX_LAST_TRIAL = 2::Int64

global MEASUREMENT_DATA =
    Array([""::String, ""::String, ""::String, 0::Int64, 0::Int64])::Vector{Any}

# ----------------------------------------------------------------------------------
# Creating the database connections.
# ----------------------------------------------------------------------------------

function create_connections(
    benchmark_number_partitions::Int64,
    connection_user::String,
    connection_password::String,
    connection_string::String,
)::Dict{Int64,Oracle.Connection}
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start $(function_name)"

    connections = Dict{Int64,Oracle.Connection}()

    for partition_key = 1:benchmark_number_partitions
        try
            @debug "      $(function_name) Connection #$(partition_key) - to be openend"
            connections[partition_key] =
                Oracle.Connection(connection_user, connection_password, connection_string)
            @debug "      $(function_name) Connection #$(partition_key) - is now open"
        catch reason
            @info "partition_key      =" * string(partition_key)
            @info "connection_user    =" * connection_user
            @info "connection_password=" * connection_password
            @info "connection_string  =" * connection_string
            error(
                "fatal error: program abort =====> database connect error: '$(string(reason))' <=====",
            )
        end
    end

    @debug "End   $(function_name)"
    return connections
end

# ----------------------------------------------------------------------------------
# Writing the results.
# ----------------------------------------------------------------------------------

function create_result(
    config::Dict{String,Any},
    result_file::IOStream,
    action::String,
    trial_number::Int64,
    sql_statement::String,
    start_date_time::TimesDates.TimeDate,
    sql_operation::String,
)
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start $(function_name)"

    end_date_time = TimeDate(now())
    duration_ns = (end_date_time - start_date_time).value
    file_result_delimiter =
        replace(config["DEFAULT"]["file_result_delimiter"], "TAB" => "\t")

    if sql_operation == "insert"
        MEASUREMENT_DATA[IX_DURATION_INSERT_SUM] += duration_ns
    elseif sql_operation == "select"
        MEASUREMENT_DATA[IX_DURATION_SELECT_SUM] += duration_ns
    end

    write(
        result_file,
        config["DEFAULT"]["benchmark_release"] *
        file_result_delimiter *
        config["DEFAULT"]["benchmark_id"] *
        file_result_delimiter *
        config["DEFAULT"]["benchmark_comment"] *
        file_result_delimiter *
        config["DEFAULT"]["benchmark_host_name"] *
        file_result_delimiter *
        config["DEFAULT"]["benchmark_number_cores"] *
        file_result_delimiter *
        config["DEFAULT"]["benchmark_os"] *
        file_result_delimiter *
        config["DEFAULT"]["benchmark_user_name"] *
        file_result_delimiter *
        config["DEFAULT"]["benchmark_database"] *
        file_result_delimiter *
        BENCHMARK_LANGUAGE *
        file_result_delimiter *
        BENCHMARK_DRIVER *
        file_result_delimiter *
        string(trial_number) *
        file_result_delimiter *
        sql_statement *
        file_result_delimiter *
        string(parse(Int64, config["DEFAULT"]["benchmark_core_multiplier"])) *
        file_result_delimiter *
        config["DEFAULT"]["connection_fetch_size"] *
        file_result_delimiter *
        config["DEFAULT"]["benchmark_transaction_size"] *
        file_result_delimiter *
        config["DEFAULT"]["file_bulk_length"] *
        file_result_delimiter *
        string(parse(Int64, config["DEFAULT"]["file_bulk_size"])) *
        file_result_delimiter *
        string(parse(Int64, config["DEFAULT"]["benchmark_batch_size"])) *
        file_result_delimiter *
        action *
        file_result_delimiter *
        string(start_date_time) *
        file_result_delimiter *
        string(end_date_time) *
        file_result_delimiter *
        string(round((end_date_time - start_date_time).value * 0.001)) *
        file_result_delimiter *
        string(duration_ns) *
        file_result_delimiter *
        "\n",
    )

    @debug "End   $(function_name)"
    nothing
end

# ----------------------------------------------------------------------------------
# Recording the results of the benchmark - end processing.
# ----------------------------------------------------------------------------------

function create_result_measuring_point_end(
    config::Dict{String,Any},
    result_file::IOStream,
    action::String,
    trial_number::Int64 = 0,
    sql_statement::String = "",
    sql_operation::String = "",
)
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start $(function_name)"

    if action == "query"
        create_result(
            config,
            result_file,
            action,
            trial_number,
            sql_statement,
            MEASUREMENT_DATA[IX_LAST_QUERY],
            sql_operation,
        )
    elseif action == "trial"
        create_result(
            config,
            result_file,
            action,
            trial_number,
            sql_statement,
            MEASUREMENT_DATA[IX_LAST_TRIAL],
            sql_operation,
        )
    elseif action == "benchmark"
        create_result(
            config,
            result_file,
            action,
            trial_number,
            sql_statement,
            MEASUREMENT_DATA[IX_LAST_BENCHMARK],
            sql_operation,
        )
        close(result_file)
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

function create_result_measuring_point_start(action::String)
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

function create_result_measuring_point_start_benchmark(config::Dict{String,Any})::IOStream
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start $(function_name)"

    MEASUREMENT_DATA[IX_LAST_BENCHMARK] = TimeDate(now())

    file_result_name = config["DEFAULT"]["file_result_name"]

    result_file = open(file_result_name, "a")

    if !(isfile(file_result_name))
        error(
            "fatal error: program abort =====> result file '$(file_result_name)' is missing <=====",
        )
    end

    @debug "End   $(function_name)"
    return result_file
end

# ----------------------------------------------------------------------------------
# Loading the bulk file into memory.
# ----------------------------------------------------------------------------------

function get_bulk_data_partitions(
    config::Dict{String,Any},
)::Dict{Int64,DataFrames.DataFrame}
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start $(function_name)"

    benchmark_number_partitions =
        parse(Int64, config["DEFAULT"]["benchmark_number_partitions"])
    file_bulk_name = config["DEFAULT"]["file_bulk_name"]

    if !(isfile(file_bulk_name))
        error(
            "fatal error: program abort =====> bulk file '$(file_bulk_name)' is missing <=====",
        )
    end

    file_bulk_size = parse(Int64, config["DEFAULT"]["file_bulk_size"])

    if file_bulk_size < benchmark_number_partitions
        error(
            "fatal error: program abort =====> size of the bulk file ($(file_bulk_size)) is smaller than the number of partitions ($(benchmark_number_partitions)) <=====",
        )
    end

    bulk_data = DataFrame(
        CSV.File(
            file_bulk_name,
            header = 1,
            delim = replace(config["DEFAULT"]["file_bulk_delimiter"], "TAB" => "\t"),
        ),
    )::DataFrames.DataFrame

    partition_size = div(file_bulk_size, benchmark_number_partitions)

    # ----------------------------------------------------------------------------------
    # Loading the bulk file into memory.
    # ----------------------------------------------------------------------------------

    @info "Start Distribution of the data in the partitions"

    bulk_data_partitions = Dict{Int64,DataFrames.DataFrame}()

    last_partition_upper = 0

    for partition_key = 1:benchmark_number_partitions
        current_partition_upper = last_partition_upper + partition_size
        last_partition_upper = last_partition_upper + 1
        if current_partition_upper > file_bulk_size
            current_partition_upper = file_bulk_size
        end
        bulk_data_partitions[partition_key] =
            bulk_data[last_partition_upper:current_partition_upper, :]::DataFrames.DataFrame
        @info format(
            "Partition p{1:0>5d} contains {2:n} rows",
            partition_key,
            size(bulk_data_partitions[partition_key], 1),
        )
        last_partition_upper = current_partition_upper
    end

    @info "End   Distribution of the data in the partitions"

    @debug "End   $(function_name)"
    return bulk_data_partitions
end

# ----------------------------------------------------------------------------------
# Loading the configuration parameters into memory.
# ----------------------------------------------------------------------------------

function load_config(configFile::String)::Dict{String,Any}
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start $(function_name)"

    config = TOML.parsefile(configFile)::Dict{String,Any}

    #     global SQL_SELECT = config["DEFAULT"]["sql_select"]

    @debug "End   $(function_name)"
    return config
end

# ----------------------------------------------------------------------------------
# Main function.
# ----------------------------------------------------------------------------------

function main()
    logger = SimpleLogger(stdout, Logging.Debug)
    logger = SimpleLogger(stdout, Logging.Info)
    old_logger = global_logger(logger)

    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start $(function_name)"

    @info "Start OraBench.jl - Number Threads: $(Threads.nthreads())"

    m = Pkg.Operations.Context().env.manifest
    v = m[findfirst(v -> v.name == "Oracle", m)].version

    global BENCHMARK_DRIVER = "Oracle.jl $(string(v))"
    global BENCHMARK_LANGUAGE = "Julia $(string(Base.VERSION))"

    numberArgs = size(ARGS, 1)

    @info "main() - number arguments=$(numberArgs)"

    if numberArgs == 0
        @error "main() - no command line argument available"
        throw(ArgumentError)
    end

    @info "main() - 1st argument=$(ARGS[1])"

    if numberArgs > 1
        @error "main() - more than one command line argument available"
        throw(ArgumentError)
    end

    # READ the configuration parameters into the memory (config params `file.configuration.name ...`)
    config = load_config(ARGS[1])

    run_benchmark(config)

    @info "End   OraBench.jl"

    @debug "End   $(function_name)"
    nothing
end

# ----------------------------------------------------------------------------------
# Performing a complete benchmark run that can consist of several trial runs.
# ----------------------------------------------------------------------------------

function run_benchmark(config::Dict{String,Any})
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start $(function_name)"

    # save the current time as the start of the 'benchmark' action
    result_file = create_result_measuring_point_start_benchmark(config)

    # READ the bulk file data into the partitioned collection bulk_data_partitions (config param 'file.bulk.name')
    bulk_data_partitions = get_bulk_data_partitions(config)

    # create a separate database connection (without auto commit behaviour) for each partition
    benchmark_number_partitions =
        parse(Int64, config["DEFAULT"]["benchmark_number_partitions"])::Int64
    connections = create_connections(
        benchmark_number_partitions,
        config["DEFAULT"]["connection_user"]::String,
        config["DEFAULT"]["connection_password"]::String,
        "$(config["DEFAULT"]["connection_host"]::String):$(config["DEFAULT"]["connection_port"]::String)/$(config["DEFAULT"]["connection_service"]::String)",
    )
    @debug "Number of database connections $(length(connections))"

    #=
    trial_no = 0
    WHILE trial_no < config_param 'benchmark.trials'
        DO run_trial(database connections,
                     trial_no,
                     bulk_data_partitions)
    ENDWHILE
    =#
    for trial_number = 1:parse(Int64, config["DEFAULT"]["benchmark_trials"])
        run_trial(config, result_file, connections, bulk_data_partitions, trial_number)
    end

    #=
    partition_no = 0
    WHILE partition_no < config_param 'benchmark.number.partitions'
        close the database connection
    ENDWHILE
    =#
    for partition_key = 1:benchmark_number_partitions
        @debug "      $(function_name) Connection #$(partition_key) - to be closed"
        Oracle.close(connections[partition_key])
        @debug "      $(function_name) Connection #$(partition_key) - is now closed"
    end

    # WRITE an entry for the action 'benchmark' in the result file (config param 'file.result.name')
    create_result_measuring_point_end(config, result_file, "benchmark")

    @debug "End   $(function_name)"
    nothing
end

# ----------------------------------------------------------------------------------
# Supervise function for inserting data into the database.
# ----------------------------------------------------------------------------------

function run_insert(
    config::Dict{String,Any},
    result_file::IOStream,
    connections::Dict{Int64,Oracle.Connection},
    bulk_data_partitions::Dict{Int64,DataFrames.DataFrame},
    trial_number::Int64,
)
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start $(function_name) - trial_number=$(trial_number)"

    # save the current time as the start of the 'query' action
    create_result_measuring_point_start("query")

    #=
    partition_no = 0
    WHILE partition_no < config_param 'benchmark.number.partitions'
        IF config_param 'benchmark.core.multiplier' = 0
            DO run_insert_helper(database connections(partition_no),
                    bulk_data_partitions(partition_no))
        ELSE
            DO run_insert_helper (database connections(partition_no),
                    bulk_data_partitions(partition_no)) as a thread
        ENDIF
    ENDWHILE
    =#
    for partition_key = 1:parse(Int64, config["DEFAULT"]["benchmark_number_partitions"])
        @info "Start partition_key no. $(partition_key) - size $(size(bulk_data_partitions[partition_key], 1))"
        if parse(Int64, config["DEFAULT"]["benchmark_core_multiplier"]) == 0
            run_insert_helper(
                config,
                connections[partition_key],
                bulk_data_partitions[partition_key],
            )
        else
            Threads.@spawn run_insert_helper(
                config,
                connections[partition_key],
                bulk_data_partitions[partition_key],
            )
        end
    end

    # WRITE an entry for the action 'query' in the result file (config param 'file.result.name')
    create_result_measuring_point_end(
        config,
        result_file,
        "query",
        trial_number,
        config["DEFAULT"]["sql_insert"],
        "insert",
    )

    @debug "End   $(function_name) - trial_number=$(trial_number)"
    nothing
end

# ----------------------------------------------------------------------------------
# Helper function for inserting data into the database.
# ----------------------------------------------------------------------------------

function run_insert_helper(
    config::Dict{String,Any},
    connection::Oracle.Connection,
    bulk_data_partition::DataFrames.DataFrame,
)
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start $(function_name)"

    #=
    count = 0
    collection batch_collection = empty
    WHILE iterating through the collection bulk_data_partition
        count + 1

        add the SQL statement in config param 'sql.insert' with the current bulk_data entry to the collection batch_collection

        IF config_param 'benchmark.batch.size' > 0
            IF count modulo config param 'benchmark.batch.size' = 0
                execute the SQL statements in the collection batch_collection
                batch_collection = empty
            ENDIF
        ENDIF

        IF  config param 'benchmark.transaction.size' > 0
        AND count modulo config param 'benchmark.transaction.size' = 0
            commit
        ENDIF
    ENDWHILE
    =#
    benchmark_batch_size = parse(Int64, config["DEFAULT"]["benchmark_batch_size"])
    benchmark_transaction_size =
        parse(Int64, config["DEFAULT"]["benchmark_transaction_size"])
    sql_insert = replace(replace(config["DEFAULT"]["sql_insert"], ":key" => ":1"), ":data" => ":2")::String

    stmt = Oracle.Stmt(connection, sql_insert)::Oracle.Stmt{Oracle.ORA_STMT_TYPE_INSERT}

    count = 0
    batch_collection = Oracle.Stmt{Oracle.ORA_STMT_TYPE_INSERT}[]

    for bulk_data_row in eachrow(bulk_data_partition)
        count += 1

        if benchmark_batch_size == 0
            stmt[:1] = bulk_data_row.key
            stmt[:2] = bulk_data_row.data
            Oracle.execute(stmt)
        else
            append(batch_collection, stmt)
            if mod(count, benchmark_batch_size) == 0
                Oracle.execute(stmt)
                batch_collection = Oracle.Stmt{Oracle.ORA_STMT_TYPE_INSERT}[]
            end
        end

        if benchmark_transaction_size > 0
            if mod(count, benchmark_transaction_size) == 0
                Oracle.execute(connection, "commit")
            end
        end
    end

    #=
    IF collection batch_collection is not empty
        execute the SQL statements in the collection batch_collection
    ENDIF
    =#


    # commit
    Oracle.execute(connection, "commit")

    Oracle.close(stmt)

    @debug "End   $(function_name)"
    nothing
end

# ----------------------------------------------------------------------------------
# Supervise function for retrieving of the database data.
# ----------------------------------------------------------------------------------

function run_select(
    config::Dict{String,Any},
    result_file::IOStream,
    connections::Dict{Int64,Oracle.Connection},
    bulk_data_partitions::Dict{Int64,DataFrames.DataFrame},
    trial_number::Int64,
)
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start $(function_name) - trial_number=$(trial_number)"

    # save the current time as the start of the 'query' action
    create_result_measuring_point_start("query")

    #=
    partition_no = 0
    WHILE partition_no < config_param 'benchmark.number.partitions'
        IF config_param 'benchmark.core.multiplier' = 0
            DO run_select_helper(database connections(partition_no),
                                 bulk_data_partitions(partition_no,
                                 partition_no)
        ELSE
            DO run_select_helper(database connections(partition_no),
                                 bulk_data_partitions(partition_no,
                                 partition_no) as a thread
        ENDIF
    ENDWHILE
    =#

    # WRITE an entry for the action 'query' in the result file (config param 'file.result.name')
    create_result_measuring_point_end(
        config,
        result_file,
        "query",
        trial_number,
        config["DEFAULT"]["sql_select"],
        "select",
    )

    @debug "End   $(function_name) - trial_number=$(trial_number)"
    nothing
end

# ----------------------------------------------------------------------------------
# Helper function for retrieving data from the database.
# ----------------------------------------------------------------------------------

function run_select_helper(
    connection::Oracle.Connection,
    bulk_data_partition::DataFrames.DataFrame,
)
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start $(function_name)"

    # execute the SQL statement in config param 'sql.select'

    #=
    int count = 0;
    WHILE iterating through the result set
        count + 1
    ENDWHILE
    =#

    #=
    IF NOT count = size(bulk_data_partition)
        display an error message
    ENDIF
    =#

    @debug "End   $(function_name)"
    nothing
end

# ----------------------------------------------------------------------------------
# Performing a single trial run.
# ----------------------------------------------------------------------------------

function run_trial(
    config::Dict{String,Any},
    result_file::IOStream,
    connections::Dict{Int64,Oracle.Connection},
    bulk_data_partitions::Dict{Int64,DataFrames.DataFrame},
    trial_number::Int64,
)
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start $(function_name) - trial_number=$(trial_number)"

    # save the current time as the start of the 'trial' action
    create_result_measuring_point_start("trial")

    @info "Start trial no. $(string(trial_number))"

    #=
    create the database table (config param 'sql.create')
    IF error
        drop the database table (config param 'sql.drop')
        create the database table (config param 'sql.create')
    ENDIF
    =#
    sql_create = config["DEFAULT"]["sql_create"]
    sql_drop = config["DEFAULT"]["sql_drop"]
    try
        Oracle.execute(connections[1], sql_create)
        @debug "last DDL statement=$(sql_create)"
    catch
        Oracle.execute(connections[1], sql_drop)
        Oracle.execute(connections[1], sql_create)
        @debug "last DDL statement after DROP=$(sql_create)"
    end

    #=
    DO run_insert(database connections,
                  trial_no,
                  bulk_data_partitions)
    =#
    run_insert(config, result_file, connections, bulk_data_partitions, trial_number)

    #=
    DO run_select(database connections,
                  trial_no,
                  bulk_data_partitions)
    =#
    run_select(config, result_file, connections, bulk_data_partitions, trial_number)

    # drop the database table (config param 'sql.drop')
    Oracle.execute(connections[1], sql_drop)
    @debug "last DDL statement=$(sql_drop)"

    # WRITE an entry for the action 'trial' in the result file (config param 'file.result.name')
    create_result_measuring_point_end(config, result_file, "trial", trial_number)

    @debug "End   $(function_name) - trial_number=$(trial_number)"
    nothing
end


# ----------------------------------------------------------------------------------
# Entry point.
# ----------------------------------------------------------------------------------

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end
