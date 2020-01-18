defmodule BoardrApi.ControllerHelpers do
  alias Plug.Conn

  alias BoardrApi.Router
  alias Plug.Conn

  import BoardrRes, only: [options: 1]
  import Phoenix.Controller, only: [render: 2]
  import Plug.Conn, only: [get_req_header: 2, put_resp_content_type: 2]

  require BoardrRes

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

  def to_options(%Conn{} = conn, opts \\ []) when is_list(opts) do
    options(authorization_header: get_req_header(conn, "authorization"), filters: Keyword.get(opts, :filters, %{}))
  end
end
