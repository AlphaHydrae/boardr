use Mix.Config

config :boardr, BoardrWeb.Endpoint,
  jwt_private_key: """
  -----BEGIN OPENSSH PRIVATE KEY-----
  b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAABFwAAAAdzc2gtcn
  NhAAAAAwEAAQAAAQEAwWbjD2NvdNItYJOxqLJ6v5Gafoac831pZcGlDodcXTyCO6Bg/8C/
  vFRFG+qlC/X0bC00xS14bAjjCEqYymNud+DBZXWulC7fmALJ2g96VESaKOcM/qlk5sqNIl
  /sc0SV2kDBLsJIHAd8tv0xiFauvrtQxss+X3b68fBhDnhMB8cVre16NJvIyNQXZXhvktTZ
  CIvlyDUCRqFZ6MjtzsGebPfIRH9n4X7BvmY0tnBQf14fJv4+DAtMP86i5WvoUVf9XrT7sG
  Af9yohitQKC27dFvrPl+yNv2Eb2gy+8oIXIVQbBEy0Tl7iorUnaQBDk7ee+x1yRMo2kHGm
  wQevieV3WwAAA9D7UpHo+1KR6AAAAAdzc2gtcnNhAAABAQDBZuMPY2900i1gk7Gosnq/kZ
  p+hpzzfWllwaUOh1xdPII7oGD/wL+8VEUb6qUL9fRsLTTFLXhsCOMISpjKY2534MFlda6U
  Lt+YAsnaD3pURJoo5wz+qWTmyo0iX+xzRJXaQMEuwkgcB3y2/TGIVq6+u1DGyz5fdvrx8G
  EOeEwHxxWt7Xo0m8jI1BdleG+S1NkIi+XINQJGoVnoyO3OwZ5s98hEf2fhfsG+ZjS2cFB/
  Xh8m/j4MC0w/zqLla+hRV/1etPuwYB/3KiGK1AoLbt0W+s+X7I2/YRvaDL7yghchVBsETL
  ROXuKitSdpAEOTt577HXJEyjaQcabBB6+J5XdbAAAAAwEAAQAAAQEAo+XAWMMoqjSPlf+0
  GEWgtoX7Cmyjx8kpL73KViSqRq1HpKZGbZb4Je64Xm8cjaVTDPXGea8OFWf2lok5MJLRBD
  BpVMVFPHj4rYb3bp+dSJqWlkEwBwSg6OEQd+gYppqh78Les/SbTX2e2Ch7+JGVJzfwvXdy
  FU7sXWobpjqWHCPEtDrSfRmtUycVaBjyNSjXwyAt6OfIfqi1JCM0XF9+ZG4XdnCUPslruh
  SCM77+TP6VExiKuiyMM033cVP/jIVC/z1ujF/GqFwQraKlfE+P/M9BrcwCt5fuxh8ip1/P
  q6mNXdQC/aCEK9+eFp1jHsT22tdlGpPciE0c6Ycf85wtkQAAAIAS12J66VLLoTke+9DtMN
  ZBFfdqYYAYxDGW5qqoDTWa4tAyWVWdPNT57CCaIS8rpOOxgSCju9+Zd7c5FwlxCAISwMjy
  Yx2lX5yAbz9O1HgLAiYyjiOSQFMsu0EFK1o6tzO+6jbV5/uXLgWznMhWYNmRLSzYgCR/nY
  8hdDZZTemDlwAAAIEA+GZrP9ueJVHuVtW7mSCDCpcgO9dn9qjodbx8icf6/Py3dPtHqWlv
  sxCA+G3L4e1ZYq/alPqmeI78Rv+sBMwSgQpPklszg4FYQqQoC8OTUDLbCfCxEa6XIG/5cK
  3/XxnQwBVwm8x2uOXhuWdtCn/8yAQXOILI0r2pHhk58ZgvEtMAAACBAMdRspYOWuOJF+io
  V0JvOfeTxkUm1C72niAmovF4vksYloVn6CHjChAiLyslGmdtCI6ahcpJ/InBzUfWCxwUb1
  FlSZqlChULoV24WvlIydqFPTEDuIs1jhKGh4zxi1tLuLodZ0krluQ4ypbP1nc5eu/ksRKC
  V0ageUGW/j1VrORZAAAAE3Vua25vd0BBdmFsb24ubG9jYWwBAgMEBQYH
  -----END OPENSSH PRIVATE KEY-----
  """,
  jwt_public_key: """
  -----BEGIN RSA PUBLIC KEY-----
  MIIBCgKCAQEAwWbjD2NvdNItYJOxqLJ6v5Gafoac831pZcGlDodcXTyCO6Bg/8C/
  vFRFG+qlC/X0bC00xS14bAjjCEqYymNud+DBZXWulC7fmALJ2g96VESaKOcM/qlk
  5sqNIl/sc0SV2kDBLsJIHAd8tv0xiFauvrtQxss+X3b68fBhDnhMB8cVre16NJvI
  yNQXZXhvktTZCIvlyDUCRqFZ6MjtzsGebPfIRH9n4X7BvmY0tnBQf14fJv4+DAtM
  P86i5WvoUVf9XrT7sGAf9yohitQKC27dFvrPl+yNv2Eb2gy+8oIXIVQbBEy0Tl7i
  orUnaQBDk7ee+x1yRMo2kHGmwQevieV3WwIDAQAB
  -----END RSA PUBLIC KEY-----
  """

# Configure your database
config :boardr, Boardr.Repo,
  database: System.get_env("BOARDR_TEST_DATABASE_NAME", "boardr-test"),
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test.
config :boardr, BoardrWeb.Endpoint, server: false

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
