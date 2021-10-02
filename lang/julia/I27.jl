#= 
OraBenchOracle:
- Author: Konnexions GmbH
- Date: 2021-06-26
=#

module I27

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
# Main function.
# ----------------------------------------------------------------------------------

function main()
    logger = SimpleLogger(stdout, Logging.Debug)
    old_logger = global_logger(logger)

    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start $(function_name)"

    @info "Start I27.jl - Number Threads: $(Threads.nthreads())"

    connection_user = ARGS[1]::String
    connection_password = ARGS[2]::String
    connection_string = ARGS[3]
    
    number_connections = 10

    connections = Dict{Int64,Oracle.Connection}()

    for i = 1:number_connections
        try
            @debug "      $(function_name) Connection #$(i) - to be openend"
            connections[i] = Oracle.Connection(pool)
            @debug "      $(function_name) Connection #$(i) - is now open"
        catch reason
            @info "i=$(i)"
            error(
                "fatal error: program abort =====> Oracle.Connection(pool) error: '$(string(reason))' <=====",
            )
        end
    end

    for i = 1:number_connections
        @debug "      $(function_name) Connection #$(i) - to be closed"
        Oracle.close(connections[i])
        @debug "      $(function_name) Connection #$(i) - is now closed"
    end

    Oracle.close(pool)

    @info "End   I27.jl"

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
