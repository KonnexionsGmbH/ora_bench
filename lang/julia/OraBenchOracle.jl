#=
OraBenchOracle:
- Author: Konnexions GmbH
- Date: 2021-06-26
=#

module OraBenchOracle

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
# Creating the database connections.
# ----------------------------------------------------------------------------------

function create_connections(
    benchmark_number_partitions::Int64,
    config::Dict{String,Any},
)::Tuple{Oracle.Pool,Dict{Int64,Oracle.Connection}}
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "\nStart $(function_name)"

    connection_user = config["DEFAULT"]["connection_user"]::String
    connection_password = config["DEFAULT"]["connection_password"]::String
    connection_string = "$(config["DEFAULT"]["connection_host"]::String):$(config["DEFAULT"]["connection_port"]::String)/$(config["DEFAULT"]["connection_service"]::String)"

    pool = Oracle.Pool(
        connection_user,
        connection_password,
        connection_string,
        max_sessions = benchmark_number_partitions,
        session_increment = 1,
    )

    connections = Dict{Int64,Oracle.Connection}()

    for partition_key = 1:benchmark_number_partitions
        try
            @debug "\n      $(function_name) Connection #$(partition_key) - to be openend"
            connections[partition_key] = Oracle.Connection(pool)
            @debug "\n      $(function_name) Connection #$(partition_key) - is now open"
        catch reason
            @info "partition_key=$(partition_key)"
            error(
                "fatal error: program abort =====> Oracle.Connection(pool) error: '$(string(reason))' <=====",
            )
        end
    end

    @debug "\nEnd   $(function_name)"
    (pool, connections)
end

# ----------------------------------------------------------------------------------
# Writing the results.
# ----------------------------------------------------------------------------------

function create_result(
    action::String,
    benchmark_globals::Vector{Any},
    config::Dict{String,Any},
    result_file::IOStream,
    sql_operation::String,
    sql_statement::String,
    start_date_time::TimesDates.TimeDate,
    trial_number::Int64,
)::Int64
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "\nStart $(function_name)"

    end_date_time = TimeDate(now())
    duration_ns = (end_date_time - start_date_time).value
    file_result_delimiter =
        replace(config["DEFAULT"]["file_result_delimiter"], "TAB" => "\t")

    if sql_operation == "insert"
        benchmark_globals[IX_DURATION_INSERT_SUM] += duration_ns
    elseif sql_operation == "select"
        benchmark_globals[IX_DURATION_SELECT_SUM] += duration_ns
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
        benchmark_globals[IX_BENCHMARK_LANGUAGE] *
        file_result_delimiter *
        benchmark_globals[IX_BENCHMARK_DRIVER] *
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

    if action == "trial"
        println("Duration (ms) trial         : $(round(duration_ns / 1000000))")
    end

    @debug "\nEnd   $(function_name)"

    duration_ns
end

# ----------------------------------------------------------------------------------
# Recording the results of the benchmark - end processing.
# ----------------------------------------------------------------------------------

function create_result_measuring_point_end(
    action::String,
    benchmark_globals::Vector{Any},
    config::Dict{String,Any},
    result_file::IOStream,
    trial_number::Int64 = 0,
    sql_operation::String = "",
    sql_statement::String = "",
)::Int64
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "\nStart $(function_name)"

    if action == "query"
        duration_ns = create_result(
            action,
            benchmark_globals,
            config,
            result_file,
            sql_operation,
            sql_statement,
            benchmark_globals[IX_LAST_QUERY],
            trial_number,
        )
    elseif action == "trial"
        duration_ns = create_result(
            action,
            benchmark_globals,
            config,
            result_file,
            sql_operation,
            sql_statement,
            benchmark_globals[IX_LAST_TRIAL],
            trial_number,
        )
    elseif action == "benchmark"
        duration_ns = create_result(
            action,
            benchmark_globals,
            config,
            result_file,
            sql_operation,
            sql_statement,
            benchmark_globals[IX_LAST_BENCHMARK],
            trial_number,
        )
        close(result_file)
    else
        error(
            "fatal error: program abort =====> unknown action='$(action)' status='end' <=====",
        )
    end

    @debug "\nEnd   $(function_name)"

    duration_ns
