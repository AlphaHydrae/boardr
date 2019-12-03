defmodule BoardrWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :boardr

  def init(:supervisor, config) do

    jwt_private_key = System.get_env("BOARDR_JWT_PRIVATE_KEY", config[:jwt_private_key])

    cond do
      is_nil(jwt_private_key) ->
        {:error, :jwt_private_key_missing}
      true ->
        {
          :ok,
          Keyword.merge(
            config,
            [
              http: [
                port: String.to_integer(System.get_env("BOARDR_PORT", System.get_env("PORT", "4000")))
              ],
              jwt_private_key: jwt_private_key,
              url: [
                host: System.get_env("BOARDR_BASE_HOST", "localhost")
              ]
            ]
          )
        }
    end
  end

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :boardr,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.Head

  plug BoardrWeb.Router
end
