defmodule BoardrApi.ControllerHelpers do
  alias Plug.Conn

  alias BoardrApi.Router

  import Phoenix.Controller, only: [render: 2]
  import Plug.Conn, only: [put_resp_content_type: 2]

  def extract_path_params(url, plug) do
    # TODO: check host, path, port & scheme match
    %URI{host: host, path: path} = URI.parse(url)
    # FIXME: host & path can be nil
    case Phoenix.Router.route_info(Router, "GET", path, host) do
      %{path_params: path_params, plug: ^plug, plug_opts: :show} -> path_params
      _ -> nil
    end
  end

  def render_hal(%Conn{} = conn, assigns) when is_map(assigns) do
    conn
    |> put_resp_content_type("application/hal+json")
    |> render(assigns)
  end
end
