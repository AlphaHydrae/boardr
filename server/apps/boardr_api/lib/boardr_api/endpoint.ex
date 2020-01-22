defmodule BoardrApi.Endpoint do
  use Phoenix.Endpoint, otp_app: :boardr

  alias Boardr.Config

  def init(:supervisor, config) do
    with {:ok, port} <-
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
          http: Keyword.merge(
            Keyword.get(config, :http, []),
            [
              port: valid_port
            ]
          ),
          url: base_url_options |> Map.take([:host, :path, :port, :scheme]) |> Map.to_list()
        )
      }
    end
  end

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug(Phoenix.CodeReloader)
  end

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])
  plug(Plug.Head)

  plug(BoardrApi.Router)
end
