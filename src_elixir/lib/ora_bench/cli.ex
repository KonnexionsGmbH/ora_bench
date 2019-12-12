defmodule OraBench.CLI do
  require Logger

  @moduledoc false

  def main(args) do
    Logger.info('Start OraBench.ex - args: #{args}')
    case args do
      ["Jamdb.Oracle"] ->
        OraBench.run_benchmark(Jamdb.Oracle)
      ["OraLixir"] ->
        OraBench.run_benchmark(OraLixir)
      [unknown] ->
        raise("[Error in main] unknown database driver #{unknown} was chosen")
      [] ->
        raise("[Error in main] no database driver was chosen")
    end
    Logger.info('End   OraBench.ex')
  end

end
