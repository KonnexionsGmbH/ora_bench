defmodule OraBench.CLI do
  require Logger

  @moduledoc false

  def main(args) do
    Logger.info('Start OraBench.ex - args: #{args}')
    case args do
      ["jamdb_oracle"] ->
        OraBench.run_benchmark_jamdb_oracle()
#      ["oranif"] ->
#        OraBench.run_benchmark_oranif()
      [unknown] ->
        raise("[Error in main] unknown database driver #{unknown} was chosen")
      [] ->
        raise("[Error in main] no database driver was chosen")
    end
    Logger.info('End   OraBench.ex')
  end

end
