defmodule BoardrWeb.UsersController do
  use BoardrWeb, :controller

  alias Boardr.Auth
  alias Boardr.Auth.{Identity, Token, User}

  plug Authenticate, [:'api:users:show'] when action in [:show]
  plug Authenticate, [:register] when action in [:create]

  def create(%Conn{assigns: %{auth: %{"sub" => identity_id}}} = conn, body) when is_map(body) do
    # FIXME: only allow local identity with unverified email in dev
    identity = Repo.get!(Identity, identity_id) |> Repo.preload(:user)
    with {:ok, user, linked_identity} <- Auth.register_user(identity, body),
         claims = create_user_claims(linked_identity),
         {:ok, jwt} <- Token.generate(claims) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.users_url(Endpoint, :show, user.id))
      |> render(%{token: jwt, user: user})
    end
  end

  def show(%Conn{} = conn, %{"id" => id}) do
    user = Repo.get!(User, id)

    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{user: user})
  end

  defp create_user_claims(%Identity{id: id, user: %User{}}) do
    %{
      scope: "api",
      sub: id
    }
  end
end