end

# ----------------------------------------------------------------------------------
# Recording the results of the benchmark - start processing.
# ----------------------------------------------------------------------------------

function create_result_measuring_point_start(action::String, benchmark_globals::Vector{Any})
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "\nStart $(function_name)"

    if action == "query"
        benchmark_globals[IX_LAST_QUERY] = TimeDate(now())
    elseif action == "trial"
        benchmark_globals[IX_LAST_TRIAL] = TimeDate(now())
    else
        error(
            "fatal error: program abort =====> unknown action='$(action)' status='start' <=====",
        )
    end

    @debug "\nEnd   $(function_name)"
    nothing
end

# ----------------------------------------------------------------------------------
# Loading the bulk file into memory.
# ----------------------------------------------------------------------------------

function get_bulk_data_partitions(
    config::Dict{String,Any},
)::Dict{Int64,DataFrames.DataFrame}
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "\nStart $(function_name)"

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

    @debug "\n      $(function_name) - size of bulk_data $(size(bulk_data,1))"

    # ----------------------------------------------------------------------------------
    # Loading the bulk file into memory.
    # ----------------------------------------------------------------------------------

    bulk_data_partitions = Dict{Int64,DataFrames.DataFrame}()

    for partition_key = 1:benchmark_number_partitions
        bulk_data_partitions[partition_key] = DataFrame(key = String[], data = String[])
    end

    for row in eachrow(bulk_data)
        key = row[1]
        partition_key =
            mod(Int(key[1]) * 251 + Int(key[2]), benchmark_number_partitions) + 1
        push!(bulk_data_partitions[partition_key], row)
    end

    println("Start Distribution of the data in the partitions")

    for partition_key = 1:benchmark_number_partitions
        println(
            format(
                "Partition p{1:0>5d} contains {2:n} rows",
                partition_key,
                size(bulk_data_partitions[partition_key], 1),
            ),
        )
    end

    println("End   Distribution of the data in the partitions")

    @debug "\nEnd   $(function_name)"
    bulk_data_partitions
end

# ----------------------------------------------------------------------------------
# Main function.
# ----------------------------------------------------------------------------------

function main()
    logger = SimpleLogger(stdout, Logging.Debug)
    logger = SimpleLogger(stdout, Logging.Info)
    old_logger = global_logger(logger)

    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "\nStart $(function_name)"

    println("Start OraBenchOracle.jl")

    numberArgs = size(ARGS, 1)

    println("main() - number arguments=$(numberArgs)")

    if numberArgs == 0
        @error "\nmain() - no command line argument available"
        throw(ArgumentError)
    end

    println("main() - 1st argument=$(ARGS[1])")

    if numberArgs > 1
        @error "\nmain() - more than one command line argument available"
        throw(ArgumentError)
    end

    # READ the configuration parameters into the memory (config params `file.configuration.name ...`)
    config = TOML.parsefile(ARGS[1])::Dict{String,Any}

    if parse(Int64, config["DEFAULT"]["benchmark_core_multiplier"]) == 0
        println("Number Threads : 1")
    else
        println("Number Threads : $(Threads.nthreads())")
    end

    run_benchmark(config)

    println("End   OraBenchOracle.jl")

    @debug "\nEnd   $(function_name)"
    nothing
end

# ----------------------------------------------------------------------------------
# Performing a complete benchmark run that can consist of several trial runs.
# ----------------------------------------------------------------------------------

