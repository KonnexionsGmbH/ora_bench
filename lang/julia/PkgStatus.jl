#=
PkgStatus:
- Author: Konnexions GmbH
- Date: 2021-06-26
=#

module OraBenchOracle

using Logging
using Pkg

# ----------------------------------------------------------------------------------
# Main function.
# ----------------------------------------------------------------------------------

function main()
    logger = SimpleLogger(stdout, Logging.Debug)
    logger = SimpleLogger(stdout, Logging.Info)
    old_logger = global_logger(logger)

    function_name = string(StackTraces.stacktrace()[1].func)
    @debug "\nStart $(function_name)"

    println("Start PkgStatus.jl")

    numberArgs = size(ARGS, 1)

    println("main() - number arguments=$(numberArgs)")

    if numberArgs != 0
        println("main() - 1st argument=$(ARGS[1])")

        @error "\nmain() - no command line arguments allowed"
        throw(ArgumentError)
   end

    Pkg.status()

    println("End   PkgStatus.jl")

    @debug "\nEnd   $(function_name)"
    nothing
end

# ----------------------------------------------------------------------------------
# Entry point.
# ----------------------------------------------------------------------------------

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end
