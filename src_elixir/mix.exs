defmodule OraBench.MixProject do
  use Mix.Project

  def project do
    [
      app: :ora_bench,
      deps: deps(),
      elixir: "~> 1.9",
      escript: escript(),
      start_permanent: Mix.env() == :prod,
      version: "0.1.0"
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      extra_applications: [
        :ecto,
        :logger
      ]
    ]
  end

  # Specifies project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:ecto_sql, "~> 3.2.2"},
      {:oranif, git: "https://github.com/konnexionsgmbh/oranif"}
    ]
  end

  defp escript do
    [
      main_module: OraBench.CLI
    ]
  end
end
