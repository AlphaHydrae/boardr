use Mix.Config

# For development, we disable any cache and enable debugging and code reloading.
config :boardr, BoardrWeb.Endpoint,
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
