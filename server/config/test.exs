use Mix.Config

config :boardr, Boardr.Auth.Token,
  private_key: """
  -----BEGIN RSA PRIVATE KEY-----
  MIICXAIBAAKBgQDl4irEyE69GzKUYtRC7HcQ74v6mIWohNC7DkU2+P6VuuViMSkY
  UPgHDOo8vX/4z9ZnvdiycYigLA95hWP7zdZjtYV/mBeLb8VZA0qrZDQgGGP3ML+X
  JLlkfG75ykSkCTideNjv6DY3owOueoO+v9URquZc6CSN5qiAUnPOjcKAiwIDAQAB
  AoGAFq5Dzfp9WkcOrHk7vAackL0xsF3QAhpohawYxB248IjqDNAQ3+dNMVTi329K
  6v+GheHDOYfeFP+D31d7z+I1Hp1jy9bPVq58DuHLq5siXV4w231x40NYgdM7U6NE
  bjEpLNdk22F5yK30MkZtZZ0GhWhoFjjuO+4NJkABhmVs/7ECQQD+Yorgbli9bp4U
  7dQc5HJ+I/XAHerjYcQs5xt4Mcy/pFITWIbodTr/kyLzAYD1xb+M4o07hc9yfjMP
  7U8TERxfAkEA51fNQpTJ8af/WfN4s6KkeXWL1zLeA0WGqmNAU38G5JD3/mqu56LP
  1Lx5Dg3rV7ayhqLdpkRw17w5k548sKQLVQJAP3aaKw+cd/YG3jXPOz4LCkkyYDGW
  jg+v/3vQsJXL/OujxkvJrGjCxUwR5go0ABzLgvxqO7VQYcH2Pzz3A0y7hQJAGE6r
  bIGBrnh+Zg8k8Yr3SSPGq7fWh/V4LtL64UsJiF6LEBpZglEjETE0bvubbL3viCH4
  tA2g5aoLSq1npw+1eQJBAPdH0hdDi0u7TNPY8AOigHBXfK1IDVo8Z5ktolQH9Qyb
  f3XyeYbmE8pLKzEwhY99wBuIb+jcKLE3EoLucIeaV8w=
  -----END RSA PRIVATE KEY-----
  """

# Configure your database
config :boardr, Boardr.Repo,
  database: System.get_env("BOARDR_TEST_DATABASE_NAME", "boardr-test"),
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test.
config :boardr, BoardrApi.Endpoint,
  server: false

# Print only warnings and errors during test.
unless System.get_env("DEBUG") do
  config :logger, level: :warn
else
  # Unless the $DEBUG variable is set (to any value).
  config :logger, :console, level: :debug
end

# Do not wait for swarm nodes during test.
config :swarm,
  sync_nodes_timeout: 0
