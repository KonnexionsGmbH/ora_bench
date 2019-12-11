# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :ora_bench,
       adapter: Ecto.Adapters.Jamdb.Oracle

# Configures Elixir's Logger
config :logger,
       :console,
       backends: [:console],
       compile_time_purge_matching: [
         [level_lower_than: :info]
       ],
       format: "$time $metadata\n[$level] $message\n",
       metadata: [
         :module,
         :function,
         :line
       ]
