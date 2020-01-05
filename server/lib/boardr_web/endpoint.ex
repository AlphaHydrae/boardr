defmodule BoardrWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :boardr

  alias Boardr.Config

  def init(:supervisor, config) do
    with {:ok, jwt_private_key} <-
           Config.get_required_env(
             "BOARDR_JWT_PRIVATE_KEY",
             :jwt_private_key_missing,
             config[:jwt_private_key]
           ),
         {:ok, port} <-
           Config.get_required_env(
             "BOARDR_PORT",
             :port_missing,
             System.get_env("PORT", "4000")
           ),
         {:ok, valid_port} <-
           Config.parse_port(port, :port_invalid),
         base_url = System.get_env("BOARDR_BASE_URL", "http://localhost:#{valid_port}"),
         {:ok, base_url_options} <-
           Config.parse_http_url(base_url, :base_url_invalid) do
      {
        :ok,
        Keyword.merge(
          config,
          http: [
            port: valid_port
          ],
          jwt_private_key: jwt_private_key,
          url: base_url_options |> Map.take([:host, :path, :port, :scheme]) |> Map.to_list()
        )
      }
    end
  end

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug(Plug.Static,
    at: "/",
    from: :boardr,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)
  )

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug(Phoenix.CodeReloader)
  end

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.Head)

  plug(BoardrWeb.Router)
end
