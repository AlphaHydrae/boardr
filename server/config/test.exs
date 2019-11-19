use Mix.Config

# Configure your database
config :boardr, Boardr.Repo,
  database: System.get_env("BOARDR_TEST_DATABASE_NAME", "boardr-test"),
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test.
config :boardr, BoardrWeb.Endpoint, server: false

# Print only warnings and errors during test.
config :logger, level: :warn
