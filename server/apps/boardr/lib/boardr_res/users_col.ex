defmodule BoardrRes.UsersCollection do
  use BoardrRes

  alias Boardr.Auth
  alias Boardr.Auth.{Identity, Token, User}

  @behaviour BoardrRes.Collection

  @impl true
  def create(representation, options() = opts) when is_map(representation) do
    representation
    |> to_context(opts)
    |> authorize(:register)
    >>> register_user()
    >>> generate_token()
    >>> to_user_with_token()
  end

  defp register_user(context(assigns: %{claims: %{"sub" => identity_id}}, representation: rep) = ctx) when is_binary(identity_id) and is_map(rep) do
    Repo.get!(Identity, identity_id)
    |> Repo.preload(:user)
    |> Auth.register_user(rep)
    >>> assign_into(ctx, :identity)
  end

  defp generate_token(context(assigns: %{identity: %Identity{user: %User{id: user_id}}}) = ctx) do
    Token.generate(%{
      scope: "api",
      sub: user_id
    })
    >>> assign_into(ctx, :token)
  end

  defp to_user_with_token(context(assigns: %{identity: %Identity{user: %User{} = user}, token: token})) when is_binary(token) do
    {:ok, %User{user | token: token}}
  end
end
