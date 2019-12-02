defmodule BoardrWeb.IdentitiesController do
  use BoardrWeb, :controller
  alias Boardr.Auth
  alias Boardr.Auth.Identity

  action_fallback BoardrWeb.FallbackController

  def update(conn, %{"id" => id}) do
    with {:ok, token} <- get_authorization_token(conn),
         {:ok, identity} <- Auth.ensure_identity(id, token) do
      conn
      |> put_identity_created(identity)
      |> render(%{identity: identity})
    end
  end

  defp get_authorization_token(conn) do
    header_values = get_req_header conn, "authorization"
    header_values_length = length header_values
    cond do
      header_values_length <= 0 -> {:client_error, :auth_header_missing}
      header_values_length >= 2 -> {:client_error, :auth_header_duplicated}
      true -> get_bearer_token(List.first(header_values))
    end
  end

  defp get_bearer_token(header_value) when is_binary(header_value) do
    if [ _, token ] = String.split header_value, " ", parts: 2 do
      {:ok, token}
    else
      {:client_error, :auth_header_malformed}
    end
  end

  defp put_identity_created(conn, %Identity{} = identity) do
    if DateTime.compare(identity.created_at, identity.updated_at) == :eq do
      conn
      |> put_status(:created)
    else
      conn
    end
  end
end
