defmodule Boardr.Repo do
  use Ecto.Repo,
    otp_app: :boardr,
    adapter: Ecto.Adapters.Postgres,
    migration_timestamps: [type: :naive_datetime_usec]

  def init(:supervisor, config) do
    # TODO: use Boardr.Config to validate URL
    database_url = System.get_env("BOARDR_DATABASE_URL", System.get_env("DATABASE_URL"))
    if database_url != nil do
      {
        :ok,
        config
        |> Keyword.drop([:database, :hostname, :password, :port, :username])
        |> Keyword.put(:url, database_url)
      }
    else
      {:ok, config}
    end
  end
end
