defmodule OraBench.Repo do
  use Ecto.Repo,
      otp_app: :ora_bench,
      adapter: Ecto.Adapters.Jamdb.Oracle
end