function run_benchmark(config::Dict{String,Any})
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "\nStart $(function_name)"

    # save the current time as the start time of the 'benchmark' action
    file_result_name = config["DEFAULT"]["file_result_name"]

    benchmark_globals = Array([
        # LAST_BENCHMARK
        ""::String,
        # LAST_TRIAL
        ""::String,
        # LAST_QUERY
        ""::String,
        # DURATION_INSERT_SUM
        0::Int64,
        # DURATION_SELECT_SUM
        0::Int64,
        # BENCHMARK_DRIVER
        ""::String,
        # BENCHMARK_LANGUAGE
        ""::String,
    ])::Vector{Any}

    global IX_BENCHMARK_DRIVER = 6::Int64
    global IX_BENCHMARK_LANGUAGE = 7::Int64
    global IX_DURATION_INSERT_SUM = 4::Int64
    global IX_DURATION_SELECT_SUM = 5::Int64
    global IX_LAST_BENCHMARK = 1::Int64
    global IX_LAST_QUERY = 3::Int64
    global IX_LAST_TRIAL = 2::Int64

    benchmark_globals[IX_LAST_BENCHMARK] = TimeDate(now())

    m = Pkg.Operations.Context().env.manifest
    v = m[findfirst(v -> v.name == "Oracle", m)].version

    benchmark_globals[IX_BENCHMARK_DRIVER] = "Oracle.jl $(string(v))"
    benchmark_globals[IX_BENCHMARK_LANGUAGE] = "Julia $(string(Base.VERSION))"

    result_file = open(file_result_name, "a")

    if !(isfile(file_result_name))
        error(
            "fatal error: program abort =====> result file '$(file_result_name)' is missing <=====",
        )
    end

    # READ the bulk file data into the partitioned collection bulk_data_partitions (config param 'file.bulk.name')
    bulk_data_partitions = get_bulk_data_partitions(config)

    # create a separate database connection (without auto commit behaviour) for each partition
    benchmark_number_partitions =
        parse(Int64, config["DEFAULT"]["benchmark_number_partitions"])::Int64

    (pool, connections) = create_connections(benchmark_number_partitions, config)

    #=
      trial_max = 0
      trial_min = 0
      trial_no = 0
      trial_sum = 0
      WHILE trial_no < config_param 'benchmark.trials'
            duration_trial = DO run_trial(database connections,
                                          trial_no,
                                          bulk_data_partitions)
            IF trial_max == 0 OR duration_trial > trial_max
               trial_max = duration_trial
            END IF
            IF trial_min == 0 OR duration_trial < trial_min
               trial_min = duration_trial
            END IF
            trial_sum + duration_trial
      ENDWHILE
    =#
    trial_max = 0
    trial_min = 0
    trial_sum = 0

    for trial_number = 1:parse(Int64, config["DEFAULT"]["benchmark_trials"])
        duration_ns_trial = run_trial(
            benchmark_globals,
            bulk_data_partitions,
            config,
            connections,
            result_file,
            trial_number,
        )

        if trial_max == 0 || duration_ns_trial > trial_max
            trial_max = duration_ns_trial
        end

        if trial_min == 0 || duration_ns_trial < trial_min
            trial_min = duration_ns_trial
        end

        trial_sum += duration_ns_trial
    end

    #=
      partition_key = 0
      WHILE partition_key < config_param 'benchmark.number.partitions'
            close the database connection
      ENDWHILE
    =#
    for partition_key = 1:benchmark_number_partitions
        @debug "\n      $(function_name) Connection #$(partition_key) - to be closed"
        Oracle.close(connections[partition_key])
        @debug "\n      $(function_name) Connection #$(partition_key) - is now closed"
    end

    Oracle.close(pool)

    # WRITE an entry for the action 'benchmark' in the result file (config param 'file.result.name')
    duration_ns_benchmark = create_result_measuring_point_end(
        "benchmark",
        benchmark_globals,
        config,
        result_file,
    )

    # INFO  Duration (ms) trial min.    : trial_min
    # INFO  Duration (ms) trial max.    : trial_max
    # INFO  Duration (ms) trial average : trial_sum / config_param 'benchmark.trials'
    println("Duration (ms) trial min.    : $(round(trial_min / 1000000))")
    println("Duration (ms) trial max.    : $(round(trial_max / 1000000))")
    println(
        "Duration (ms) trial average : $(round(trial_sum / 1000000 / parse(Int64, config["DEFAULT"]["benchmark_trials"])))",
    )

    # INFO  Duration (ms) benchmark run : duration_benchmark
    println("Duration (ms) benchmark run : $(round(duration_ns_benchmark / 1000000))")

    @debug "\nEnd   $(function_name)"
    nothing
end

# ----------------------------------------------------------------------------------
# Supervise function for inserting data into the database.
# ----------------------------------------------------------------------------------

