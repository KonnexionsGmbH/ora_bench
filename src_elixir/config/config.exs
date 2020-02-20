# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures Elixir's Logger
config :logger, level: :info
config :logger,
       :console,
       backends: [:console],
       format: "$time $metadata [$level] $message\n",
       metadata: [
         :module,
         :line
       ]
