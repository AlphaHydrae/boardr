defmodule Boardr.Repo do
  use Ecto.Repo,
    otp_app: :boardr,
    adapter: Ecto.Adapters.Postgres
end
