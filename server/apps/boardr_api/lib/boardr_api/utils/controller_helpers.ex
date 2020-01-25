defmodule BoardrApi.ControllerHelpers do
  alias Plug.Conn

  alias Plug.Conn

  import Boardr.Distributed, only: [distribute: 3]
  import Phoenix.Controller, only: [render: 2]
  import Plug.Conn, only: [get_req_header: 2, put_resp_content_type: 2]

  require BoardrRest

  def render_hal(%Conn{} = conn, assigns) when is_map(assigns) do
    conn
    |> put_resp_content_type("application/hal+json")
    |> render(assigns)
  end

  def rest(%Conn{} = conn, resources, operation_type, options \\ %{})
      when is_atom(operation_type) and is_map(options) do
    with {:ok, op} <- to_rest_operation(conn, operation_type, options) do
      distribute(resources, :handle_operation, [op])
    end
  end

  defp get_authorization(%Conn{} = conn),
    do: conn |> get_req_header("authorization") |> get_authorization()

  defp get_authorization([_, _]), do: {:error, {:auth_error, :auth_header_duplicated}}
  defp get_authorization(["Bearer " <> token]), do: {:ok, {:bearer_token, token}}
  defp get_authorization([_]), do: {:error, {:auth_error, :auth_header_malformed}}
  defp get_authorization([]), do: {:ok, nil}

  defp to_rest_operation(%Conn{} = conn, operation_type, options)
       when is_atom(operation_type) and is_map(options) do
    {id, remaining_options} = Map.pop(options, :id)

    with {:ok, authorization} <- get_authorization(conn),
         {:ok, body, _} <- Plug.Conn.read_body(conn) do
      {
        :ok,
        BoardrRest.operation(
          type: operation_type,
          id: id,
          data: BoardrRest.http_request(body: body, query_string: conn.query_string),
          authorization: authorization,
          options: Map.put(remaining_options, :authorization, authorization)
        )
      }
    end
  end
end
