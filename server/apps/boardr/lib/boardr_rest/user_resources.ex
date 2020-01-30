defmodule BoardrRest.UserResources do
  use BoardrRest

  alias Boardr.Auth
  alias Boardr.Auth.{Identity, Token, User}

  @behaviour BoardrRest.Resources

  @impl true
  def handle_operation(operation(type: :create, data: http_request(body: body)) = op) do
    with {:ok, {:identity, identity_id, _}} <- authorize(op, :identity, :register),
         {:ok, user_properties} <- parse_json_object(body),
         {:ok, identity} <- register_user(identity_id, user_properties),
         {:ok, token} <- generate_token(identity) do
      {
        :ok,
        %User{identity.user | token: token}
      }
    end
  end

  defp register_user(identity_id, user_properties) when is_binary(identity_id) and is_map(user_properties) do
    Repo.get!(Identity, identity_id)
    |> Repo.preload(:user)
    |> Auth.register_user(user_properties)
  end

  defp generate_token(%Identity{user: %User{} = user}) do
    Token.generate(user)
  end
end
