defmodule OraBench.CLI do
  require Logger

  @moduledoc false

  def main(args) do
    Logger.info('Start OraBench.ex - args: #{args}')
    case args do
      ["Jamdb.Oracle"] ->
        OraBenchJamdb.run_benchmark()
      ["oranif"] ->
        OraBenchOranif.run_benchmark()
      [unknown] ->
        raise("[Error in main] unknown database driver #{unknown} was chosen")
      [] ->
        raise("[Error in main] no database driver was chosen")
    end
    Logger.info('End   OraBench.ex')
  end

end
