defmodule BoardrWeb.MethodNotAllowedController do
  use BoardrWeb, :controller

  def match(%Plug.Conn{path_info: path_info} = conn, _) do

    routes =
      BoardrWeb.Router.__routes__()
      |> Enum.map(&({&1.verb, &1.path}))
      |> Enum.uniq()
      |> Enum.map(&({elem(&1, 0), elem(&1, 1) |> String.split("/") |> Enum.drop(1)}))

    matching_routes = Enum.filter(routes, fn route -> path_info_matches_route(path_info, route) end)
    if Enum.empty?(matching_routes) do
      raise %Phoenix.Router.NoRouteError{}
    else
      raise %BoardrWeb.Errors.MethodNotAllowed{
        allowed_methods: Enum.map(matching_routes, fn route -> elem(route, 0) end),
        conn: conn,
        router: BoardrWeb.Router
      }
    end
  end

  defp path_info_matches_route(path_info, route) when is_list(path_info) and is_tuple(route) do
    path_info_matches_route_path(path_info, elem(route, 1))
  end

  defp path_info_matches_route_path([], []) do
    true
  end

  defp path_info_matches_route_path(path_info, route_path) when is_list(path_info) and is_list(route_path) and length(path_info) != length(route_path) do
    false
  end

  defp path_info_matches_route_path([ path_info_head | path_info_rest ], [ route_path_head | route_path_rest ]) do
    (String.starts_with?(route_path_head, ":") or path_info_head === route_path_head) and path_info_matches_route_path(path_info_rest, route_path_rest)
  end
end
