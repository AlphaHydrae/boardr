use Mix.Config

require Logger

# For development, we disable any cache and enable debugging and code reloading.
config :boardr, BoardrApi.Endpoint,
  check_origin: false,
  code_reloader: true,
  debug_errors: false,
  show_sensitive_data_on_connection_error: false

# Set a higher stacktrace during development. Avoid configuring such in
# production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation.
config :phoenix, :plug_init_mode, :runtime

# Log debug messages (e.g. database queries) in development.
config :logger, :console, level: :debug

# Do not wait for swarm nodes in development.
config :swarm,
  sync_nodes_timeout: 0

repo_dir = [Path.dirname(__ENV__.file), "..", ".."] |> Path.join() |> Path.expand()

private_key_file =
  [repo_dir, "server", "tmp", "id_rsa"]
  |> Path.join()
  |> Path.expand()

case private_key_result = File.read(private_key_file) do
  {:ok, private_key} ->
    config :boardr, Boardr.Auth.Token, private_key: private_key

  {:error, :enoent} ->
    Logger.warn(
      "Private key file #{private_key_file} not found; have you run #{
        Path.join([repo_dir, "scripts", "setup.sh"])
      }?"
    )

    :noop
end
