# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :boardr,
  ecto_repos: [Boardr.Repo],
  generators: [binary_id: true]

# Take the environment variable $USER or the Unix system username as the default
# database username if the $BOARDR_DATABASE_USERNAME variable is not set.
database_username = System.get_env("BOARDR_DATABASE_USERNAME", System.get_env("USER")) || (fn ->
  {result, 0} = System.cmd("whoami", [])
  String.trim_trailing(result)
end).()

database_socket_dir = System.get_env(
  "BOARDR_DATABASE_SOCKET_DIR",
  (if File.exists?("/tmp/.s.PGSQL.5432"), do: "/tmp", else: nil)
)

database_options = [
  username: database_username,
  password: System.get_env("BOARDR_DATABASE_PASSWORD", nil),
  database: System.get_env("BOARDR_DATABASE_NAME", "boardr"),
  hostname: System.get_env("BOARDR_DATABASE_HOST", "localhost"),
  port: String.to_integer(System.get_env("BOARDR_DATABASE_PORT", "5432")),
  socket_dir: database_socket_dir
]

config :boardr, Boardr.Repo, database_options

# Configures the endpoint
config :boardr, BoardrWeb.Endpoint,
  jwt_issuer: "boardr.alphahydrae.io",
  render_errors: [view: BoardrWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Boardr.PubSub, adapter: Phoenix.PubSub.PG2]

config :boardr, :gaming,
  rules_factory: Boardr.Rules.DefaultFactory

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  level: :info,
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config_dir = Path.dirname(__ENV__.file)

# Import environment-specific configuration file (e.g. "dev.exs").
env_specific_config_file = Path.join(config_dir, "#{Mix.env()}.exs")
if File.exists?(env_specific_config_file), do: import_config env_specific_config_file

# Import generic configuration file "env.exs" (not under version control).
generic_config_file = Path.join(config_dir, "env.exs")
if File.exists?(generic_config_file), do: import_config generic_config_file
