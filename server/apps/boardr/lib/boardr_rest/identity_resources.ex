defmodule BoardrRest.IdentityResources do
  use BoardrRest

  alias Boardr.Auth
  alias Boardr.Auth.{Identity, Token, User}

  @behaviour BoardrRest.Resources

  @impl true
  def handle_operation(
        operation(
          type: :create,
          data: http_request(body: body),
          authorization: authorization
        )
      ) do
    with {:ok, identity_properties} <- parse_json_object(body),
         {:ok, bearer_token} <- get_bearer_token(authorization),
         {:ok, identity} <- Auth.ensure_identity(identity_properties, bearer_token),
         claims = create_identity_claims(identity),
         {:ok, jwt} <- Token.generate(claims) do
      {
        :ok,
        %Identity{identity | token: jwt}
      }
    end
  end

  defp create_identity_claims(%Identity{id: id, user: %User{}}) do
    %{scope: "api", sub: "u:#{id}"}
  end

  defp create_identity_claims(%Identity{id: id, user: nil}) do
    %{scope: "register", sub: "i:#{id}"}
  end

  @spec get_bearer_token(BoardrRest.authorization | nil) :: {:ok, binary | nil}
  defp get_bearer_token({:bearer_token, token}), do: {:ok, token}
  defp get_bearer_token(_), do: {:ok, nil}
end