function run_insert(
    benchmark_batch_size::Int64,
    benchmark_core_multiplier::Int64,
    benchmark_globals::Vector{Any},
    benchmark_number_partitions::Int64,
    benchmark_transaction_size::Int64,
    bulk_data_partitions::Dict{Int64,DataFrames.DataFrame},
    config::Dict{String,Any},
    connections::Dict{Int64,Oracle.Connection},
    result_file::IOStream,
    sql_insert::String,
    trial_number::Int64,
)
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "\nStart $(function_name) - trial_number=$(trial_number)"

    # save the current time as the start time of the 'query' action
    create_result_measuring_point_start("query", benchmark_globals)

    #=
      partition_key = 0
      WHILE partition_key < config_param 'benchmark.number.partitions'
            IF config_param 'benchmark.core.multiplier' == 0
               DO run_insert_helper(database connections(partition_key),
                                    bulk_data_partitions(partition_key),
                                    partition_key)
            ELSE
               DO run_insert_helper(database connections(partition_key),
                                   bulk_data_partitions(partition_key),
                                   partition_key) as a thread
            ENDIF
      ENDWHILE
    =#
    if benchmark_core_multiplier == 0
        for partition_key = 1:benchmark_number_partitions
            run_insert_helper(
                benchmark_batch_size,
                benchmark_transaction_size,
                bulk_data_partitions[partition_key],
                connections[partition_key],
                partition_key,
                sql_insert,
                trial_number,
            )
        end
    else
        @threads for partition_key = 1:benchmark_number_partitions
            run_insert_helper(
                benchmark_batch_size,
                benchmark_transaction_size,
                bulk_data_partitions[partition_key],
                connections[partition_key],
                partition_key,
                sql_insert,
                trial_number,
            )
        end
    end

    # WRITE an entry for the action 'query' in the result file (config param 'file.result.name')
    create_result_measuring_point_end(
        "query",
        benchmark_globals,
        config,
        result_file,
        trial_number,
        "insert",
        sql_insert,
    )

    @debug "\nEnd   $(function_name) - trial_number=$(trial_number)"
    nothing
end

# ----------------------------------------------------------------------------------
# Helper function for inserting data into the database.
# ----------------------------------------------------------------------------------

function run_insert_helper(
    benchmark_batch_size::Int64,
    benchmark_transaction_size::Int64,
    bulk_data_partition::DataFrames.DataFrame,
    connection::Oracle.Connection,
    partition_key::Int64,
    sql_insert::String,
    trial_number::Int64,
)
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "\nStart $(function_name) - partition_key=$(partition_key)"

    #=
      IF trial_no == 1
         INFO Start insert partition_key=partition_key
      ENDIF
    =#
    if trial_number == 1
        println("Start insert partition_key=$(partition_key) - thread id=$(threadid())")
    end

    #=
      count = 0
      collection batch_collection = empty
      WHILE iterating through the collection bulk_data_partition
            count + 1

            add the SQL statement in config param 'sql.insert' with the current bulk_data entry to the collection batch_collection

            IF config_param 'benchmark.batch.size' > 0
               IF count modulo config param 'benchmark.batch.size' == 0
                  execute the SQL statements in the collection batch_collection
                  batch_collection = empty
               ENDIF
            ENDIF

            IF  config param 'benchmark.transaction.size' > 0
            AND count modulo config param 'benchmark.transaction.size' == 0
                commit
            ENDIF
      ENDWHILE
    =#
    stmt = Oracle.Stmt(connection, sql_insert)::Oracle.Stmt{Oracle.ORA_STMT_TYPE_INSERT}

    count = 0
    batch_collection_keys = Vector{String}()
    batch_collection_data = Vector{String}()

    for bulk_data_row in eachrow(bulk_data_partition)
        count += 1

        if benchmark_batch_size == 1
            stmt[:1] = bulk_data_row.key
            stmt[:2] = bulk_data_row.data
            Oracle.execute(stmt)
        else
            push!(batch_collection_keys, bulk_data_row.key)
            push!(batch_collection_data, bulk_data_row.data)
            if benchmark_batch_size > 0 && mod(count, benchmark_batch_size) == 0
                @debug "\n      $(function_name) - partition_key=$(partition_key) - before bulk"
                Oracle.execute_many(
                    connection,
                    sql_insert,
                    [batch_collection_keys, batch_collection_data],
                )
                @debug "\n      $(function_name) - partition_key=$(partition_key) - after  bulk"
                batch_collection_keys = Vector{String}()
                batch_collection_data = Vector{String}()
            end
        end

        if benchmark_transaction_size > 0
            if mod(count, benchmark_transaction_size) == 0
                @debug "\n      $(function_name) - partition_key=$(partition_key) - before commit"
                Oracle.execute(connection, "commit")
                @debug "\n      $(function_name) - partition_key=$(partition_key) - after  commit"
            end
        end
    end

    #=
      IF collection batch_collection is not empty
         execute the SQL statements in the collection batch_collection
      ENDIF
    =#
    if size(batch_collection_keys, 1) != 0
        @debug "\n      $(function_name) - partition_key=$(partition_key) - before bulk final"
        Oracle.execute_many(
            connection,
            sql_insert,
            [batch_collection_keys, batch_collection_data],
        )
        @debug "\n      $(function_name) - partition_key=$(partition_key) - after  bulk final"
    end

    # commit
    @debug "\n      $(function_name) - partition_key=$(partition_key) - before commit - final"
    Oracle.execute(connection, "commit")
    @debug "\n      $(function_name) - partition_key=$(partition_key) - after  commit - final"

    #=
      IF trial_no == 1
         INFO End   insert partition_key=partition_key
      ENDIF
    =#
    if trial_number == 1
        println("End   insert partition_key=$(partition_key) - thread id=$(threadid())")
    end

    @debug "\nEnd   $(function_name) - partition_key=$(partition_key)"
    nothing
