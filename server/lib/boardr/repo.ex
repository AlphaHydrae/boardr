defmodule Boardr.Repo do
  use Ecto.Repo,
    otp_app: :boardr,
    adapter: Ecto.Adapters.Postgres,
    migration_timestamps: [type: :naive_datetime_usec]
end
