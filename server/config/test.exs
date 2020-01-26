use Mix.Config

config :boardr, Boardr.Auth,
  secret_key_base: "15VLc5dynJrIq2HZb8qNfui7e4g0YImLVryvDJbx5SU5o5hdgW14u773KF1SlgdRh3a83YZGmbjZtY1Dkttauxc9bvutDwHW8jgX"

# Configure your database
config :boardr, Boardr.Repo,
  database: System.get_env("BOARDR_TEST_DATABASE_NAME", "boardr-test"),
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test.
config :boardr, BoardrApi.Endpoint,
  server: false

# Print only warnings and errors during test.
unless System.get_env("DEBUG") do
  config :logger, :console, level: :warn
else
  # Unless the $DEBUG variable is set (to any value).
  config :logger, :console, level: :debug
end

# Do not wait for swarm nodes during test.
config :swarm,
  sync_nodes_timeout: 0
