defmodule BoardrRes.IdentitiesCollection do
  use BoardrRes

  alias Boardr.Auth
  alias Boardr.Auth.{Identity, Token, User}

  @behaviour BoardrRes.Collection

  @impl true
  def create(representation, options() = opts) when is_map(representation) do
    representation |> to_context(opts) |> upsert_identity()
  end

  defp upsert_identity(context(representation: rep) = ctx) do
    with {:ok, token} <- BoardrRes.Auth.get_bearer_token(ctx, false),
         {:ok, identity} <- Auth.ensure_identity(rep, token),
         claims = create_identity_claims(identity),
         {:ok, jwt} <- Token.generate(claims) do
      {:ok, %Identity{identity | token: jwt}}
    end
  end

  defp create_identity_claims(%Identity{id: id, user: %User{}}) do
    %{
      scope: "api",
      sub: id
    }
  end

  defp create_identity_claims(%Identity{id: id, user: nil}) do
    %{
      scope: "register",
      sub: id
    }
  end
end
