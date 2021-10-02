module I27

using Pkg

# Pkg.add("Formatting")
Pkg.add("Oracle")

# using Formatting
using Logging
using Oracle

function main()
    logger = SimpleLogger(stdout, Logging.Debug)
    old_logger = global_logger(logger)

    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "Start $(function_name)"

    @debug "Start I27.jl - Number Threads: $(Threads.nthreads())"

    connection_user = ARGS[1]::String
    @debug "      I27.jl - connection_user    : $(connection_user)"
    connection_password = ARGS[2]::String
    @debug "      I27.jl - connection_password: $(connection_password)"
    connection_string = ARGS[3]
    @debug "      I27.jl - connection_string  : $(connection_string)"
    
    number_connections = 20

    connections = Dict{Int64,Oracle.Connection}()

    for i = 1:number_connections
        try
            @debug "      $(function_name) Connection #$(i) - to be openend"
            connections[i] = Oracle.Connection(connection_user, connection_password,connection_string)
            @debug "      $(function_name) Connection #$(i) - is now open"
        catch reason
            @debug "i=$(i)"
            error(
                "fatal error: program abort =====> Oracle.Connection() error: '$(string(reason))' <=====",
            )
        end
    end

    for i = 1:number_connections
        @debug "      $(function_name) Connection #$(i) - to be closed"
        Oracle.close(connections[i])
        @debug "      $(function_name) Connection #$(i) - is now closed"
    end

    @debug "End   I27.jl"

    @debug "End   $(function_name)"
    nothing
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end
