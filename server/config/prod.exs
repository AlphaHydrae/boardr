use Mix.Config

config :boardr, Boardr.Telemetry,
  slow_query_time: 500

config :boardr, BoardrApi.Endpoint,
  server: true

config :logger, :console,
  level: :warn