end

# ----------------------------------------------------------------------------------
# Supervise function for retrieving of the database data.
# ----------------------------------------------------------------------------------

function run_select(
    benchmark_core_multiplier::Int64,
    benchmark_globals::Vector{Any},
    benchmark_number_partitions::Int64,
    bulk_data_partitions::Dict{Int64,DataFrames.DataFrame},
    config::Dict{String,Any},
    connections::Dict{Int64,Oracle.Connection},
    result_file::IOStream,
    sql_select::String,
    trial_number::Int64,
)
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "\nStart $(function_name) - trial_number=$(trial_number)"

    # save the current time as the start time of the 'query' action
    create_result_measuring_point_start("query", benchmark_globals)

    #=
      partition_key = 0
      WHILE partition_key < config_param 'benchmark.number.partitions'
            IF config_param 'benchmark.core.multiplier' == 0
               DO run_select_helper(database connections(partition_key),
                                    bulk_data_partitions(partition_key,
                                    partition_key)
            ELSE
               DO run_select_helper(database connections(partition_key),
                                    bulk_data_partitions(partition_key,
                                    partition_key) as a thread
            ENDIF
      ENDWHILE
    =#
    if benchmark_core_multiplier == 0
        for partition_key = 1:benchmark_number_partitions
            run_select_helper(
                connections[partition_key],
                size(bulk_data_partitions[partition_key], 1),
                partition_key,
                sql_select,
                trial_number,
            )
        end
    else
        @threads for partition_key = 1:benchmark_number_partitions
            run_select_helper(
                connections[partition_key],
                size(bulk_data_partitions[partition_key], 1),
                partition_key,
                sql_select,
                trial_number,
            )
        end
    end

    # WRITE an entry for the action 'query' in the result file (config param 'file.result.name')
    create_result_measuring_point_end(
        "query",
        benchmark_globals,
        config,
        result_file,
        trial_number,
        "select",
        sql_select,
    )

    @debug "\nEnd   $(function_name) - trial_number=$(trial_number)"
    nothing
end

# ----------------------------------------------------------------------------------
# Helper function for retrieving data from the database.
# ----------------------------------------------------------------------------------

function run_select_helper(
    connection::Oracle.Connection,
    count_expected::Int64,
    partition_key::Int64,
    sql_select::String,
    trial_number::Int64,
)
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "\nStart $(function_name) - partition_key=$(partition_key)"

    #=
      IF trial_no == 1
         INFO Start select partition_key=partition_key
      ENDIF
    =#
    if trial_number == 1
        println("Start select partition_key=$(partition_key) - thread id=$(threadid())")
    end

    # execute the SQL statement in config param 'sql.select'
    stmt = Oracle.Stmt(
        connection,
        sql_select * " where partition_key = $(partition_key - 1)",
    )::Oracle.Stmt{Oracle.ORA_STMT_TYPE_SELECT}

    #=
      count = 0
      WHILE iterating through the result set
            count + 1
      ENDWHILE
    =#
    count = 0

    Oracle.query(stmt) do cursor
        for row in cursor
            count += 1
        end
    end

    #=
      IF NOT count = size(bulk_data_partition)
         display an error message
      ENDIF
    =#
    if count != count_expected
        @error "\nPartition $(partition_key - 1) number rows: expected=$(count_expected) - found=$(count)"
        throw(ErrorException)
    end

    #=
      IF trial_no == 1
         INFO End   select partition_key=partition_key
      ENDIF
    =#
    if trial_number == 1
        println("End   select partition_key=$(partition_key) - thread id=$(threadid())")
    end

    @debug "\nEnd   $(function_name) - partition_key=$(partition_key)"
    nothing
end

# ----------------------------------------------------------------------------------
# Performing a single trial run.
# ----------------------------------------------------------------------------------

function run_trial(
    benchmark_globals::Vector{Any},
    bulk_data_partitions::Dict{Int64,DataFrames.DataFrame},
    config::Dict{String,Any},
    connections::Dict{Int64,Oracle.Connection},
    result_file::IOStream,
    trial_number::Int64,
)::Int64
    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "\nStart $(function_name) - trial_number=$(trial_number)"

    # save the current time as the start time of the 'trial' action
    create_result_measuring_point_start("trial", benchmark_globals)

    # INFO  Start trial no. trial_no
    println("Start trial no. $(string(trial_number))")

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
        @debug "\nlast DDL statement=$(sql_create)"
    catch
        Oracle.execute(connections[1], sql_drop)
        Oracle.execute(connections[1], sql_create)
        @debug "\nlast DDL statement after DROP=$(sql_create)"
    end

    #=
    DO run_insert(database connections,
                  trial_no,
                  bulk_data_partitions)
    =#
    benchmark_batch_size = parse(Int64, config["DEFAULT"]["benchmark_batch_size"])
    benchmark_core_multiplier = parse(Int64, config["DEFAULT"]["benchmark_core_multiplier"])
    benchmark_number_partitions =
        parse(Int64, config["DEFAULT"]["benchmark_number_partitions"])
    benchmark_transaction_size =
        parse(Int64, config["DEFAULT"]["benchmark_transaction_size"])

    sql_insert = replace(
        replace(config["DEFAULT"]["sql_insert"], ":key" => ":1"),
        ":data" => ":2",
    )::String

    run_insert(
        benchmark_batch_size,
        benchmark_core_multiplier,
        benchmark_globals,
        benchmark_number_partitions,
        benchmark_transaction_size,
        bulk_data_partitions,
        config,
        connections,
        result_file,
        sql_insert,
        trial_number,
    )

    #=
    DO run_select(database connections,
                  trial_no,
                  bulk_data_partitions)
    =#
    sql_select = config["DEFAULT"]["sql_select"]::String

    run_select(
        benchmark_core_multiplier,
        benchmark_globals,
        benchmark_number_partitions,
        bulk_data_partitions,
        config,
        connections,
        result_file,
        sql_select,
        trial_number,
    )

    # drop the database table (config param 'sql.drop')
    Oracle.execute(connections[1], sql_drop)
    @debug "\nlast DDL statement=$(sql_drop)"

    # WRITE an entry for the action 'trial' in the result file (config param 'file.result.name')
    duration_ns = create_result_measuring_point_end(
        "trial",
        benchmark_globals,
        config,
        result_file,
        trial_number,
    )

    @debug "\nEnd   $(function_name) - trial_number=$(trial_number)"

    duration_ns
end


# ----------------------------------------------------------------------------------
# Entry point.
# ----------------------------------------------------------------------------------

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end
