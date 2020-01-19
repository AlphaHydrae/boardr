defmodule BoardrRest.UsersService do
  use BoardrRest

  alias Boardr.Auth
  alias Boardr.Auth.{Identity, Token, User}

  @behaviour BoardrRest.Service

  @impl true
  def handle_operation(operation(type: :create) = op) do
    op
    |> authorize(:register) >>>
      parse_json_object_entity() >>>
      register_user() >>>
      generate_token() >>>
      to_user_with_token()
  end

  defp register_user(
         operation(
           options:
             %{authorization_claims: %{"sub" => identity_id}, parsed_entity: entity} = options
         ) = op
       )
       when is_binary(identity_id) and is_map(entity) do
    with {:ok, identity} <-
           Repo.get!(Identity, identity_id)
           |> Repo.preload(:user)
           |> Auth.register_user(entity) do
      {
        :ok,
        operation(op, options: Map.put(options, :identity, identity))
      }
    end
  end

  defp generate_token(
         operation(options: %{identity: %Identity{user: %User{id: user_id}}} = options) = op
       ) do
    with {:ok, token} <- Token.generate(%{scope: "api", sub: user_id}) do
      {
        :ok,
        operation(op, options: Map.put(options, :token, token))
      }
    end
  end

  defp to_user_with_token(
         operation(options: %{identity: %Identity{user: %User{} = user}, token: token})
       )
       when is_binary(token) do
    {:ok, %User{user | token: token}}
  end
end
