defmodule BoardrRest.IdentitiesService do
  use BoardrRest

  alias Boardr.Auth
  alias Boardr.Auth.{Identity, Token, User}

  import BoardrRest.Auth, only: [get_bearer_token: 2]

  @behaviour BoardrRest.Service

  @impl true
  def handle_operation(operation(type: :create) = op) do
    op |> parse_json_object_entity() >>>
      get_bearer_token(false) >>>
      ensure_identity() >>>
      generate_token()
  end

  defp create_identity_claims(%Identity{id: id, user: %User{}}) do
    %{scope: "api", sub: id}
  end

  defp create_identity_claims(%Identity{id: id, user: nil}) do
    %{scope: "register", sub: id}
  end

  defp ensure_identity(operation(options: %{parsed_entity: entity} = options) = op)
       when is_map(entity) do
    with {:ok, identity} <- Auth.ensure_identity(entity, options[:authorization_token]) do
      {
        :ok,
        operation(op, options: Map.put(options, :identity, identity))
      }
    end
  end

  defp generate_token(operation(options: %{identity: %Identity{} = identity})) do
    claims = create_identity_claims(identity)

    with {:ok, jwt} <- Token.generate(claims) do
      {
        :ok,
        %Identity{identity | token: jwt}
      }
    end
  end
end
