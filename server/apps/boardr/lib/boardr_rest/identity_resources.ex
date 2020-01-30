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
         {:ok, jwt} <- generate_token(identity) do
      {
        :ok,
        %Identity{identity | token: jwt}
      }
    end
  end

  defp generate_token(%Identity{user: %User{} = user}) do
    Token.generate(user)
  end

  defp generate_token(%Identity{} = identity) do
    Token.generate(identity)
  end

  @spec get_bearer_token(BoardrRest.authorization | nil) :: {:ok, binary | nil}
  defp get_bearer_token({:bearer_token, token}), do: {:ok, token}
  defp get_bearer_token(_), do: {:ok, nil}
end
