defmodule BoardrApi.ControllerHelpers do
  alias Plug.Conn

  alias BoardrApi.Router
  alias Plug.Conn

  import Boardr.Distributed, only: [distribute: 3]
  import Phoenix.Controller, only: [render: 2]
  import Plug.Conn, only: [get_req_header: 2, put_resp_content_type: 2]

  require BoardrRest

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

  def distribute_to_service(%Conn{} = conn, service, type, options \\ %{})
       when is_atom(type) and is_map(options) do
    with {:ok, op} <- to_rest_operation(conn, type, options) do
      distribute(service, :handle_operation, [op])
    end
  end

  defp to_rest_operation(%Conn{} = conn, type, options)
       when is_atom(type) and is_map(options) do
    {id, remaining_options} = Map.pop(options, :id)
    authorization = conn |> get_req_header("authorization") |> List.first

    with {:ok, entity, _} <- Plug.Conn.read_body(conn) do
      {
        :ok,
        BoardrRest.operation(
          type: type,
          entity: entity,
          id: id,
          options: Map.put(remaining_options, :authorization, authorization),
          query: conn.query_string
        )
      }
    end
  end
end
